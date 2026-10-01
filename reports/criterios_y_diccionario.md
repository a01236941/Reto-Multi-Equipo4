# Criterios de preparación y lectura de la base

## Alcance y procedencia

Se analizaron únicamente los siete Excel entregados por SIMA (2020 a julio de 2026). Se adaptó la idea del cuaderno `BD.ipynb`: recorrer archivos y hojas, unificar la fecha y añadir estación y año. La descarga con `googledrive` se sustituyó por lectura local. El cuaderno original no se ejecutó.

Cada fila conserva `archivo`, `estacion` y `fila_excel`. `anio_archivo` se extrae del nombre del libro; `anio` se deriva de la fecha y se verifica que coincidan. `fecha_original` conserva el serial de Excel como texto. Los hashes SHA-256 permiten comprobar que los libros permanecen intactos.

Los libros no incluyen columnas separadas con banderas de validación. No se atribuyeron los vacíos a fallos específicos de sensores, mantenimiento o validación sin evidencia adicional. Tampoco se convirtió la ausencia de una hoja o los periodos anteriores al primer registro en mediciones a imputar.

## Fechas y duplicados

Los seriales de Excel se convierten con origen `1899-12-30`, redondeando a segundos para evitar el error numérico de las fracciones de día. R usa UTC como contenedor técnico de la hora escrita; **no representa una conversión a UTC**. El CSV exporta fecha y hora sin `Z` ni desplazamiento. Antes de unir con otras fuentes, confirmar la convención horaria original. No se aplicó un calendario de cambios de horario supuesto.

Sólo se reconstruyen fechas vacías aisladas si ambas filas vecinas pertenecen al mismo archivo y estación, son consecutivas y distan exactamente dos horas. Los demás casos se separan en cuarentena. Las cuatro reconstrucciones de 2026 están en `fechas_reconstruidas.csv`.

La clave es estación + fecha. Dos filas con la misma clave y las mismas 15 mediciones se deduplican; si sus mediciones difieren, el proceso se detiene y escribe el conflicto para revisión. No se promedian versiones contradictorias. En estos siete archivos no se encontraron duplicados tras resolver las fechas.

## Correcciones explícitas

| Regla | Acción | Aplicación |
|---|---|---|
| Código `-9999` | Sustituir por `NA` | 26 celdas; valor incompatible con las magnitudes afectadas. Su significado exacto en el catálogo está pendiente |
| RH fuera de 0–100 % | Sustituir por `NA` | 292 celdas adicionales; regla de dominio adoptada para trabajar |
| PRS ≤ 0 | Sustituir por `NA` | 2 celdas |
| TOUT fuera de −100 a 100 °C | Sustituir por `NA` | 2 celdas adicionales; filtro amplio de plausibilidad, no rango de operación SIMA |
| WDR fuera de 0–360°, WSR o RAINF negativos | Sustituir por `NA` | Sin casos adicionales a los `-9999` |

Estas reglas quedan versionadas para poder revisarlas con el catálogo. RH en %, TOUT en °C y WDR en grados son las convenciones de trabajo; deben cotejarse con el documento entregado por SIMA. En particular, que una lectura pase estos filtros **no demuestra** que el sensor estuviera funcionando bien. Persisten candidatos como TOUT = 84.47 o velocidades elevadas que requieren rangos instrumentales, unidades y contexto antes de corregirlos. No se intercambian columnas ni se reconstruyen valores a partir de una sospecha de transcripción.

