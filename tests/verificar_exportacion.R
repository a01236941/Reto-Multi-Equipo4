source("scripts/03_leer_base_preparada.R",encoding="UTF-8")
original <- as.data.frame(readRDS("output/cache/sima_preparado.rds"))
original$fecha_hora <- format(original$fecha_hora,"%Y-%m-%d %H:%M:%S",tz="UTC")
original <- original[,names(base_sima)]
iguales <- all.equal(base_sima,original,check.attributes=FALSE,tolerance=1e-12)
if (!isTRUE(iguales)) stop(paste(iguales,collapse="; "))
manifiesto_salida <- read.csv("reports/auditoria/manifiesto_base_preparada.csv")
stopifnot(nrow(manifiesto_salida)==7L,sum(manifiesto_salida$registros)==nrow(base_sima))
for (i in seq_len(nrow(manifiesto_salida))) {
  ruta <- file.path("data/processed",manifiesto_salida$archivo[i])
  stopifnot(file.info(ruta)$size<=25*1024^2,
    digest::digest(file=ruta,algo="sha256")==manifiesto_salida$sha256[i])
}
rm(original,base_sima)
cat("Exportación anual equivalente a la base consolidada y apta para subida web: verificado.\n")
