# Imputación causal de predictoras. Las mediciones originales no se sobrescriben.
# Ajuste: 2020-2024; selección: 2025; prueba independiente: enero-julio 2026.
library(data.table)
variables_imputar <- c("CO","NO","NO2","NOX","PM10","PM2.5","PRS","RAINF","RH","SO2","SR","TOUT","WSR")
metodos_imputar <- c("persistencia","rezago_24h","autorregresion")

matriz_temporal <- function(y, tiempo, idx, h) {
  # Para el h-ésimo valor de un bloque oculto, el origen es idx-h.
  # Ninguna entrada procede del bloque oculto ni de una hora posterior.
  leer <- function(j) { z <- rep(NA_real_,length(j)); ok <- j>=1 & j<=length(y); z[ok] <- y[j[ok]]; z }
  hora <- as.integer(format(tiempo[idx],"%H",tz="UTC"))
  mes <- as.integer(format(tiempo[idx],"%m",tz="UTC"))
  cbind(intercepto=1,ultimo=leer(idx-h),previo=leer(idx-h-1L),diario=leer(idx-24L),
    hora_sin=sin(2*pi*hora/24),hora_cos=cos(2*pi*hora/24),
    mes_sin=sin(2*pi*(mes-1)/12),mes_cos=cos(2*pi*(mes-1)/12))
}

limitar_estimacion <- function(z,v) {
  # Sólo estimaciones: las observaciones no se recortan.
  if (v=="RH") z <- pmax(0,pmin(100,z))
  if (v=="TOUT") z <- pmax(-100,pmin(100,z))
  if (!v %in% c("TOUT","RH")) z <- pmax(0,z)
  if (v=="PRS") z[z<=0] <- NA_real_
  z[!is.finite(z)] <- NA_real_
  z
}

predecir_temporal <- function(y,tiempo,idx,h,coeficientes,v) {
  a <- matriz_temporal(y,tiempo,idx,h)
  ar <- rep(NA_real_,nrow(a)); ok <- complete.cases(a)
  if (!is.null(coeficientes) && all(is.finite(coeficientes))) ar[ok] <- drop(a[ok,,drop=FALSE] %*% coeficientes)
  data.table(persistencia=limitar_estimacion(a[,"ultimo"],v),
    rezago_24h=limitar_estimacion(a[,"diario"],v),autorregresion=limitar_estimacion(ar,v))
}

