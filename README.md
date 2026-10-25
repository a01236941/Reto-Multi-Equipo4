# Reto SIMA · Equipo 4
Pronóstico de la concentración de ozono (O3) a 24 horas en el Área Metropolitana de Monterrey, a partir de datos horarios de SIMA (enero 2021 a julio 2026, 13 estaciones), meteorología, precursores y variables de calendario. Regresión lineal múltiple evaluada con R2, RMSE, MSE, MAE y AUC bajo validación temporal en dos pasos, y comparada con una línea base de persistencia. PCA y k-means se usan como análisis exploratorio. Metodología CRISP-DM, MA2003B.

## Qué base usar

| Archivo | Contenido |
|---|---|
| `data/raw/` | Los siete Excel originales de SIMA, sin tocar |
| `data/final/sima_modelo_o3.csv.gz` | **Base para modelar O3**: 488 029 filas y 38 columnas (enero 2021 a julio 2026) con O3 medido, predictoras completas y dummies de estación y temporada. Se excluyen 2020, NOX y las estaciones NTE y NO3 |
| `data/final/sima_mascara_imputacion.csv.gz` | Máscara de imputación por estación y hora (columnas `*_imp`: 1 = valor imputado, 0 = medido), usada en el análisis de sensibilidad |
| `data/final/o3_horario_medido_2021_2026.csv` | O3 horario medido (sin imputar), usado para el indicador de la NOM-020 |

**Estaciones (13):** CE, NE, NE2, NE3, NO, NO2, NTE2, SE, SE2, SE3, SO, SO2 y SUR. NTE y NO3 se excluyen porque tienen menos de 40 % de las horas del periodo.

**Unidades:** O3, NO, NO2 y SO2 en ppb; CO en ppm; PM10 y PM2.5 en µg/m³; TOUT en °C; RH en %; SR en kW/m²; RAINF en mm/hr; PRS en mmHg; WSR en km/h; WDR en grados. Los umbrales de las normas están en ppm: 0.058 ppm equivalen a 58 ppb y 0.090 ppm a 90 ppb.

La base de modelado se lee directamente, sin descomprimir:

```r
base <- read.csv("data/final/sima_modelo_o3.csv.gz")
```

```python
import pandas as pd
base = pd.read_csv("data/final/sima_modelo_o3.csv.gz")
```

## Estructura del repositorio

| Carpeta | Contenido |
|---|---|
| `data/` | Datos originales (`raw/`) y base para modelar (`final/`) |
| `R/` | Funciones del flujo de limpieza en R: importación, preparación y exportación (`01_importar.R` a `03_exportar.R`) y la primera versión de la imputación (`04_imputar.R`) |
| `scripts/` | Limpieza (`01_preparar_datos.R`), lectura y vista compacta de la base preparada en R (`03_leer_base_preparada.R`, `04_base_para_modelar.R`) y análisis por etapa (`codigo_etapa2.Rmd`, `reto_etapa3.Rmd`, `reto_etapa4.rmd`) |
| `python/` | Imputación con SAITS y construcción de la base final |
| `reports/` | Auditoría de la limpieza, resultados de la imputación y diccionario de variables |
| `docs/` | Reportes de las etapas 2, 3 y 4, reporte en Word, cuaderno de referencia y figuras de la Etapa 4 |
| `quarto/` | Plantilla del reporte en Quarto con salida a Word (`reporte.qmd`); carga los Excel de 2024 y 2025 |

## Cómo se hizo