Los gases, las partículas y el resto de las magnitudes mantienen la escala de los archivos. No se asumió que O3 estuviera en ppm ni se dividió automáticamente entre 1 000. Las unidades de los datos fuente deben confirmarse antes de usar normas o comparar modelos con otras fuentes. La información institucional sobre parámetros puede consultarse en el [reporte oficial SIMA de abril de 2026](https://aire.nl.gob.mx/docs/reportes/mensuales/2026/04_Reporte_Abril_2026.pdf), pero no sustituye el diccionario específico de estos libros.

## Faltantes e imputación

Se normalizan vacíos y códigos textuales `NA`, `N/A`, `NULL` y `NaN`, y se registran textos inesperados; en estos siete libros no aparecieron tokens no numéricos en las mediciones. Cero se conserva cuando es una medición admisible; no significa ausencia de datos.

Los porcentajes por variable usan como denominador las filas existentes. Los porcentajes globales usan 830 908 × 15 = 12 463 620 celdas de medición. La ausencia de una fila horaria se contabiliza en `horas_sin_fila_interiores.csv`, no dentro de esos porcentajes. Las hojas ausentes aparecen en `cobertura_estacion_anio.csv`.

Las columnas originales conservan los NA después de la limpieza. En 13 predictoras se añaden columnas `*_preparado` y `*_metodo` con estimaciones de hasta tres horas desde la última observación real. Se comparan persistencia, rezago de 24 horas y autorregresión; los resultados y porcentajes están en `imputacion.csv`. No se imputa por media ni mediana. O3 y WDR conservan sus faltantes. Esta fue la primera versión de la imputación. La versión final usa SAITS (`python/imputar_saits.py`) y sus resultados están en `reports/imputacion_saits/`. Se evita rellenar series enteras, asumir cero para lluvia ausente o utilizar lecturas futuras como entradas del imputador.

`faltantes_por_variable.csv`, `faltantes_por_estacion.csv` y `faltantes_estacion_anio.csv` describen las mediciones tras las correcciones y **antes** de usar las columnas imputadas. `imputacion.csv` permite obtener los faltantes restantes restando `imputados` de `faltantes`. En `resumen.json`, `faltantes_finales` conserva el conteo de NA de las mediciones; `faltantes_base_uso` corresponde a la vista con predictoras preparadas. No se suman las columnas duplicadas al denominador de 15 mediciones.

## Alertas estadísticas

Para cada variable distinta de WDR, estación y año se calculan Q1 y Q3 (cuantiles tipo 7). Sólo se evalúan grupos con al menos 30 observaciones e intervalo intercuartílico positivo. Se marca lo que queda fuera de `[Q1 − 3·RIC, Q3 + 3·RIC]`. Los grupos constantes o con RIC cero no se clasifican automáticamente; el porcentaje usa sólo celdas evaluables y no se extrapola a ellas.

Las distribuciones de lluvia, radiación y contaminantes pueden ser asimétricas. Un candidato no equivale a sensor averiado, ni una celda sin alerta equivale a dato validado. Ninguna fila ni medición se elimina por esta prueba. Estas banderas son únicamente descriptivas y deben excluirse de las entradas predictivas, pues usan información del año completo.

## Columnas añadidas

| Columna | Significado |
|---|---|
| `fecha_reconstruida` | Se completó sólo la fecha usando las dos filas vecinas |
| `*_corregido` | La lectura de esa variable se convirtió a NA; consultar motivo en auditoría |
| `*_atipico` | Candidato descriptivo por 3·RIC, no causa de eliminación |
| `alguna_alerta_estadistica` | Al menos una variable fue candidata |
| `anio`, `mes`, `hora` | Componentes de la fecha escrita en Excel |
| `temporada` | Estación meteorológica convencional del hemisferio norte |
| `hora_sin`, `hora_cos` | Ciclo de 24 horas |
| `mes_sin`, `mes_cos` | Ciclo de 12 meses |
| `WDR_sin`, `WDR_cos` | Representación circular de dirección, sin magnitud del viento |
| `viento_calma` | WSR = 0; NA si falta WSR |
| `*_preparado` | Copia de la variable con estimaciones sólo donde faltaba una medición |
| `*_metodo` | Observado, sin imputar o nombre del imputador seleccionado |

WDR = 360 y WDR = 0 generan las mismas componentes. Si WSR = 0, las componentes se dejan vacías; si falta WSR pero existe WDR, la dirección se conserva y `viento_calma` queda NA. La dirección no se sustituye por una media aritmética de grados.