imputar_sima <- function(base,auditoria="reports/auditoria") {
  stopifnot(!anyDuplicated(base,by=c("estacion","fecha_hora")))
  x <- copy(base); setorder(x,estacion,fecha_hora)
  set.seed(20260930)
  modelos <- mascaras <- propuestas <- list()
  for (ee in sort(unique(x$estacion))) {
    ids <- which(x$estacion==ee); local <- x[ids]
    tiempo <- seq(min(local$fecha_hora),max(local$fecha_hora),by="hour")
    correspondencia <- match(local$fecha_hora,tiempo)
    anios <- as.integer(format(tiempo,"%Y",tz="UTC"))
    for (v in variables_imputar) {
      y <- rep(NA_real_,length(tiempo)); y[correspondencia] <- local[[v]]
      ajustes <- vector("list",3)
      for (h in 1:3) {
        idx <- which(anios<=2024L & seq_along(y)>24L)
        a <- matriz_temporal(y,tiempo,idx,h)
        ok <- complete.cases(a) & is.finite(y[idx])
        b <- rep(NA_real_,ncol(a)); names(b) <- colnames(a)
        if (sum(ok)>=500L) {
          fit <- stats::lm.fit(a[ok,,drop=FALSE],y[idx[ok]])
          if (fit$rank==ncol(a)) b <- fit$coefficients
        }
        ajustes[[h]] <- b
        modelos[[length(modelos)+1L]] <- data.table(estacion=ee,variable=v,h=h,
          termino=names(b),coeficiente=as.numeric(b),n_entrenamiento=sum(ok),
          ultimo_anio_ajuste=2024L)
      }
      # Cada bloque es un experimento independiente. Se ocultan todas sus horas.
      # Se comparan los tres métodos en los mismos casos con contexto disponible.
      for (aa in 2025:2026) for (largo in 1:3) {
        candidatos <- which(anios==aa & seq_along(y)>24L & seq_along(y)+largo-1L<=length(y))
        valido <- rep(TRUE,length(candidatos))
        for (h in seq_len(largo)) {
          idx <- candidatos+h-1L
          a <- matriz_temporal(y,tiempo,idx,h)
          valido <- valido & anios[idx]==aa & is.finite(y[idx]) & complete.cases(a)
        }
        candidatos <- candidatos[valido]
        if (!length(candidatos) || any(!is.finite(unlist(ajustes)))) next
        # Hasta 60 bloques de cada longitud, estación, variable y periodo.
        inicios <- sort(candidatos[sample.int(length(candidatos),min(60L,length(candidatos)))])
        for (h in seq_len(largo)) {
          idx <- inicios+h-1L
          estimado <- predecir_temporal(y,tiempo,idx,h,ajustes[[h]],v)
          z <- data.table(estacion=ee,variable=v,periodo=aa,
            inicio=format(tiempo[inicios],"%Y-%m-%d %H:%M:%S",tz="UTC"),
            longitud=largo,h=h,fecha_hora=format(tiempo[idx],"%Y-%m-%d %H:%M:%S",tz="UTC"),
            observado=y[idx])
          mascaras[[length(mascaras)+1L]] <- cbind(z,estimado)
        }
      }
      # Sólo las primeras tres horas desde la última medición real.
      # Las ausencias de filas cuentan como horas, pero no se crean filas nuevas.
      ultimo <- cummax(ifelse(is.finite(y),seq_along(y),0L))
      edad <- seq_along(y)-ultimo
      for (h in 1:3) {
        idx <- which(is.na(y) & ultimo>0 & edad==h)
        filas_local <- match(idx,correspondencia)
        keep <- !is.na(filas_local)
        idx <- idx[keep]; filas_local <- filas_local[keep]
        if (!length(idx)) next
        est <- predecir_temporal(y,tiempo,idx,h,ajustes[[h]],v)
        propuestas[[length(propuestas)+1L]] <- cbind(data.table(fila=ids[filas_local],
          estacion=ee,variable=v,h=h),est)
      }
    }
    message("Imputación evaluada: ",ee)
  }
  modelos <- rbindlist(modelos)
  pruebas <- rbindlist(mascaras)
  largos <- melt(pruebas,id.vars=setdiff(names(pruebas),metodos_imputar),
    measure.vars=metodos_imputar,variable.name="metodo",value.name="estimado")
  largos[, error:=estimado-observado]
  metricas <- largos[,.(n=.N,MAE=mean(abs(error)),RMSE=sqrt(mean(error^2)),
    sesgo=mean(error)),by=.(periodo,variable,metodo)]
  # Selección por variable: mínimo MAE en 2025; el test 2026 no cambia la elección.
  seleccion <- metricas[periodo==2025 & is.finite(MAE)]
  setorder(seleccion,variable,MAE,RMSE,metodo)
  seleccion <- seleccion[,head(.SD,1L),by=variable]
  setnames(seleccion,c("MAE","RMSE","n"),c("MAE_validacion","RMSE_validacion","n_validacion"))
  prop <- rbindlist(propuestas)
  log_cambios <- list(); resumen <- list()
  for (v in variables_sima) {
    if (!v %in% variables_imputar) {
      resumen[[v]] <- data.table(variable=v,metodo="sin_imputar",registros=nrow(x),
        faltantes=sum(is.na(x[[v]])),imputados=0L,porcentaje_total=0,porcentaje_faltantes=0)
      next
    }
    eleccion <- seleccion[variable==v,as.character(metodo)]
    salida <- x[[v]]; etiqueta <- rep("observado",nrow(x)); etiqueta[is.na(salida)] <- "sin_imputar"
    if (length(eleccion)==1L) {
      z <- prop[variable==v]
      z[,valor:=get(eleccion)]
      z <- z[is.finite(valor)]
      salida[z$fila] <- z$valor; etiqueta[z$fila] <- eleccion
      if (nrow(z)) {
        registro <- x[z$fila,.(archivo,estacion,fila_excel,fecha_hora)]
        registro[, `:=`(variable=v,valor_imputado=z$valor,metodo=eleccion,horas_desde_observacion=z$h)]
        log_cambios[[v]] <- registro
      }
    } else eleccion <- "sin_evidencia_para_seleccionar"
    set(x,j=paste0(v,"_preparado"),value=salida)
    set(x,j=paste0(v,"_metodo"),value=etiqueta)
    n_na <- sum(is.na(x[[v]])); n_imp <- sum(!is.na(salida) & is.na(x[[v]]))
    resumen[[v]] <- data.table(variable=v,metodo=eleccion,registros=nrow(x),faltantes=n_na,
      imputados=n_imp,porcentaje_total=100*n_imp/nrow(x),
      porcentaje_faltantes=if(n_na)100*n_imp/n_na else 0)
    stopifnot(identical(salida[!is.na(x[[v]])],x[[v]][!is.na(x[[v]])]))
  }
  resumen <- rbindlist(resumen)
  log_cambios <- rbindlist(log_cambios)
  log_cambios[,fecha_hora:=format(fecha_hora,"%Y-%m-%d %H:%M:%S",tz="UTC")]
  fwrite(resumen,file.path(auditoria,"imputacion.csv"))
  fwrite(modelos,file.path(auditoria,"coeficientes_imputacion.csv"))
  fwrite(pruebas,file.path(auditoria,"validacion_bloques.csv.gz"))
  fwrite(metricas,file.path(auditoria,"metricas_imputacion.csv"))
  fwrite(largos[,.(n=.N,MAE=mean(abs(error)),RMSE=sqrt(mean(error^2))),
    by=.(periodo,estacion,variable,longitud,metodo)],file.path(auditoria,"metricas_imputacion_detalle.csv"))
  fwrite(seleccion,file.path(auditoria,"metodos_seleccionados.csv"))
  fwrite(log_cambios,file.path(auditoria,"celdas_imputadas.csv.gz"))
  r <- jsonlite::fromJSON(file.path(auditoria,"resumen.json"))
  r$mediciones_imputadas <- sum(resumen$imputados)
  r$faltantes_base_uso <- r$faltantes_finales-r$mediciones_imputadas
  r$columnas_exportadas <- ncol(x)
  jsonlite::write_json(r,file.path(auditoria,"resumen.json"),auto_unbox=TRUE,pretty=TRUE)
  x
}
