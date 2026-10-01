# Ejecutar desde la raíz del proyecto, después de renv::restore().
if (.Platform$OS.type=="windows") invisible(Sys.setlocale("LC_CTYPE", ".UTF-8"))
source("R/01_importar.R",encoding="UTF-8")
source("R/02_preparar.R",encoding="UTF-8")
dir.create("output/cache",recursive=TRUE,showWarnings=FALSE)
dir.create("data/processed",recursive=TRUE,showWarnings=FALSE)
entrada <- importar_sima()
limpios <- preparar_sima(entrada)
# RDS conserva tipos; CSV comprimido permite abrir la base sin dependencias extra.
saveRDS(limpios,"output/cache/sima_preparado.rds")
exportar <- copy(limpios)
exportar[, fecha_hora := format(fecha_hora,"%Y-%m-%d %H:%M:%S",tz="UTC")]
setcolorder(exportar,c("fecha_hora","estacion",variables_sima,
  setdiff(names(exportar),c("fecha_hora","estacion",variables_sima))))
fwrite(exportar,"data/processed/sima_horario.csv.gz",na="NA")
writeLines(trimws(capture.output(sessionInfo()),which="right"),"reports/auditoria/sessionInfo.txt")
message("Terminado: ",nrow(limpios)," filas en data/processed/sima_horario.csv.gz")
