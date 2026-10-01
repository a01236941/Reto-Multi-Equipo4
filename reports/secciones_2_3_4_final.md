## 2. Preparación de los datos

### Selección de los datos

Unimos los siete archivos Excel que entregó SIMA, de enero de 2020 a julio de 2026. Cada hoja corresponde a una estación, así que la base queda con una fila por estación y hora: 830 908 registros de 15 estaciones y 15 variables medidas. No todas las estaciones existen todos los años. En 2020 hay 13, en 2021 hay 14 y desde 2022 están las 15, aunque NO3 empieza a registrar en diciembre de ese año.

La columna objetivo es O3. Como predictoras usamos la meteorología (TOUT, RH, SR, RAINF, PRS, WSR y WDR) y los precursores del ozono (NO, NO2, NOX y CO). PM10, PM2.5 y SO2 se limpian e imputan igual que el resto, pero no entran a la base de modelado porque no son precursores del ozono y PM2.5 tiene casi un 24 % de datos faltantes.

### Duplicados

Revisamos la combinación estación y fecha. No encontramos registros duplicados, por lo que se eliminó el 0 %. Cuatro filas de 2026 tenían la fecha vacía; las reconstruimos porque las filas vecinas estaban separadas exactamente por dos horas. También encontramos 187 horas que no tenían fila en el Excel dentro de la serie de una estación; las añadimos vacías para que la serie horaria quedara continua.

### Valores espurios o erróneos

Pasamos a NA 1 034 lecturas imposibles, el 0.008 % de las celdas. En la primera revisión fueron 322: valores de −9999, humedades fuera de 0 a 100 %, presiones iguales a cero y temperaturas mayores de 100 °C. En la segunda fueron 712: 427 temperaturas fuera de −15 a 50 °C (casi todas de la estación NTE, que marcaba −50 °C), 154 radiaciones mayores de 2 kW/m², 97 vientos de más de 150 km/h, 27 lluvias de más de 100 mm en una hora, una presión menor de 650 mmHg y seis valores de saturación de 999 en PM10 y PM2.5. Cada cambio queda guardado con su valor original y el motivo en los archivos de auditoría del repositorio.

### Valores faltantes

Tras la limpieza falta el 11.26 % de las mediciones. Por variable, el caso más alto es PM2.5 (23.99 %); en O3 falta el 13.62 %. Los huecos vienen sobre todo de fallas de energía, mantenimiento y lecturas que SIMA descarta en su validación.

No imputamos con la media ni con la mediana, porque ponen el mismo valor en cualquier hora y borran el ciclo diario y la relación entre contaminantes y clima. Usamos SAITS, un modelo Transformer de autoatención para series de tiempo multivariadas. Es la parte de imputación del método híbrido Transformer-Diffusion de Gómez Santos et al. (2027), que trabajó con datos históricos de SIMA. La parte de difusión (CSDI) no la incluimos porque sirve para generar varias versiones posibles de cada dato y el modelo de ozono solo necesita un valor por celda. Hua et al. (2024) también encontraron que SAITS supera a la media y la mediana en bases de calidad del aire.

El modelo recibe ventanas de 48 horas con las 14 variables escalares, la dirección del viento en seno y coseno, y la hora y el mes en seno y coseno. Antes de entrenar aplicamos logaritmo a las variables muy sesgadas y estandarizamos cada estación con su media y desviación de 2020 a 2024. Entrenamos con 2020 a 2024 (25 389 ventanas), usamos 2025 para validar y dejamos 2026 para la prueba. En la prueba escondimos bloques de 1 a 24 horas de datos reales y comparamos lo que estimaba cada método con el valor verdadero.

| Método | Error medio (MAE, en desviaciones estándar) | Correlación con el valor real |
|---|---:|---:|
| SAITS | 0.364 | 0.80 |
| Interpolación lineal | 0.492 | 0.63 |
| Último valor observado | 0.588 | 0.54 |
| Mediana | 0.744 | 0 |
| Media | 0.769 | 0 |

SAITS tuvo el menor error en general y su ventaja crece con el tamaño del hueco: con bloques de 24 horas su error fue de 0.41, frente a 0.58 de la interpolación y 0.76 de la media. Solo en huecos de una hora la interpolación lineal quedó ligeramente por delante (0.157 frente a 0.168). Por variable, SAITS fue el mejor en 10 de 16; en CO, PM10, PM2.5, PRS, RAINF y SO2 la interpolación tuvo algo menos de error.

