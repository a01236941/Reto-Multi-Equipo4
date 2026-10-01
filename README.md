# Reto SIMA · Equipo 4

Preparación de datos horarios para predecir **ozono (O3)** con meteorología, como parte del objetivo 6 y de la metodología CRISP-DM.

La base preparada conserva valores faltantes. El horizonte de predicción, la división temporal y los rangos oficiales de sensores por año siguen pendientes de confirmación. Esta preparación no equivale a una validación instrumental de SIMA ni a un modelo ya entrenado.

## Archivos para trabajar

| Archivo o carpeta | Contenido |
|---|---|
| `data/raw/` | Los siete Excel originales del ZIP proporcionado, 2020–julio de 2026 |
| `data/processed/sima_horario.csv.gz` | Tabla preparada con 830 908 filas, sin imputación de mediciones |
| `R/01_importar.R` | Importación de todas las hojas desde rutas locales |
| `R/02_preparar.R` | Fechas, duplicados, correcciones, faltantes, alertas y atributos derivados |
| `scripts/01_preparar_datos.R` | Ejecución completa desde los Excel |
| `scripts/02_generar_informe.R` | Redacción de las secciones 2–4 con cifras de la auditoría |
| `reports/secciones_2_3_4.md` | Borrador para integrar al informe del equipo |
| `reports/auditoria/` | Resultados por variable, estación y año; cambios y procedencia |
| `reports/criterios_y_diccionario.md` | Definiciones, reglas, denominadores y límites del análisis |
| `tests/verificar_preparacion.R` | Comprobaciones de fechas, claves, transformación circular y cifras |
| `renv.lock` | Versiones de R y paquetes del proyecto |

Los Excel que ya existían directamente en `data/` y el cuaderno Quarto original se conservaron. Sus huellas difieren de las versiones 2024 y 2025 del ZIP. La nueva importación lee **solamente `data/raw/`** para no mezclar versiones ni duplicarlas.

## Reproducir en RStudio

Abra `MA2003B_Blank.Rproj`. El proyecto ya tiene `renv`; no vuelva a ejecutar `renv::init()`.

```r
# Restauración completa del entorno del equipo.
renv::restore()

# Ejecutar en este orden, desde la raíz del proyecto.
source("scripts/01_preparar_datos.R", encoding = "UTF-8")
source("tests/verificar_preparacion.R", encoding = "UTF-8")
source("scripts/02_generar_informe.R", encoding = "UTF-8")
```

Para ejecutar únicamente esta preparación puede restaurar sus dependencias:

```r
renv::restore(packages = c("readxl", "data.table", "digest", "jsonlite", "renv"))
```

La ejecución de esta aportación se verificó con R 4.6.1 y la biblioteca del proyecto. Se restauraron sus dependencias; no se comprobó la ejecución del Quarto anterior ni de todas las dependencias de la plantilla. `data.table` se actualizó de 1.18.4 a 1.18.6.1 y se registró con `renv::snapshot(..., update = TRUE)` sin retirar los paquetes del equipo. La restauración inicial de 1.18.4 requería compilación y este equipo no tenía `make`.

El pipeline no instala paquetes, no abre Google Drive y no utiliza rutas personales. Las copias RDS de trabajo quedan en `output/cache/`, fuera de Git. Para leer directamente el CSV comprimido con R base:

```r
base <- read.csv(gzfile("data/processed/sima_horario.csv.gz"),
                 na.strings = "NA", check.names = FALSE)
```

## Decisiones para el modelo de ozono

- `O3` es la concentración observada en la hora de la fila. Aún **no** es la etiqueta `O3(t+h)` de un modelo de anticipación.
- Cuando se defina `h`, construir la respuesta mediante una unión por **estación y hora exacta**, no desplazando filas: existen horas ausentes.
- No imputar O3 para crear etiquetas. Las filas sin respuesta futura válida se excluyen solamente del ajuste/evaluación correspondiente y se contabilizan allí.
- Separar cronológicamente entrenamiento, validación y prueba. La fecha de la respuesta debe quedar dentro del periodo asignado; evitar que una respuesta futura del entrenamiento caiga en validación.
- Ajustar imputación, escalado y categorías únicamente con entrenamiento. Usar meteorología de la hora de emisión o pronósticos disponibles entonces, no observaciones futuras.
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

Repositorio: https://github.com/a01236941/Reto-Multi-Equipo4. Esta aportación se prepara en la rama `preparacion-sima`. Su publicación remota se registra en `reports/estado_publicacion.md`; tener una copia local no significa que GitHub ya contenga los cambios.

Codex de OpenAI apoyó la adaptación del código, la auditoría, las verificaciones y la redacción. Los números proceden de la ejecución sobre los archivos. Corresponde al equipo revisar las decisiones y contrastar las unidades, banderas y rangos con los documentos del socio formador antes de entregar.