1. **Limpieza (R):** `scripts/01_preparar_datos.R` usa las funciones de `R/` para unir los Excel, revisar duplicados, reconstruir fechas y pasar a NA las lecturas imposibles. Genera la base limpia por año en `data/processed/`. Auditoría en `reports/auditoria/`.
2. **Imputación (Python):** `python/imputar_saits.py` lee la base limpia, aplica reglas físicas adicionales y entrena SAITS, la parte Transformer del método Transformer-Diffusion de Gómez Santos et al. (2027). Entrena con 2020–2024, valida con 2025 y prueba con 2026. Solo imputa huecos de hasta 24 horas y no usa media ni mediana. La imputación es retrospectiva: usa horas anteriores y posteriores al hueco. Escribe la base imputada en `data/imputada/` y los resultados en `reports/imputacion_saits/`.
3. **Base final (Python):** `python/base_final.ipynb` y `python/base_final.py` excluyen 2020 y la variable NOX, quitan las filas sin O3 medido o con predictoras vacías y las estaciones NTE y NO3, crean las dummies y exportan `sima_modelo_o3.csv`. Para subirla a GitHub se comprime con `gzip` (`data/final/sima_modelo_o3.csv.gz`). 2020 se excluye porque le falta el ozono en la mayor parte de sus horas (58.6 %); NOX, porque equivale prácticamente a NO + NO2. 2020 sí se usó para entrenar la imputación.
4. **Exploración descriptiva, Etapa 2 (R):** `scripts/codigo_etapa2.Rmd` genera las tablas y gráficas del reporte de la Etapa 2. Usa la base de 13 estaciones; el reporte de la Etapa 2 se hizo con 15 estaciones (522 208 registros), por lo que algunas cifras pueden diferir.
5. **Modelación, Etapa 3 (R):** `scripts/reto_etapa3.Rmd` ajusta la regresión lineal múltiple, el PCA (6 componentes) y el k-means del reporte de la Etapa 3, con el umbral de 70 ppb de esa etapa. Ese valor era un límite de 8 horas de la NOM-172-SEMARNAT-2019 aplicado a datos horarios, y la Etapa 4 lo corrige. Las cifras finales del informe están en `scripts/reto_etapa4.rmd`.
6. **Análisis final, Etapa 4 (R):** `scripts/reto_etapa4.rmd` contiene el análisis del informe final:
   - Modelo D (regresión sobre ln(O3) a 24 h con meteorología, precursores, rezagos de 1 a 3 h de O3 y NO2, hora, mes y estación), modelo mínimo (O3 de hoy, hora, mes y estación) y persistencia, evaluados sobre las mismas filas.
   - Validación temporal: entrenamiento 2021–2024 con prueba en 2025, y entrenamiento 2021–2025 con prueba en enero–julio de 2026.
   - Umbrales por promedio horario: 58 ppb (principal, fin de la banda "buena" del Índice AIRE Y SALUD, NOM-172-SEMARNAT-2023, Tabla 6) y 90 ppb (límite horario de la NOM-020-SSA1-2021, Tabla 1).
   - Matriz de confusión, AUC, episodios, comparación con igual número de alertas y bootstrap por bloques de 7 días.
   - Calibración por grupos de pronóstico y desempeño por estación con la cobertura de horas de cada periodo (varias estaciones tienen menos de 75 %). La figura `modelos_estacion.png` compara el R2 del modelo y el de la persistencia por estación.
   - Diagnósticos de supuestos (autocorrelación, heterocedasticidad, VIF), PCA (5 componentes) y k-means (k = 3) con el error por perfil.
   - Sensibilidad a lecturas de NO fuera del rango de operación de SIMA y a la imputación.
   - Indicador de la NOM-020 por estación y año (2021–2025).

La imputación anterior en R (`R/04_imputar.R`, columnas `*_preparado`) se conserva como primera versión; la que se usa en el informe es la de SAITS. Los scripts `scripts/03_leer_base_preparada.R` (une los siete archivos anuales de `data/processed/` en una sola tabla) y `scripts/04_base_para_modelar.R` (construye una vista compacta con las predictoras de esa primera imputación y sus marcas de imputación) pertenecen a esa primera versión: requieren haber corrido antes `scripts/01_preparar_datos.R` y no se usan en el informe final.

## Resultados principales (Etapa 4)

| Pronóstico | Periodo | R2 | RMSE (ppb) |
|---|---|---|---|
| Persistencia | 2025 | 0.500 | 14.80 |
| Modelo mínimo | 2025 | 0.618 | 12.93 |
| Modelo D | 2025 | 0.622 | 12.87 |
| Persistencia | 2026 ene–jul | 0.484 | 14.21 |
| Modelo mínimo | 2026 ene–jul | 0.575 | 12.89 |
| Modelo D | 2026 ene–jul | 0.587 | 12.72 |

