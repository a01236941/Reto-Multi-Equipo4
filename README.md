# Reto SIMA · Equipo 4
Preparación de los datos horarios de SIMA (enero 2021 a julio 2026, 15 estaciones) para **predecir la concentración de ozono (O3)** a partir de meteorología, precursores y variables de calendario. Modelo de regresión evaluado con R2 y MSE, bajo validación temporal en dos pasos. Metodología CRISP-DM, MA2003B.

## Qué base usar

| Carpeta | Contenido |
|---|---|
| `data/raw/` | Los siete Excel originales de SIMA, sin tocar |
| `data/processed/` | Base limpia: 830 908 filas, mediciones con las correcciones documentadas |
| `data/imputada/` | Base imputada con SAITS. Cada variable tiene una columna `_imp` (1 = valor imputado, 0 = medido) |
| `data/final/sima_modelo_o3.csv` | **Base limpia para modelar O3**: 522 208 filas y 40 columnas (enero 2021 a julio 2026) con O3 medido, predictoras completas y dummies de estación y temporada. Se excluyen 2020 y NOX |

**Unidades:** O3, NO, NO2 y SO2 en ppb; CO en ppm; PM10 y PM2.5 en µg/m³; TOUT en °C; RH en %; SR en kW/m²; RAINF en mm/hr; PRS en mmHg; WSR en km/h; WDR en grados. Los umbrales de la NOM están en ppm: 0.070 ppm equivalen a 70 ppb.

La base limpia se lee directamente:

```r
base <- read.csv("data/final/sima_modelo_o3.csv")
```

```python
import pandas as pd
base = pd.read_csv("data/final/sima_modelo_o3.csv")
```

Las carpetas `processed` e `imputada` están en CSV comprimidos (`.csv.gz`) divididos por año o semestre, que R y pandas leen sin descomprimir.

## Cómo se hizo

1. **Limpieza (R):** `scripts/01_preparar_datos.R` une los Excel, revisa duplicados, reconstruye fechas y pasa a NA las lecturas imposibles. Auditoría en `reports/auditoria/`.
2. **Imputación (Python):** `python/imputar_saits.py` aplica reglas físicas adicionales y entrena SAITS, la parte Transformer del método Transformer-Diffusion de Gómez Santos et al. (2027). Entrena con 2020–2024, valida con 2025 y prueba con 2026. Se usa 2020 solo aquí, como contexto histórico para el imputador; no forma parte de la base de modelado. Solo imputa huecos de hasta 24 horas y no usa media ni mediana. Resultados en `reports/imputacion_saits/`.
3. **Base final (Python):** `python/base_final.py` excluye 2020 y la variable NOX, quita las filas sin O3 medido o con predictoras vacías, crea las dummies y guarda `data/final/sima_modelo_o3.csv`. 2020 se excluye porque le falta el ozono en la mayor parte de sus horas; NOX, porque equivale prácticamente a NO + NO2. 2020 sí se usó para entrenar la imputación.
4. **Exploración descriptiva (R):** `scripts/codigo_etapa2.Rmd` lee `data/final/sima_modelo_o3.csv` y genera las tablas y gráficas del reporte de la Etapa 2.

Para repetir la imputación: `pip install -r python/requirements.txt` y después `python python/imputar_saits.py` y `python python/base_final.py` desde la raíz del proyecto.

La imputación anterior en R (`R/04_imputar.R`, columnas `*_preparado` de `data/processed`) se conserva como primera versión; la que se usa en el informe es la de SAITS.

El reporte de la Etapa 2 está en `docs/etapa2/Etapa2_Equipo4.pdf`.

El diccionario de variables y los criterios de limpieza están en `reports/criterios_y_diccionario.md`.
