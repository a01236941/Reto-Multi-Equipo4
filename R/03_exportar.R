# La división por año permite subir la base desde el navegador de GitHub.
# No modifica mediciones, columnas ni criterios de preparación.
exportar_sima <- function(limpios) {
  dir.create("data/processed",recursive=TRUE,showWarnings=FALSE)
  exportar <- data.table::copy(limpios)
  exportar[, fecha_hora := format(fecha_hora,"%Y-%m-%d %H:%M:%S",tz="UTC")]
  data.table::setcolorder(exportar,c("fecha_hora","estacion",variables_sima,
    setdiff(names(exportar),c("fecha_hora","estacion",variables_sima))))
  # Copia consolidada para uso local. Se excluye de Git por superar 25 MiB.
  data.table::fwrite(exportar,"data/processed/sima_horario.csv.gz",na="NA")
  manifiesto <- list()
  for (aa in sort(unique(exportar$anio))) {
    nombre <- sprintf("sima_horario_%d.csv.gz",aa)
    ruta <- file.path("data/processed",nombre)
    parte <- exportar[anio==aa]
    data.table::fwrite(parte,ruta,na="NA")
    if (file.info(ruta)$size>25*1024^2) stop("El archivo supera el límite de subida web: ",nombre)
    manifiesto[[as.character(aa)]] <- data.table::data.table(archivo=nombre,anio=aa,
      registros=nrow(parte),bytes=file.info(ruta)$size,
      sha256=digest::digest(file=ruta,algo="sha256"))
  }
  data.table::fwrite(data.table::rbindlist(manifiesto),
                    "reports/auditoria/manifiesto_base_preparada.csv")
  invisible(manifiesto)
}
