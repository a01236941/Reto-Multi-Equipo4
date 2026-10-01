library(data.table)

reparar_fechas <- function(x) {
  x <- copy(x)
  setorder(x, archivo, estacion, fila_excel)
  x[, fecha_reconstruida := FALSE]
  x[, c("anterior", "siguiente", "fila_anterior", "fila_siguiente") := list(
    shift(fecha_hora), shift(fecha_hora, type="lead"),
    shift(fila_excel), shift(fila_excel, type="lead")), by=.(archivo, estacion)]
  # Sólo un hueco aislado entre dos filas consecutivas separadas por dos horas.
  ok <- which(is.na(x$fecha_hora) & !is.na(x$anterior) & !is.na(x$siguiente) &
    as.numeric(difftime(x$siguiente, x$anterior, units="secs")) == 7200 &
    x$fila_excel == x$fila_anterior + 1L & x$fila_siguiente == x$fila_excel + 1L)
  x[ok, `:=`(fecha_hora=anterior + 3600, fecha_reconstruida=TRUE)]
  x[, c("anterior", "siguiente", "fila_anterior", "fila_siguiente") := NULL]
  x
}

derivar_variables <- function(x) {
  x <- copy(x)
  x[, `:=`(anio=as.integer(format(fecha_hora, "%Y", tz="UTC")),
           mes=as.integer(format(fecha_hora, "%m", tz="UTC")),
           hora=as.integer(format(fecha_hora, "%H", tz="UTC")))]
  x[, temporada := fcase(mes %in% c(12L,1L,2L), "invierno",
    mes %in% 3:5, "primavera", mes %in% 6:8, "verano", default="otono")]
  x[, `:=`(hora_sin=sin(2*pi*hora/24), hora_cos=cos(2*pi*hora/24),
    mes_sin=sin(2*pi*(mes-1)/12), mes_cos=cos(2*pi*(mes-1)/12),
    viento_calma=ifelse(is.na(WSR), NA, WSR==0))]
  # WDR original se conserva; 360 y 0 producen la misma representación.
  direccion <- ifelse(!is.na(x$WDR) & x$WDR >= 0 & x$WDR <= 360 &
    (is.na(x$WSR) | x$WSR > 0), x$WDR %% 360, NA_real_)
  x[, `:=`(WDR_sin=sin(direccion*pi/180), WDR_cos=cos(direccion*pi/180))]
  x
}

tabla_faltantes <- function(x, variables, grupos=character()) {
  if (length(grupos)) {
    z <- x[, lapply(.SD, function(v) sum(is.na(v))), by=grupos, .SDcols=variables]
    z <- melt(z, id.vars=grupos, variable.name="variable", value.name="faltantes")
    z <- merge(z, x[,.(registros=.N), by=grupos], by=grupos, sort=FALSE)
  } else {
    z <- data.table(variable=variables, faltantes=vapply(x[,..variables], function(v)sum(is.na(v)), integer(1)),
                    registros=nrow(x))
  }
  z[, porcentaje := 100*faltantes/registros]
  z[]
}

