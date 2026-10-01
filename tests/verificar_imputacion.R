source("R/04_imputar.R",encoding="UTF-8")
x <- readRDS("output/cache/sima_preparado.rds")
r <- jsonlite::fromJSON("reports/auditoria/resumen.json")
imp <- fread("reports/auditoria/imputacion.csv")
conexion_imp <- gzfile("reports/auditoria/celdas_imputadas.csv.gz","rt")
cel <- as.data.table(read.csv(conexion_imp,stringsAsFactors=FALSE))
close(conexion_imp)
sel <- fread("reports/auditoria/metodos_seleccionados.csv")
met <- fread("reports/auditoria/metricas_imputacion.csv")
stopifnot(sum(imp$imputados)==r$mediciones_imputadas,nrow(cel)==r$mediciones_imputadas,
  all(cel$horas_desde_observacion %in% 1:3),all(sel$periodo==2025),
  !any(cel$variable %in% c("O3","WDR")),!"O3_preparado" %in% names(x),
  r$faltantes_base_uso==r$faltantes_finales-r$mediciones_imputadas)
for (v in variables_imputar) {
  obs <- x[[v]]; prep <- x[[paste0(v,"_preparado")]]; etiqueta <- x[[paste0(v,"_metodo")]]
  stopifnot(identical(obs[!is.na(obs)],prep[!is.na(obs)]),
    all(etiqueta[!is.na(obs)]=="observado"),
    sum(is.na(obs) & is.finite(prep))==imp[variable==v,imputados],
    all(is.na(prep[etiqueta=="sin_imputar"])))
  elegido <- sel[variable==v,as.character(metodo)]
  if (length(elegido)) stopifnot(met[periodo==2025 & variable==v & metodo==elegido,MAE] ==
    min(met[periodo==2025 & variable==v,MAE]))
}
# Prueba adversarial de fuga: cambiar el bloque oculto y todas las horas futuras
# no puede cambiar las predicciones hechas desde su origen.
tt <- seq(as.POSIXct("2025-01-01",tz="UTC"),by="hour",length.out=120)
y <- seq_len(120)+sin(seq_len(120)); cambiado <- y; cambiado[70:120] <- 999999
b <- c(0,.7,.1,.2,0,0,0,0)
for (h in 1:3) stopifnot(identical(
  predecir_temporal(y,tt,69+h,h,b,"TOUT"),
  predecir_temporal(cambiado,tt,69+h,h,b,"TOUT")))
# Comprobar que cada imputación tiene una medición real exactamente h horas antes.
cel[,fecha_hora:=as.POSIXct(fecha_hora,tz="UTC")]
for (v in unique(cel$variable)) {
  z <- cel[variable==v]
  keys <- data.table(estacion=z$estacion,fecha_hora=z$fecha_hora-3600*z$horas_desde_observacion)
  antiguos <- x[keys,on=.(estacion,fecha_hora),get(v)]
  stopifnot(all(is.finite(antiguos)))
}
cat("Imputación verificada: originales intactos, trazabilidad, selección temporal y ausencia de lecturas futuras.\n")
