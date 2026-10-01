# Aportación a la Parte 2: secciones 2, 3 y 4

## 2. Preparación de los datos

Se integraron los siete Excel de 2020 a julio de 2026 siguiendo la unión del cuaderno BD.ipynb, adaptada a rutas locales. La base reúne 830 908 registros horarios de 15 estaciones. Se conservaron las 15 variables medidas; O3 será la respuesta y la meteorología será la principal fuente de predictoras. El horizonte de predicción aún debe definirlo el equipo.

La cobertura es desigual: hay 13 estaciones en 2020 y 14 en 2021. En 2022 aparecen las 15, aunque NO3 sólo tiene 743 registros desde diciembre. Se identificaron 187 horas sin fila dentro de las series de cada estación y año. Se registraron aparte de las celdas vacías, sin atribuirlas automáticamente a cambios de horario.

Se comprobó la clave fecha–estación y no hubo duplicados: 0 % eliminados. Se reconstruyeron cuatro fechas vacías aisladas porque las filas vecinas estaban separadas exactamente por dos horas. No se eliminaron registros completos: 0 %.

Se convirtieron a NA 322 lecturas (0.0026 % de las celdas): 26 valores de −9999, 292 humedades fuera de 0–100 %, dos presiones iguales a cero y dos temperaturas superiores a 100 °C. Se registró cada valor original y su motivo. Son filtros provisionales de plausibilidad; deben cotejarse con las unidades y los rangos anuales de SIMA.

Tras estas correcciones, faltaba el 11.26 % de las mediciones; en O3, 113 198 valores (13.62 %), y en PM2.5, 23.99 %. Los denominadores corresponden a las filas existentes, no a un calendario completo con 15 estaciones.

No se imputó por media ni mediana. En 13 predictoras se compararon persistencia, rezago de 24 horas y autorregresión con calendario. Los coeficientes se ajustaron con 2020–2024; el menor MAE en bloques ocultos de 2025 determinó el método por variable; 2026 se reservó para comprobarlo. Las entradas proceden de horas anteriores al bloque. Se estimaron únicamente las primeras tres horas desde la última medición real y se conservaron los NA restantes.

| Método aplicado | Celdas imputadas | % de todas las mediciones | % de faltantes previos |
|---|---:|---:|---:|
| Autorregresión | 99 828 | 0.80 % | 7.11 % |
| Último valor observado | 48 139 | 0.39 % | 3.43 % |
| Misma hora del día anterior | 4 627 | 0.04 % | 0.33 % |

En total se estimaron 152 594 celdas (10.87 % de los faltantes) y permaneció sin valor el 10.03 % de las mediciones en la vista preparada. O3 se mantuvo observado para no fabricar respuestas; WDR conservó sus vacíos por su naturaleza angular. Las estimaciones y su método están en columnas separadas. La evaluación de bloques breves no demuestra que puedan reconstruirse averías prolongadas ni que se conserven todos los picos.

Se marcaron como candidatos atípicos 144 656 celdas (1.53 % de las evaluables), presentes en 97 282 filas (11.71 %), mediante límites de Q1 − 3·RIC y Q3 + 3·RIC por estación, año y variable. WDR se excluyó de este criterio. No se borraron estos valores: un pico puede ser un episodio real. Las alertas son descriptivas y no se utilizarán como predictoras.

## 3. Transformación

Se añadieron año, mes, hora y temporada meteorológica. La hora y el mes se representaron también con seno y coseno. En la dirección del viento se usaron sen(WDR·π/180) y cos(WDR·π/180), para mantener próximas direcciones como 359° y 1°. Sus componentes se dejaron vacías cuando la velocidad fue cero.

No se aplicó binning ni escalado a las mediciones. Estación y temporada se conservaron como categorías; las dummies y la normalización se ajustarán con entrenamiento si el modelo elegido las requiere. No se asignaron categorías normativas a lecturas horarias sin verificar primero unidades e indicadores temporales.

## 4. Reformateo y reestructuración

Las hojas se unieron en una tabla ordenada por estación y hora. Los encabezados de fecha se unificaron como fecha_hora y se conservaron archivo y fila de Excel para rastrear cada medición. La hora escrita no se convirtió a una zona horaria supuesta. La salida se dividió en siete CSV comprimidos por año, acompañados de scripts, auditorías y renv.lock. Los Excel originales permanecen intactos y sus huellas SHA-256 permiten verificarlo.

[Base preparada en GitHub](https://github.com/a01236941/Reto-Multi-Equipo4/tree/preparacion-sima/data/processed). El estado de integración en la rama principal se indica en reports/estado_publicacion.md.

Se revisó el resumen del [artículo Transformer–Diffusion recomendado](https://doi.org/10.1007/978-3-032-37441-7_55), pero esta entrega no reproduce su arquitectura: el capítulo completo requiere suscripción y no se dispuso de su código. La comparación temporal realizada queda documentada en reports/metodo_imputacion.md.

**Declaratoria de uso de IA.** Se utilizó Codex de OpenAI para adaptar y ejecutar los scripts, auditar resultados, comprobar las salidas y apoyar la redacción. Las cifras provienen de la ejecución sobre los archivos. El equipo deberá revisar el texto y confirmar los criterios instrumentales con la documentación del socio formador.