preparar_sima <- function(entrada, auditoria="reports/auditoria") {
  x <- reparar_fechas(entrada)
  escribir <- function(z, nombre) {
    z <- copy(z)
    # Exportar horas de Excel sin sufijo Z: la zona del origen sigue sin documentar.
    for (v in names(z)[vapply(z,inherits,logical(1),"POSIXt")])
      set(z,j=v,value=format(z[[v]],"%Y-%m-%d %H:%M:%S",tz="UTC"))
    fwrite(z, file.path(auditoria,nombre), na="NA")
  }
  escribir(x[fecha_reconstruida==TRUE,.(archivo,estacion,fila_excel,fecha_hora)],"fechas_reconstruidas.csv")
  invalidas <- is.na(x$fecha_hora) | format(x$fecha_hora,"%Y",tz="UTC") != as.character(x$anio_archivo) |
    as.numeric(x$fecha_hora) %% 3600 != 0
  invalidas[is.na(invalidas)] <- TRUE
  cuarentena <- x[invalidas]
  x <- x[!invalidas]
  claves <- c("estacion","fecha_hora")
  dup <- x[,.(registros=.N), by=claves][registros>1L]
  # Si una clave tiene valores distintos, no decidir arbitrariamente cuál es correcta.
  repetidas <- duplicated(x,by=claves) | duplicated(x,by=claves,fromLast=TRUE)
  conflictos <- x[repetidas,.(versiones=uniqueN(.SD)), by=claves, .SDcols=variables_sima][versiones>1L]
  if (nrow(conflictos)) {
    afectados <- x[conflictos,on=claves, nomatch=0]
    escribir(afectados,"conflictos_clave.csv")
    stop("Hay claves con lecturas diferentes. Revisar conflictos_clave.csv antes de continuar.")
  }
  quitar <- duplicated(x, by=claves)
  escribir(x[quitar],"duplicados_eliminados.csv")
  n_duplicados <- sum(quitar)
  x <- x[!quitar]
  escribir(dup,"claves_repetidas.csv")
  escribir(cuarentena,"cuarentena_fechas.csv")
  antes <- tabla_faltantes(x,variables_sima)
  cambios <- list()
  for (v in variables_sima) {
    valor <- x[[v]]
    motivo <- rep(NA_character_,length(valor))
    motivo[which(valor == -9999)] <- "valor_-9999_no_utilizable"
    # Reglas explícitas de trabajo, NO rangos oficiales SIMA por año.
    if (v=="RH") motivo[which(!is.na(valor) & valor!=-9999 & (valor<0 | valor>100))] <- "RH_fuera_0_100_por_ciento"
    if (v=="WDR") motivo[which(!is.na(valor) & valor!=-9999 & (valor<0 | valor>360))] <- "WDR_fuera_0_360_grados"
    if (v=="PRS") motivo[which(!is.na(valor) & valor<=0)] <- "presion_no_positiva"
    if (v %in% c("WSR","RAINF")) motivo[which(!is.na(valor) & valor!=-9999 & valor<0)] <- "magnitud_negativa"
    if (v=="TOUT") motivo[which(!is.na(valor) & valor!=-9999 & abs(valor)>100)] <- "temperatura_fuera_filtro_amplio_C"
    indices <- which(!is.na(motivo))
    if (length(indices)) {
      z <- x[indices,.(archivo,estacion,fila_excel,fecha_hora)]
      z[, `:=`(variable=v, valor_original=valor[indices], valor_nuevo=NA_real_, motivo=motivo[indices])]
      cambios[[v]] <- z
      valor[indices] <- NA_real_
      set(x,j=v,value=valor)
    }
    set(x,j=paste0(v,"_corregido"),value=!is.na(motivo))
  }
  cambios <- if (length(cambios)) rbindlist(cambios) else data.table(
    archivo=character(),estacion=character(),fila_excel=integer(),
    fecha_hora=as.POSIXct(character(),tz="UTC"),variable=character(),
    valor_original=numeric(),valor_nuevo=numeric(),motivo=character())
  escribir(cambios,"correcciones_celdas.csv")
  x <- derivar_variables(x)
  setorder(x,estacion,fecha_hora)
  # Sólo diagnóstico retrospectivo. Estos límites NO son predictores ni filtros
  # de entrenamiento. No se borran ni winsorizan los candidatos estadísticos.
  resumen_atipicos <- limites <- list()
  for (v in setdiff(variables_sima,"WDR")) {
    z <- x[, {
      q <- quantile(get(v),c(.25,.75),na.rm=TRUE,names=FALSE,type=7)
      list(q1=q[1],q3=q[2],iqr=q[2]-q[1],observados=sum(!is.na(get(v))))
    },by=.(estacion,anio)]
    z[, `:=`(variable=v, inferior=q1-3*iqr, superior=q3+3*iqr)]
    z[, evaluable := observados>=30 & is.finite(iqr) & iqr>0]
    umbrales <- z[x,on=.(estacion,anio)]
    flag <- !is.na(x[[v]]) & umbrales$evaluable &
      (x[[v]]<umbrales$inferior | x[[v]]>umbrales$superior)
    flag[is.na(flag)] <- FALSE
    set(x,j=paste0(v,"_atipico"),value=flag)
    limites[[v]] <- z
    resumen_atipicos[[v]] <- data.table(variable=v, candidatos=sum(flag),
      observados=sum(!is.na(x[[v]])), evaluados=sum(!is.na(x[[v]]) & umbrales$evaluable))
  }
  atipicos <- rbindlist(resumen_atipicos)
  atipicos[, porcentaje_observados := 100*candidatos/observados]
  escribir(rbindlist(limites),"limites_atipicos_descriptivos.csv")
  escribir(atipicos,"atipicos_por_variable.csv")
  flags <- paste0(setdiff(variables_sima,"WDR"),"_atipico")
  x[, alguna_alerta_estadistica := Reduce(`|`,.SD), .SDcols=flags]
  escribir(x[alguna_alerta_estadistica==TRUE, c("archivo","estacion","fila_excel","fecha_hora",variables_sima,flags),with=FALSE],
           "candidatos_revision.csv.gz")
  despues <- tabla_faltantes(x,variables_sima)
  setnames(antes,c("faltantes","porcentaje"),c("faltantes_antes","porcentaje_antes"))
  faltantes <- merge(antes,despues,by=c("variable","registros"))
  escribir(faltantes,"faltantes_por_variable.csv")
  escribir(tabla_faltantes(x,variables_sima,c("estacion","anio")),"faltantes_estacion_anio.csv")
  escribir(tabla_faltantes(x,variables_sima,"estacion"),"faltantes_por_estacion.csv")
  # No se rellenan concentraciones ni meteorología antes de definir objetivo,
  # horizonte, partición temporal y unidades/rangos definitivos.
  imputacion <- despues[,.(variable, registros, faltantes, imputados=0L,
    metodo="sin_imputacion_de_mediciones", porcentaje_total=0, porcentaje_faltantes=0)]
  escribir(imputacion,"imputacion.csv")
  huecos <- cobertura <- list()
  for (aa in sort(unique(x$anio))) for (ee in estaciones_sima) {
    z <- x[anio==aa & estacion==ee]
    inicio_anio <- as.POSIXct(sprintf("%d-01-01 00:00:00",aa),tz="UTC")
    fin_anio <- if (aa==2026L) as.POSIXct("2026-07-31 23:00:00",tz="UTC") else
      as.POSIXct(sprintf("%d-01-01 00:00:00",aa+1L),tz="UTC")-3600
    calendario <- seq(inicio_anio,fin_anio,by="hour")
    if (!nrow(z)) {
      cobertura[[length(cobertura)+1L]] <- data.table(anio=aa,estacion=ee,estado="sin_hoja",
        registros=0L,horas_periodo=length(calendario),huecos_interiores=NA_integer_,
        horas_antes_primera=NA_integer_,horas_despues_ultima=NA_integer_)
      next
    }
    inicio <- min(z$fecha_hora); fin <- max(z$fecha_hora)
    grid <- data.table(fecha_hora=seq(inicio,fin,by="hour"))
    faltan <- grid[!z,on="fecha_hora"]
    faltan[, `:=`(anio=aa,estacion=ee)]
    huecos[[length(huecos)+1L]] <- faltan
    cobertura[[length(cobertura)+1L]] <- data.table(anio=aa,estacion=ee,estado="presente",
      registros=nrow(z),horas_periodo=length(calendario),huecos_interiores=nrow(faltan),
      horas_antes_primera=sum(calendario<inicio),horas_despues_ultima=sum(calendario>fin))
  }
  cobertura <- rbindlist(cobertura)
  escribir(cobertura,"cobertura_estacion_anio.csv")
  escribir(rbindlist(huecos),"horas_sin_fila_interiores.csv")
  escribir(x[,.(registros=.N, estaciones=uniqueN(estacion)),by=anio],"registros_por_anio.csv")
  resumen <- list(registros_importados=nrow(entrada),registros_limpios=nrow(x),
    fechas_reconstruidas=sum(x$fecha_reconstruida),fechas_en_cuarentena=nrow(cuarentena),
    duplicados_eliminados=n_duplicados, filas_excluidas=nrow(entrada)-nrow(x),
    celdas_medicion=nrow(x)*length(variables_sima), celdas_corregidas=nrow(cambios),
    faltantes_iniciales=sum(antes$faltantes_antes), faltantes_finales=sum(despues$faltantes),
    mediciones_imputadas=0L, celdas_atipicas=sum(atipicos$candidatos),
    celdas_evaluadas_atipicos=sum(atipicos$evaluados),
    filas_con_alerta_estadistica=sum(x$alguna_alerta_estadistica),
    huecos_interiores=sum(cobertura$huecos_interiores,na.rm=TRUE),
    horas_borde=sum(cobertura$horas_antes_primera+cobertura$horas_despues_ultima,na.rm=TRUE))
  jsonlite::write_json(resumen,file.path(auditoria,"resumen.json"),auto_unbox=TRUE,pretty=TRUE)
  stopifnot(!anyDuplicated(x,by=claves),!anyNA(x$fecha_hora),
    sum(despues$faltantes)-sum(antes$faltantes_antes)==nrow(cambios),
    nrow(entrada)==nrow(x)+nrow(cuarentena)+n_duplicados)
  x
}
