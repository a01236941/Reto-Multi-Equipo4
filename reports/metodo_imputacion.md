# Imputación de la base SIMA

## Artículo recomendado

Gómez Santos, J. E., et al. (2027). *A Hybrid Transformer-Diffusion Architecture for Multivariate Air Quality Data Imputation*. Artificial Intelligence – COMIA 2026, CCIS 3097, pp. 728–739. [DOI: 10.1007/978-3-032-37441-7_55](https://doi.org/10.1007/978-3-032-37441-7_55). Springer fecha la publicación en línea el 13 de septiembre de 2026 y la cita del volumen en 2027.

Se consultaron la ficha y el resumen de Springer. Describen un modelo que combina SAITS, difusión condicional CSDI y adaptación LoRA por estación, orientado a reconstruir distribuciones y conservar picos de contaminación. Los agradecimientos mencionan las bases históricas de SIMA. Es una referencia directamente relacionada con el proyecto, pero sus resultados publicados no equivalen a una validación sobre los siete Excel de esta entrega.

El texto completo requiere suscripción en la sesión consultada. No se localizó código de los autores. **Esta entrega no implementa ni afirma reproducir esa arquitectura.** Para incorporarla harían falta el capítulo completo o su código, parámetros de entrenamiento y una evaluación con la misma separación temporal. No se instaló ni entrenó una red diferente bajo el nombre del artículo.

## Método ejecutado

Se compararon tres estimadores por variable: persistencia (última medición real), rezago de 24 horas y regresión autorregresiva con términos horarios y mensuales. Ninguno sustituye faltantes por la media o la mediana. La regresión es un método propio de esta preparación, no una reproducción del artículo.

Para el valor situado h horas después de la última observación, con h = 1, 2 o 3, la regresión usa la última lectura, la lectura anterior a ella, el valor de la misma hora del día anterior y seno/coseno de hora y mes. Los coeficientes se ajustan por estación, variable y h mediante mínimos cuadrados, con al menos 500 casos completos y matriz de rango completo. No se sustituyen regresores ausentes por constantes; si faltan entradas del método seleccionado, no se estima esa celda. La selección se hace por variable, agregando sus estaciones.

Se usa una rejilla horaria interna por estación. Las horas sin fila cuentan para calcular los rezagos, pero no se inventan registros de estaciones ausentes. Las predicciones no se reciclan como mediciones para rellenar la siguiente hora. Sólo se completan las primeras tres horas desde una observación real; el resto de una interrupción prolongada permanece vacío. El límite de tres horas es una decisión conservadora de alcance, no un máximo validado por SIMA.

Las estimaciones se restringen al dominio de trabajo: RH entre 0 y 100, TOUT entre −100 y 100, presión positiva y otras magnitudes no negativas. Son los mismos supuestos provisionales de unidades documentados en `criterios_y_diccionario.md`; no son rangos instrumentales oficiales. Las observaciones no se recortan.

## Validación temporal

- **2020–2024:** ajuste de coeficientes.
- **2025:** comparación y elección del método de menor MAE por variable; RMSE rompe empates.
- **Enero–julio de 2026:** prueba independiente, sin ajustar coeficientes ni cambiar la selección por su resultado.

Semilla: 20260930. Se ocultan hasta 60 bloques de cada longitud (1, 2 y 3 horas) por estación, variable y periodo. Cada bloque es un experimento independiente y los tres métodos se comparan sobre las mismas observaciones con contexto pasado disponible. En cada bloque se omiten todas las lecturas ocultas al construir las entradas. El calendario de ocultación y las predicciones quedan en `validacion_bloques.csv.gz`; las métricas y los coeficientes se comparten en la auditoría.

La evaluación representa interrupciones breves en segmentos observados, no averías prolongadas ni necesariamente el mecanismo de los faltantes reales. MAE y RMSE se expresan en la escala original de cada variable; no se comparan entre contaminantes con unidades distintas. Una estimación puntual puede suavizar picos y no conserva automáticamente la distribución conjunta. Este procedimiento no produce intervalos de incertidumbre ni demuestra superioridad frente al modelo generativo del artículo.

## Cómo utilizar la salida

Las columnas originales mantienen las mediciones después de la limpieza. Para las 13 predictoras escalares se añaden `VARIABLE_preparado` y `VARIABLE_metodo`. La primera contiene observaciones y estimaciones; la segunda distingue `observado`, `sin_imputar` y el método elegido. O3 permanece sin imputación porque será la respuesta; WDR conserva sus faltantes por ser angular. Tampoco se rellena una lluvia ausente con cero por defecto.

`scripts/04_base_para_modelar.R` genera en memoria `base_modelo` con las predictoras preparadas, recalcula las componentes del viento y conserva O3 observado. La tabla de auditoría enumera cada celda imputada, su estación, fecha, método y horas desde la última observación real.

La partición anterior corresponde a esta evaluación de imputación. Las estimaciones de 2020–2024 son preparación retrospectiva del entrenamiento, no una simulación de operaciones en esos años. El método fue seleccionado con 2025, por lo que ese año no debe presentarse después como prueba final independiente. Si el equipo cambia los cortes temporales, tiene que reajustar y seleccionar el imputador dentro de sus nuevos periodos. El horizonte de predicción de O3 sigue por definir y no debe confundirse con el límite de tres horas de imputación.

Referencias metodológicas: Hyndman y Athanasopoulos, *Forecasting: Principles and Practice*, [métodos ingenuos](https://otexts.com/fpp3/simple-methods.html) y [autorregresión](https://otexts.com/fpp3/AR.html).
