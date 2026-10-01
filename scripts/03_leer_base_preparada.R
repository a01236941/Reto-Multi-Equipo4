# Ejecutar desde la raíz del proyecto. R base puede leer .csv.gz sin descomprimir.
archivos <- file.path("data/processed",sprintf("sima_horario_%d.csv.gz",2020:2026))
if (!all(file.exists(archivos))) stop("Falta alguno de los siete CSV anuales en data/processed.")
partes <- lapply(archivos,function(archivo) {
  conexion <- gzfile(archivo,"rt")
  on.exit(close(conexion))
  read.csv(conexion,na.strings="NA",check.names=FALSE,stringsAsFactors=FALSE,
    colClasses=c(fecha_hora="character",fecha_original="character",estacion="character",
                 archivo="character",temporada="character"))
})
stopifnot(all(vapply(partes,function(p)identical(names(p),names(partes[[1]])),logical(1))))
base_sima <- do.call(rbind,partes)
base_sima <- base_sima[order(base_sima$estacion,base_sima$fecha_hora),]
row.names(base_sima) <- NULL
rm(partes)
cat("Base cargada:",nrow(base_sima),"filas y",ncol(base_sima),"columnas.\n")
