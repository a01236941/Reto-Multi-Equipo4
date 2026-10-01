# Tu parte D: qué entregar y dónde está

Tu aportación comprende preparación y limpieza, transformación, reestructuración y mantenimiento del repositorio. El objetivo del equipo es predecir ozono. El contenido de los demás roles se conserva.

## Qué poner en el informe

Abre `reports/secciones_2_3_4.md` y copia su contenido después de la sección 1 de la Parte 2, correspondiente a comprensión de datos.

- **Sección 2:** datos incluidos, duplicados, correcciones, faltantes, imputación y atípicos.
- **Sección 3:** atributos de fecha, ciclos de hora y mes, dirección del viento, escalado y dummies.
- **Sección 4:** estructura de la tabla, procedencia y enlace a la base publicada.
- **Declaratoria de IA:** integrar donde lo acuerde el equipo.

Las cifras proceden de la ejecución. Las tablas completas permanecen en `reports/auditoria/`; no hace falta pegarlas todas en un informe cuyo límite es de 3–4 páginas para el equipo entero. Antes de entregar, contrastar las reglas provisionales con el diccionario y los rangos anuales de SIMA.

## De dónde salió la base

Se adaptó la unión de `BD.ipynb` y se usaron los siete Excel de tu compañero, de 2020 a julio de 2026. Los originales están en `data/raw/` y el cuaderno recibido en `docs/referencia/BD.ipynb`. La nueva ejecución usa scripts R con rutas locales y no abre Google Drive.

Los Excel 2024 y 2025 que ya tenía la plantilla en `data/` son versiones distintas y se conservaron sin mezclarlos. La importación lee solamente `data/raw/`.

## Qué base usar

Los siete archivos `data/processed/sima_horario_2020.csv.gz` a `sima_horario_2026.csv.gz` reúnen 830 908 filas. Cada archivo queda por debajo de 25 MiB. El consolidado se genera localmente; no es necesario subirlo también.

Las columnas originales conservan las mediciones después de las correcciones documentadas. En 13 predictoras se añaden `VARIABLE_preparado`, que combina observaciones y estimaciones, y `VARIABLE_metodo`, que identifica su origen. Por eso hay 89 columnas, aunque sólo 15 variables medidas. No se introducen juntas ambas versiones de una variable al modelo.

O3 y WDR no se imputaron. Los campos de procedencia y las alertas estadísticas son de auditoría. La vista `base_modelo` selecciona las predictoras preparadas y recalcula los atributos del viento para evitar confusiones.

Abre `MA2003B_Blank.Rproj` en RStudio. Para usar la base ya preparada:

```r
renv::restore(packages = c("readxl", "data.table", "digest", "jsonlite", "renv"))
source("scripts/04_base_para_modelar.R", encoding = "UTF-8")
dim(base_modelo)
head(base_modelo)
```

Los NA restantes necesitan un tratamiento acorde al modelo; no conviene eliminar automáticamente todas las filas con algún vacío. La respuesta futura de ozono se construirá cuando el equipo decida el horizonte.

## Cómo reproducir todo desde los Excel

Desde el mismo proyecto:

```r
renv::restore(packages = c("readxl", "data.table", "digest", "jsonlite", "renv"))
source("scripts/01_preparar_datos.R", encoding = "UTF-8")
source("tests/verificar_preparacion.R", encoding = "UTF-8")
source("scripts/02_generar_informe.R", encoding = "UTF-8")
```

El proceso puede tardar varios minutos. `R/01_importar.R` une archivos; `R/02_preparar.R` limpia y audita; `R/04_imputar.R` compara y aplica imputadores; `R/03_exportar.R` guarda los CSV. El proceso no entrena un predictor de O3.

`renv.lock` registra las dependencias. Para esta aportación se verificaron las indicadas arriba. El equipo puede restaurar el entorno completo con `renv::restore()`; no hace falta ejecutar de nuevo `renv::init()`.

## Qué se hizo con la imputación

No se usó media ni mediana. Se compararon persistencia, rezago de 24 horas y autorregresión con calendario. Se ajustó con 2020–2024, se eligió el método con 2025 y se comprobó con 2026. Para evaluar, se ocultaron bloques de una a tres horas y se compararon las estimaciones con sus valores conocidos.

Se rellenaron 152 594 celdas, limitándose a las primeras tres horas desde una medición real. El resto de las interrupciones largas se conserva vacío. Los resultados están desglosados por variable, método, estación y periodo. Las estimaciones puntuales no garantizan conservar picos ni correlaciones; por eso las mediciones se mantienen separadas.

El artículo recomendado de Transformer–Diffusion sí es pertinente y menciona datos SIMA. Su resumen está disponible, pero el capítulo completo requiere suscripción y no se localizó código de los autores. Esta entrega **no afirma haber entrenado esa arquitectura**. Consulta `reports/metodo_imputacion.md` para la referencia y la distinción entre ese trabajo y el método ejecutado.

## GitHub y colaboración

La rama es `preparacion-sima`. `reports/estado_publicacion.md` registra la publicación y la solicitud de integración en `trunk`. Mientras siga abierta, usa el enlace de esa rama para entregar.

No hace falta crear otro repositorio ni subir el ZIP desde el navegador. Si alguien utiliza la copia manual, debe extraerla primero y subir el contenido del proyecto conservando las carpetas. Las bibliotecas de paquetes, cachés y el CSV consolidado no se versionan.

Para cambios posteriores: actualizar la rama, abrir el proyecto, instalar deliberadamente las dependencias y revisar el diff de `renv::snapshot()`. No reemplazar todo el lock con el de otra computadora ni aceptar eliminaciones masivas porque falten paquetes localmente. Ante conflictos, acordar versiones y regenerar el lock con el entorno correcto.

## Decisiones pendientes del equipo

Confirmar unidades, banderas y rangos instrumentales con el socio formador; elegir el horizonte de predicción; y revisar el texto antes de incorporarlo al informe. Las tres horas de imputación no definen ese horizonte. Si cambian los cortes de entrenamiento, validación y prueba, deberán reajustar el imputador. La preparación queda reproducible bajo los criterios documentados; no equivale a una certificación instrumental de los datos.
