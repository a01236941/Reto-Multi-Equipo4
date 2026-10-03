# Reto SIMA · Equipo 4
Preparación de los datos horarios de SIMA (enero 2020 a julio 2026, 15 estaciones) para **predecir la concentración de ozono (O3)** a partir de meteorología, precursores y variables de calendario. Modelo de regresión evaluado con R2 y MSE, bajo validación temporal en dos pasos. Metodología CRISP-DM, MA2003B.

## Qué base usar

| Carpeta | Contenido |
|---|---|
| `data/raw/` | Los siete Excel originales de SIMA, sin tocar |
| `data/processed/` | Base limpia: 830 908 filas, mediciones con las correcciones documentadas |
| `data/imputada/` | Base imputada con SAITS. Cada variable tiene una columna `_imp` (1 = valor imputado, 0 = medido) |
| `data/final/` | **Base para modelar O3**: 545 417 filas con O3 medido, predictoras completas y dummies de estación y temporada |

**Unidades:** O3, NO, NO2, NOX y SO2 en ppb; CO en ppm; PM10 y PM2.5 en µg/m³; TOUT en °C; RH en %; SR en kW/m²; PRS en mmHg; WSR en km/h; WDR en grados. Los umbrales de la NOM están en ppm: 0.070 ppm equivalen a 70 ppb.

Todos los archivos son CSV comprimidos (`.csv.gz`) divididos por año o semestre. Se leen sin descomprimir:

```r
archivos <- list.files("data/final", pattern = "csv.gz$", full.names = TRUE)
base <- do.call(rbind, lapply(archivos, read.csv))
```

```python
import pandas as pd, glob
base = pd.concat(pd.read_csv(a) for a in sorted(glob.glob("data/final/*.csv.gz")))
```

## Cómo se hizo

1. **Limpieza (R):** `scripts/01_preparar_datos.R` une los Excel, revisa duplicados, reconstruye fechas y pasa a NA las lecturas imposibles. Auditoría en `reports/auditoria/`.
2. **Imputación (Python):** `python/imputar_saits.py` aplica reglas físicas adicionales y entrena SAITS, la parte Transformer del método Transformer-Diffusion de Gómez Santos et al. (2027). Entrena con 2020–2024, valida con 2025 y prueba con 2026. Solo imputa huecos de hasta 24 horas y no usa media ni mediana. Resultados en `reports/imputacion_saits/`.
3. **Base final (Python):** `python/base_final.py` quita las filas sin O3 medido o con predictoras vacías y crea las dummies.

Para repetir la imputación: `pip install -r python/requirements.txt` y después `python python/imputar_saits.py` y `python python/base_final.py` desde la raíz del proyecto.

La imputación anterior en R (`R/04_imputar.R`, columnas `*_preparado` de `data/processed`) se conserva como primera versión; la que se usa en el informe es la de SAITS.

El diccionario de variables y los criterios de limpieza están en `reports/criterios_y_diccionario.md`.
