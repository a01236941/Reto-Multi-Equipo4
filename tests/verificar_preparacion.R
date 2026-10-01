if (.Platform$OS.type=="windows") invisible(Sys.setlocale("LC_CTYPE", ".UTF-8"))
source("R/01_importar.R",encoding="UTF-8")
source("R/02_preparar.R",encoding="UTF-8")

# No reconstruir secuencias ambiguas ni mezclar estaciones.
t0 <- as.POSIXct("2026-01-01",tz="UTC")
prueba <- data.table(archivo="prueba",estacion=c(rep("CE",3),rep("NE",4)),
  fila_excel=c(2:4,2:5),fecha_hora=t0+c(0,NA,7200,0,NA,NA,10800))
salida <- reparar_fechas(prueba)
stopifnot(sum(salida$fecha_reconstruida)==1,
          salida[estacion=="CE" & fila_excel==3,fecha_hora]==t0+3600,
          sum(is.na(salida[estacion=="NE",fecha_hora]))==2)

# El círculo del viento respeta norte y no asigna una dirección a la calma.
viento <- data.table(fecha_hora=rep(t0,6),WDR=c(359,1,0,360,90,361),WSR=c(1,1,1,1,0,1))
viento <- derivar_variables(viento)
distancia <- sqrt(sum((unlist(viento[1,.(WDR_sin,WDR_cos)])-
                       unlist(viento[2,.(WDR_sin,WDR_cos)]))^2))
stopifnot(distancia<0.04, viento$WDR_sin[3]==viento$WDR_sin[4],
          viento$WDR_cos[3]==viento$WDR_cos[4],is.na(viento$WDR_sin[5]),is.na(viento$WDR_sin[6]))

# Verificación del resultado completo, no sólo de funciones aisladas.
x <- readRDS("output/cache/sima_preparado.rds")
# Las claves repetidas requieren comparar lecturas, no sólo filas completas.
cols_base <- c("archivo","estacion","fila_excel","fecha_hora","anio_archivo",variables_sima)
caso <- x[rep(1L,2),..cols_base]
caso[,fila_excel:=2:3]
auditoria_prueba <- tempfile("sima-prueba-")
dir.create(auditoria_prueba)
deduplicado <- preparar_sima(caso,auditoria=auditoria_prueba)
stopifnot(nrow(deduplicado)==1L)
caso[2,CO:=ifelse(is.na(CO),1,CO+1)]
conflicto <- tryCatch({preparar_sima(caso,auditoria=auditoria_prueba);FALSE},
                      error=function(e)grepl("claves con lecturas diferentes",conditionMessage(e)))
stopifnot(conflicto,file.exists(file.path(auditoria_prueba,"conflictos_clave.csv")))
r <- jsonlite::fromJSON("reports/auditoria/resumen.json")
cambios <- fread("reports/auditoria/correcciones_celdas.csv")
stopifnot(nrow(x)==r$registros_limpios, !anyNA(x$fecha_hora),
          !anyDuplicated(x,by=c("estacion","fecha_hora")),
          nrow(cambios)==r$celdas_corregidas,
          sum(vapply(x[,..variables_sima],function(v)sum(is.na(v)),integer(1)))==r$faltantes_finales,
          r$faltantes_finales-r$faltantes_iniciales==r$celdas_corregidas,
          r$registros_importados==r$registros_limpios+r$filas_excluidas)
for (v in variables_sima) {
  flag <- x[[paste0(v,"_corregido")]]
  stopifnot(all(is.na(x[[v]][flag])),sum(flag)==sum(cambios$variable==v))
}
manifiesto <- fread("reports/auditoria/manifiesto_originales.csv")
for (i in seq_len(nrow(manifiesto))) stopifnot(
  digest::digest(file=file.path("data/raw",manifiesto$archivo[i]),algo="sha256")==manifiesto$sha256[i])
source("tests/verificar_exportacion.R",encoding="UTF-8")
source("tests/verificar_imputacion.R",encoding="UTF-8")
cat("Verificaciones correctas: fechas, claves, dirección circular, auditoría y originales.\n")
