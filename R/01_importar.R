# Importación local. Los libros originales no se modifican.
library(data.table)
library(readxl)

variables_sima <- c("CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5", "PRS",
                    "RAINF", "RH", "SO2", "SR", "TOUT", "WSR", "WDR")
estaciones_sima <- c("CE", "NE", "NE2", "NE3", "NO", "NO2", "NO3", "NTE",
                    "NTE2", "SE", "SE2", "SE3", "SO", "SO2", "SUR")

importar_sima <- function(directorio = "data/raw", auditoria = "reports/auditoria") {
  archivos <- sort(list.files(directorio, pattern = "^BD 20[0-9]{2}.*\\.xlsx$", full.names = TRUE))
  if (length(archivos) != 7L) stop("Se esperan los siete libros anuales en data/raw.")
  dir.create(auditoria, recursive = TRUE, showWarnings = FALSE)
  datos <- inventario <- incidencias <- manifiesto <- list()
  i <- j <- 0L
  for (archivo in archivos) {
    anio <- as.integer(sub(".*(20[0-9]{2}).*", "\\1", basename(archivo)))
    manifiesto[[length(manifiesto) + 1L]] <- data.table(
      archivo = basename(archivo), bytes = file.info(archivo)$size,
      sha256 = digest::digest(file = archivo, algo = "sha256"))
    hojas <- excel_sheets(archivo)
    if (any(!hojas %in% estaciones_sima)) stop("Hoja no reconocida en ", archivo)
    message("Leyendo ", basename(archivo), " (", length(hojas), " estaciones)")
    for (hoja in hojas) {
      # Texto evita que la inferencia de tipos oculte códigos de ausencia.
      x <- as.data.table(read_excel(archivo, sheet = hoja, col_types = "text", .name_repair = "minimal"))
      if (!names(x)[1] %in% c("Fecha y hora", "date") ||
          !setequal(names(x)[-1], variables_sima)) stop("Esquema inesperado: ", archivo, "/", hoja)
      setnames(x, names(x)[1], "fecha_original")
      x[, fila_excel := .I + 1L]
      n_leidas <- nrow(x)
      vacias <- x[, Reduce(`&`, lapply(.SD, function(z) is.na(z) | trimws(z) == "")),
                  .SDcols = c("fecha_original", variables_sima)]
      x <- x[!vacias]
      # Excel almacena días sin zona horaria. UTC es sólo un contenedor técnico
      # para conservar la hora escrita, NO una conversión de hora local a UTC.
      serial <- suppressWarnings(as.numeric(x$fecha_original))
      x[, fecha_hora := as.POSIXct(round(serial * 86400), origin = "1899-12-30", tz = "UTC")]
      for (v in variables_sima) {
        texto <- trimws(x[[v]])
        ausente <- is.na(texto) | toupper(texto) %in% c("", "NA", "N/A", "NULL", "NAN")
        valor <- suppressWarnings(as.numeric(texto))
        especiales <- which(!is.na(texto) & (ausente | is.na(valor) | !is.finite(valor)))
        if (length(especiales)) {
          j <- j + 1L
          incidencias[[j]] <- data.table(archivo = basename(archivo), estacion = hoja,
            fila_excel = x$fila_excel[especiales], variable = v, texto = texto[especiales],
            motivo = ifelse(ausente[especiales], "codigo_ausencia", "no_numerico_o_no_finito"))
        }
        valor[ausente | !is.finite(valor)] <- NA_real_
        set(x, j = v, value = valor)
      }
      x[, `:=`(estacion = hoja, anio_archivo = anio, archivo = basename(archivo))]
      i <- i + 1L
      inventario[[i]] <- data.table(archivo = basename(archivo), anio = anio, estacion = hoja,
        filas_leidas = n_leidas, filas_vacias = sum(vacias), registros = nrow(x),
        fechas_invalidas = sum(is.na(x$fecha_hora)),
        inicio = format(min(x$fecha_hora, na.rm = TRUE), "%Y-%m-%d %H:%M:%S",tz="UTC"),
        fin = format(max(x$fecha_hora, na.rm = TRUE), "%Y-%m-%d %H:%M:%S",tz="UTC"))
      datos[[i]] <- x
    }
  }
  fwrite(rbindlist(manifiesto), file.path(auditoria, "manifiesto_originales.csv"))
  fwrite(rbindlist(inventario), file.path(auditoria, "inventario.csv"))
  tokens <- if (length(incidencias)) rbindlist(incidencias) else data.table(
    archivo=character(), estacion=character(), fila_excel=integer(), variable=character(), texto=character(), motivo=character())
  fwrite(tokens, file.path(auditoria, "valores_texto.csv"))
  rbindlist(datos, use.names = TRUE)
}