El Modelo D reduce el error frente a la persistencia (MSE −24.4 % en 2025 y −19.9 % en 2026), pero no mejora de forma demostrable al modelo mínimo (diferencia en R2 de 0.004 y 0.012, con intervalos al 95 % que incluyen cero).

Detección de horas excedidas con alerta fija (alerta cuando el pronóstico supera el umbral):

| Pronóstico | Periodo | Detección 58 ppb | Precisión 58 ppb | Detección 90 ppb | Precisión 90 ppb |
|---|---|---|---|---|---|
| Modelo D | 2025 | 46.2 % | 57.9 % | 9.4 % | 52.8 % |
| Persistencia | 2025 | 56.8 % | 56.3 % | 29.5 % | 29.6 % |
| Modelo D | 2026 ene–jul | 43.3 % | 53.5 % | 6.1 % | 50.0 % |
| Persistencia | 2026 ene–jul | 52.6 % | 53.1 % | 33.0 % | 32.0 % |

Con el umbral de alerta nominal, el modelo no detecta más horas excedidas que la persistencia, aunque emite menos falsas alarmas. Con el mismo número de alertas a 58 ppb, el modelo detecta 55.2 % de las horas excedidas en 2025 (persistencia: 56.8 %) y 53.1 % en 2026 (persistencia: 52.6 %). El modelo ordena mejor el riesgo (AUC de 0.930 frente a 0.916 en 2025 a 58 ppb), pero con alerta fija pierde horas de ozono alto.

Diagnósticos: los residuos tienen autocorrelación de 0.859 en el rezago 1, hay heterocedasticidad (Breusch-Pagan, p < 2.2e-16) y multicolinealidad (GVIF hasta 25.67), por lo que los coeficientes individuales y los valores p no deben interpretarse. El k-means con k = 3 tiene silueta de 0.250: los perfiles describen un continuo y no grupos naturales.

Sensibilidad: excluir las 28 lecturas de NO fuera del rango de SIMA no cambia el R2 (0.622 a 0.623), y excluir las horas con predictoras imputadas (8.6 % en 2025) lo deja en 0.619.

2026 solo cubre hasta julio. El análisis completo, con la discusión, las limitaciones y las recomendaciones, está en `docs/etapa4/Etapa4_Equipo4.pdf`.

## Cómo reproducirlo

1. Abrir `MA2003B_Blank.Rproj` y restaurar el entorno de R con `renv::restore()` (lee `renv.lock`). El análisis final usa los paquetes `lmtest`, `car`, `dplyr`, `cluster` y `plotly`.
2. Correr la limpieza: `scripts/01_preparar_datos.R`, desde la raíz del proyecto. Lee `data/raw/` y genera `data/processed/`.
3. Instalar las dependencias de Python con `pip install -r python/requirements.txt` y correr, desde la raíz del proyecto, `python python/imputar_saits.py` y después `python python/base_final.py`.
4. Para repetir el análisis final: abrir `scripts/reto_etapa4.rmd` y generarlo con Knit. Las rutas de datos (`data/final/...`) se definen al inicio del script y son relativas a la raíz del proyecto, por lo que el directorio de trabajo debe ser esa raíz (el chunk `setup` lo fija con `knitr::opts_knit$set(root.dir = here::here())`). La figura `modelos_estacion.png` se guarda en `docs/etapa4/`.

La imputación con SAITS tiene semilla fija, pero un nuevo entrenamiento puede dar valores ligeramente distintos; la base de `data/final/` es la que usa el informe.

## Documentación

- Reportes de las etapas: `docs/etapa2/Etapa2_Equipo4.pdf`, `docs/etapa3/Etapa3_Equipo4.pdf` y `docs/etapa4/Etapa4_Equipo4.pdf` (informe final).
- Diccionario de variables y criterios de limpieza: `reports/criterios_y_diccionario.md`.
