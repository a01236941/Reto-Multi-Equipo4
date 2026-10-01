# Aportación a la Parte 2: preparación, transformación y reestructuración

Borrador para integrar al informe del equipo. Objetivo: predecir ozono (O3). El horizonte de anticipación aún no está definido. Las reglas de plausibilidad deben cotejarse con el diccionario y los rangos anuales del socio formador antes de cerrar la validación de sensores.

## 2. Preparación de los datos

Se integraron los siete archivos de 2020 a julio de 2026, con 830 908 registros horarios de 15 estaciones. Se conservaron las 15 variables medidas para mantener una base común; O3 será la variable respuesta y las variables meteorológicas serán las predictoras principales. La respuesta futura se construirá cuando el equipo defina cuántas horas desea anticipar. No se usará la meteorología observada en el futuro como entrada del modelo.

La cobertura cambia entre años: en 2020 aparecen 13 estaciones y en 2021, 14. Aunque en 2022 ya están las 15, NO3 sólo contiene 743 registros desde el 1 de diciembre a la 01:00. Se identificaron 187 horas sin fila entre el primer y último registro de cada estación y año. Estos huecos se reportaron por separado de las celdas vacías y no se atribuyeron automáticamente al cambio de horario. Por ejemplo, falta el 29 de enero de 2026 a las 16:00 en las 15 estaciones.

Se revisó la combinación fecha y estación y no se encontraron duplicados: 0 % eliminados. Cuatro filas de 2026 tenían la fecha vacía; se reconstruyó únicamente esa fecha porque las filas contiguas estaban separadas exactamente por dos horas. No se alteraron sus mediciones. Se conservaron todas las filas, por lo que el porcentaje de registros eliminados fue 0 %.

Se sustituyeron por NA 322 lecturas (0.0026 % de las 12 463 620 celdas de medición): 26 valores de −9999, 292 humedades fuera de 0–100 % además de los −9999, dos presiones iguales a cero y dos temperaturas superiores a 100 °C. El filtro de temperatura es una regla amplia de plausibilidad del análisis; no se presenta como un rango oficial de SIMA. Se guardó el valor original y el motivo de cada cambio. Los demás valores sospechosos se mantuvieron para revisión.

Después de estas correcciones, las mediciones faltantes representan 11.26 % de las celdas. En O3 faltan 113 198 valores (13.62 %); en PM2.5, 23.99 %. Los porcentajes se calcularon sobre las filas existentes de cada variable y se desglosaron por estación y año. No describen la disponibilidad respecto de un calendario completo de 15 estaciones.

En esta base no se imputaron mediciones: 0 % por interpolación, 0 % por media o mediana y 0 % por arrastre del último valor. Los NA se conservaron porque aún falta fijar el horizonte y la separación temporal del modelo. En particular, no se imputará O3 para crear respuestas de evaluación. Si se imputan predictoras en la siguiente etapa, los parámetros se estimarán únicamente con el entrenamiento y se registrará el método y la proporción rellenada. Reconstruir las cuatro fechas se contabiliza aparte de imputar mediciones.

Para localizar valores atípicos se usaron límites de Q1 − 3·RIC y Q3 + 3·RIC por variable, estación y año, con al menos 30 observaciones y RIC positivo. Se excluyó WDR por su naturaleza circular. Se marcaron 144 656 celdas (1.53 % de las 9 439 534 evaluables), presentes en 97 282 filas (11.71 %). Estos indicadores son descriptivos: no prueban un error del sensor y no se usarán como predictores. No se eliminaron picos de contaminación con esta regla, porque podrían corresponder a episodios reales.

## 3. Transformación

Se añadieron año, mes, hora y temporada meteorológica: invierno (diciembre–febrero), primavera (marzo–mayo), verano (junio–agosto) y otoño (septiembre–noviembre). La hora y el mes también se representaron mediante seno y coseno. Para WDR se calcularon sen(WDR·π/180) y cos(WDR·π/180), de manera que 359° y 1° queden cerca. Se conservó la dirección original y se dejaron vacías sus componentes cuando la velocidad del viento fue cero.

No se discretizaron ni escalaron las concentraciones, para conservar sus valores y unidades. La estación y la temporada se mantuvieron como categorías; no se generaron dummies en la base general. Si el modelo las requiere, su codificación, la imputación de predictoras y el escalado se ajustarán con el conjunto de entrenamiento. Tampoco se asignaron categorías normativas a las lecturas horarias, pues requieren verificar unidades, norma aplicable e indicador temporal.

## 4. Reformateo y reestructuración

Las hojas se unieron en una tabla con una fila por fecha y estación. Se unificaron los encabezados `Fecha y hora` y `date` como `fecha_hora`, se ordenaron los registros y se añadieron archivo, hoja/estación y fila de Excel para conservar su procedencia. La hora se mantiene tal como está escrita en los Excel, sin atribuirle una zona horaria que no viene documentada. Se exportó la tabla en CSV comprimido, junto con las tablas de auditoría y los scripts de R. Los siete originales permanecen sin cambios y cada uno cuenta con una huella SHA-256.

Repositorio del equipo: https://github.com/a01236941/Reto-Multi-Equipo4. Consultar el README para conocer el estado de publicación de esta aportación y la ubicación de `data/processed/sima_horario.csv.gz`.

**Declaratoria de uso de IA.** Se utilizó Codex de OpenAI como apoyo para adaptar la importación a rutas locales, elaborar y ejecutar los scripts de limpieza, verificar la consistencia de los resultados y redactar este borrador. Las cifras proceden de los archivos analizados. La revisión del equipo y la confirmación de las reglas con la documentación del socio formador quedan pendientes antes de la entrega final.