Solo imputamos huecos de hasta 24 horas seguidas. Un hueco más largo suele ser una avería de días o meses, y dentro de una ventana de 48 horas el modelo ya no tiene información real para reconstruirlo. Con esta regla se imputaron 323 691 celdas, el 23.05 % de los faltantes, y siguen vacías el 8.67 % de las mediciones. Cada valor imputado tiene una columna de marca (`_imp` = 1) para distinguirlo de los medidos.

### Filas eliminadas para el modelo

En la base de modelado quitamos las filas sin O3 medido, porque la respuesta no puede ser un valor imputado, y las que seguían sin alguna predictora después de imputar.

| Concepto | Filas | % |
|---|---:|---:|
| Base imputada | 831 095 | 100 % |
| Eliminadas por no tener O3 medido | 113 385 | 13.64 % |
| Eliminadas por faltar alguna predictora | 172 293 | 20.73 % |
| Base final para modelar | 545 417 | 65.63 % |

### Valores atípicos

Marcamos como posibles atípicos los valores fuera de Q1 − 3·RIC y Q3 + 3·RIC, calculados por estación, año y variable. Salieron 144 656 celdas, el 1.53 % de las evaluadas. No las borramos, porque un pico de contaminación suele ser un episodio real y es justo lo que interesa anticipar. Solo eliminamos los valores físicamente imposibles descritos arriba.

### Datos categóricos

Las variables categóricas son `estacion` (15 niveles) y `temporada` (invierno, primavera, verano y otoño). En la base final creamos variables dummy con k − 1 columnas: 14 para estación, con CE como referencia, y 3 para temporada, con invierno como referencia.

## 3. Transformación de los datos

No discretizamos las mediciones, porque O3 y sus predictoras son continuas y los modelos que vamos a usar trabajan con valores continuos. La base final no está escalada: el logaritmo y la estandarización solo se usaron dentro de la imputación, y en la etapa de modelado se escalará con los datos de entrenamiento.

Creamos estos atributos derivados: año, mes, hora y temporada; seno y coseno de la hora y del mes, para que el modelo entienda que las 23 h están junto a las 0 h y diciembre junto a enero; seno y coseno de la dirección del viento, para que 359° y 1° queden cerca (con viento en calma valen 0); y una marca que indica si la fila tiene algún valor imputado.

## 4. Reformateo y reestructuración

Las hojas por estación se unieron en una sola tabla ordenada por estación y hora, con una columna `fecha_hora` común. La base se guarda en CSV, dividida por semestre, para respetar el límite de tamaño de GitHub:

- Base limpia: https://github.com/a01236941/Reto-Multi-Equipo4/tree/trunk/data/processed
- Base imputada con SAITS (con marcas de imputación): https://github.com/a01236941/Reto-Multi-Equipo4/tree/trunk/data/imputada
- Base final para modelar O3: https://github.com/a01236941/Reto-Multi-Equipo4/tree/trunk/data/final
- Código de la imputación: https://github.com/a01236941/Reto-Multi-Equipo4/tree/trunk/python

## Declaratoria de uso de IA

Opción B. Se utilizó IA de la siguiente forma:

- Herramienta: Codex (OpenAI) y Claude (Anthropic).
- Uso realizado: apoyo para escribir los scripts de limpieza en R y de imputación con SAITS en Python, ejecutarlos, revisar el repositorio y redactar el borrador de las secciones 2 a 4.
- Secciones donde se utilizó: Parte 2, secciones 2, 3 y 4, y código del repositorio.
- Validación realizada por los estudiantes: revisamos que las cifras del texto coinciden con las tablas de `reports/imputacion_saits/` y `reports/auditoria/`, revisamos las reglas de limpieza y los resultados de la prueba de imputación. Revisamos y verificamos el contenido y asumimos la responsabilidad del trabajo entregado.

## Referencias (añadir a la lista general)

Gómez Santos, J. E., et al. (2027). A hybrid Transformer-Diffusion architecture for multivariate air quality data imputation. En *Artificial Intelligence – COMIA 2026* (CCIS 3097, pp. 728–739). Springer. https://doi.org/10.1007/978-3-032-37441-7_55

Hua, V., Nguyen, T., Dao, M., Nguyen, H., & Nguyen, B. T. (2024). The impact of data imputation on air quality prediction problem. *PLOS ONE*. https://doi.org/10.1371/journal.pone.0306303

Du, W., Côté, D., & Liu, Y. (2023). SAITS: Self-attention-based imputation for time series. *Expert Systems with Applications, 219*, 119619. https://doi.org/10.1016/j.eswa.2023.119619
