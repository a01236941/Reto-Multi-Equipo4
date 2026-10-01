# Reto SIMA · Equipo 4

Preparación de datos horarios para predecir **ozono (O3)** con meteorología, como parte del objetivo 6 y de la metodología CRISP-DM.

Se usaron `BD.ipynb` como referencia de unión y los siete Excel del compañero como fuentes. La preparación incluye imputación temporal de huecos breves en 13 predictoras, sin media ni mediana. **O3 se conserva observado**, y los huecos prolongados permanecen como NA. Las reglas de plausibilidad siguen sujetas al diccionario y los rangos oficiales de SIMA.

La imputación se ajustó con 2020–2024, se seleccionó con 2025 y se evaluó con enero–julio de 2026. El horizonte del futuro predictor de ozono aún debe decidirlo el equipo. El artículo Transformer–Diffusion recomendado se analiza en `reports/metodo_imputacion.md`; su arquitectura no se presenta como implementada.

## Archivos para trabajar

| Archivo o carpeta | Contenido |
|---|---|
| `data/raw/` | Los siete Excel originales del ZIP proporcionado, 2020–julio de 2026 |
| `data/processed/sima_horario_2020.csv.gz` … `sima_horario_2026.csv.gz` | 830 908 filas: mediciones conservadas y predictoras imputadas en columnas separadas |
| `R/01_importar.R` | Importación de todas las hojas desde rutas locales |
| `R/02_preparar.R` | Fechas, duplicados, correcciones, faltantes, alertas y atributos derivados |
| `R/03_exportar.R` | Exportación por año para que los archivos puedan subirse desde el navegador |
| `R/04_imputar.R` | Ajuste, comparación temporal, selección y aplicación de imputadores |
| `scripts/01_preparar_datos.R` | Ejecución completa desde los Excel |
| `scripts/02_generar_informe.R` | Redacción de las secciones 2–4 con cifras de la auditoría |
| `scripts/03_leer_base_preparada.R` | Lectura y unión de los siete CSV ya preparados |
| `scripts/04_base_para_modelar.R` | Vista compacta `base_modelo` con predictoras preparadas y O3 observado |
| `reports/secciones_2_3_4.md` | Borrador para integrar al informe del equipo |
| `reports/auditoria/` | Resultados por variable, estación y año; cambios y procedencia |
| `reports/criterios_y_diccionario.md` | Definiciones, reglas, denominadores y límites del análisis |
| `reports/metodo_imputacion.md` | Método ejecutado, validación y revisión del artículo recomendado |
| `tests/verificar_preparacion.R` | Comprobaciones de fechas, claves, transformación circular y cifras |
| `renv.lock` | Versiones de R y paquetes del proyecto |
| `GUIA_PASO_A_PASO.md` | Qué usar, dónde colocar tus secciones y decisiones pendientes del equipo |

Los Excel que ya existían directamente en `data/` y el cuaderno Quarto original se conservaron. Sus huellas difieren de las versiones 2024 y 2025 del ZIP. La nueva importación lee **solamente `data/raw/`** para no mezclar versiones ni duplicarlas.

## Reproducir en RStudio

Abra `MA2003B_Blank.Rproj`. El proyecto ya tiene `renv`; no vuelva a ejecutar `renv::init()`.

```r
# Restauración completa del entorno del equipo.
renv::restore()

# Ejecutar en este orden, desde la raíz del proyecto. La imputación puede tardar varios minutos.
source("scripts/01_preparar_datos.R", encoding = "UTF-8")
source("tests/verificar_preparacion.R", encoding = "UTF-8")
source("scripts/02_generar_informe.R", encoding = "UTF-8")
```

Para ejecutar únicamente esta preparación puede restaurar sus dependencias:

```r
renv::restore(packages = c("readxl", "data.table", "digest", "jsonlite", "renv"))
```

La ejecución de esta aportación se verificó con R 4.6.1 y la biblioteca del proyecto. Se restauraron sus dependencias; no se comprobó la ejecución del Quarto anterior ni de todas las dependencias de la plantilla. `data.table` se actualizó de 1.18.4 a 1.18.6.1 y se registró con `renv::snapshot(..., update = TRUE)` sin retirar los paquetes del equipo. La restauración inicial de 1.18.4 requería compilación y este equipo no tenía `make`.

