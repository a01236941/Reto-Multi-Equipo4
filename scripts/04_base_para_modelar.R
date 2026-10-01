# Vista compacta para el equipo. No crea O3(t+h) ni entrena un predictor de ozono.
if (.Platform$OS.type=="windows") invisible(Sys.setlocale("LC_CTYPE", ".UTF-8"))
source("scripts/03_leer_base_preparada.R",encoding="UTF-8")
source("R/01_importar.R",encoding="UTF-8")
source("R/02_preparar.R",encoding="UTF-8")
predictoras_imputadas <- sub("_preparado$","",grep("_preparado$",names(base_sima),value=TRUE))
base_modelo <- data.table::as.data.table(base_sima[,c("fecha_hora","estacion",variables_sima)])
base_modelo[,fecha_hora:=as.POSIXct(fecha_hora,tz="UTC")]
for (v in predictoras_imputadas) {
  data.table::set(base_modelo,j=v,value=base_sima[[paste0(v,"_preparado")]])
  data.table::set(base_modelo,j=paste0(v,"_imputado"),value=
    !base_sima[[paste0(v,"_metodo")]] %in% c("observado","sin_imputar"))
}
base_modelo <- derivar_variables(base_modelo)
stopifnot(identical(base_modelo$O3,base_sima$O3))
cat("Vista preparada para definir el modelo:",nrow(base_modelo),"filas.",
    "O3 conserva sus faltantes. Definir el horizonte antes de crear la respuesta futura.\n")