El pipeline no instala paquetes, no abre Google Drive y no utiliza rutas personales. Las copias RDS de trabajo quedan en `output/cache/`, fuera de Git. También genera `data/processed/sima_horario.csv.gz` como copia consolidada local: supera los 25 MiB permitidos para subir un archivo desde el navegador y no se versiona en esta revisión. Los siete CSV anuales contienen las mismas filas y columnas. Para leer la base compartida con R base:

```r
source("scripts/03_leer_base_preparada.R", encoding = "UTF-8")
dim(base_sima)

# Vista de trabajo: los valores imputados sustituyen NA únicamente en memoria.
source("scripts/04_base_para_modelar.R", encoding = "UTF-8")
dim(base_modelo)
```

## Decisiones para el modelo de ozono

- `O3` es la concentración observada en la hora de la fila. Aún **no** es la etiqueta `O3(t+h)` de un modelo de anticipación.
- Cuando se defina `h`, construir la respuesta mediante una unión por **estación y hora exacta**, no desplazando filas: existen horas ausentes.
- No imputar O3 para crear etiquetas. Las filas sin respuesta futura válida se excluyen solamente del ajuste/evaluación correspondiente y se contabilizan allí.
- Separar cronológicamente entrenamiento, validación y prueba. La fecha de la respuesta debe quedar dentro del periodo asignado; evitar que una respuesta futura del entrenamiento caiga en validación.
- Mantener los cortes de esta imputación: ajuste 2020–2024, selección 2025, prueba 2026. Si se cambian, reajustar el imputador antes de evaluar el modelo. Las estimaciones de los años de entrenamiento son retrospectivas; no representan una simulación de operación en esos años. Usar meteorología de la hora de emisión o pronósticos disponibles entonces.
- `VARIABLE_preparado` combina observaciones y estimaciones; `VARIABLE_metodo` indica su origen. Las columnas originales no se sobrescribieron. Usar la vista `base_modelo` para trabajar con las predictoras preparadas sin confundir ambas versiones.
- Excluir del modelo `*_atipico` y `alguna_alerta_estadistica`: se calcularon con el año completo para diagnóstico retrospectivo. Tampoco usar archivo, fila de Excel o códigos de procedencia como predictores.
- Las variables de estación y temporada se conservan como categorías. Las dummies se crean sólo si las necesita el modelo. No se aplicó binning ni normalización a la base general.

## Colaborar sin romper `renv.lock`

1. Actualizar la rama antes de trabajar y abrir el proyecto para usar su biblioteca.
2. Instalar deliberadamente las dependencias nuevas con `renv::install()` y probar el código.
3. Ejecutar `renv::snapshot()` y revisar el diff. No aceptar eliminaciones masivas de paquetes de otros integrantes por tener una biblioteca local incompleta.
4. Si dos ramas modifican el lock, acordar las versiones y reconstruirlo con `restore()`/`install()`/`snapshot()`. No combinar a mano fragmentos JSON de versiones incompatibles.
5. Compartir scripts, `renv.lock`, `.Rprofile` y `renv/activate.R`. Los demás integrantes ejecutan `renv::restore()`; no se versiona `renv/library/`.

Referencias: [colaboración con renv](https://rstudio.github.io/renv/articles/collaborating.html) y [documentación de snapshot](https://rstudio.github.io/renv/reference/snapshot.html).

## Publicación y uso de IA

Repositorio: https://github.com/a01236941/Reto-Multi-Equipo4. Esta aportación usa la rama `preparacion-sima`. El estado verificado de publicación se registra en `reports/estado_publicacion.md`.

Codex de OpenAI apoyó la adaptación del código, la auditoría, las verificaciones y la redacción. Los números proceden de la ejecución sobre los archivos. Corresponde al equipo revisar las decisiones y contrastar las unidades, banderas y rangos con los documentos del socio formador antes de entregar.

Los archivos se publican mediante Git. Si se utiliza la subida manual, extraer primero el ZIP: no subirlo como un único archivo. Los datos preparados están divididos por año y cada archivo queda por debajo de 25 MiB. [Límites de subida de GitHub](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository).
