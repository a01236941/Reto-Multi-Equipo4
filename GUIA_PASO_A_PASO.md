# Tu entrega SIMA: qué hacer, dónde ponerlo y por qué

Esta guía corresponde a tu parte del equipo: preparación y limpieza, transformación, reestructuración y mantenimiento del repositorio. El contaminante elegido es **ozono (O3)**. Todavía no se ha decidido cuántas horas se anticipará la predicción.

## 1. Lo que ya tienes y lo que falta

Ya se integraron los siete Excel de 2020 a julio de 2026. Hay 830 908 registros y 15 variables medidas; la exportación tiene 63 columnas porque también incluye procedencia, atributos derivados y banderas de revisión. No hay 63 mediciones originales.

Ya están hechos la revisión de claves duplicadas, el inventario de faltantes, las cuatro reconstrucciones de fecha, las correcciones documentadas de 322 lecturas, las alertas estadísticas, las transformaciones de fecha y viento, los scripts y el borrador de tus secciones. Los originales se conservaron intactos y se verificaron las salidas.

**La base aún no está lista para presentarse como una base completamente imputada o validada por SIMA.** Falta contrastar las unidades y las reglas provisionales con el diccionario y los rangos anuales del socio formador, evaluar la imputación de predictoras, definir la partición temporal del modelo y publicar los archivos. El código actual conserva los NA.

## 2. Si quieres que Codex haga la subida

Se necesitan dos cosas distintas: permiso para escribir en el repositorio y una sesión de Git autorizada en este equipo.

1. Si tu cuenta todavía no es colaboradora, Jessica debe abrir el repositorio del equipo, entrar en **Settings → Collaborators → Add people**, buscar tu usuario exacto e invitarte. Tú debes aceptar la invitación. Si ya eres colaborador, este paso se omite.
2. Abre **PowerShell** en Windows. No pegues el siguiente comando en la consola de R.
3. Pega y ejecuta:

```powershell
& "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe" credential-manager github login --browser
```

4. Si se abre el navegador, inicia sesión con la cuenta que tiene acceso al repositorio y completa la autorización de Git Credential Manager. Las credenciales se introducen en GitHub, no en el chat.
5. Cuando el comando termine correctamente, avisa que ya autorizaste el acceso. Codex podrá verificar la cuenta y el permiso antes de subir la rama.

La carpeta de trabajo que ya tiene Git, la rama y los cambios guardados es:

```text
C:\Users\tyut6565\Documents\Codex\2026-09-29\te-hago-el-2-9-completo\outputs\Reto-Multi-Equipo4
```

La rama local es `preparacion-sima`. No es necesario crear otro repositorio ni empezar de cero. Abrir GitHub en el navegador no autentica automáticamente la copia de Git que ejecuta los comandos. En los intentos anteriores no se completó la vinculación; no se publicó ninguna rama.

Si el comando se queda esperando sin abrir una página ni mostrar instrucciones, ciérralo con **Ctrl+C** y usa el camino manual del apartado siguiente. No generes ni pegues tokens en el chat para resolverlo.

Referencia: [invitar colaboradores](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/inviting-collaborators-to-a-personal-repository).

## 3. Si lo vas a subir tú desde la página de GitHub

Usa el paquete **SIMA-subida-manual.zip** entregado junto con esta guía. Es la versión preparada para la web. No subas el ZIP como un archivo dentro del repositorio: GitHub no lo descomprime para crear la estructura del proyecto.

La subida manual también requiere que tu cuenta pueda escribir en el repositorio. Si no tienes permiso, Jessica puede añadirte o hacer la subida con el mismo paquete.

1. En Windows, haz clic derecho sobre el ZIP y elige **Extraer todo**.
2. Entra en la carpeta extraída `Reto-Multi-Equipo4`. Debes ver directamente `README.md`, `renv.lock`, `R`, `scripts`, `data`, `reports` y otros archivos. Esa carpeta es la raíz del proyecto.
3. Abre [el repositorio del equipo](https://github.com/a01236941/Reto-Multi-Equipo4) e inicia sesión.
4. Comprueba que estás viendo la raíz del repositorio, no el interior de `data` ni de otra carpeta. Selecciona la rama `trunk` como punto de partida.
5. Pulsa **Add file → Upload files**. Desde el explorador de Windows, arrastra **el contenido que está dentro de `Reto-Multi-Equipo4`**, incluidas las carpetas. No arrastres la carpeta contenedora completa: eso crearía una carpeta extra dentro del repositorio.
6. Espera a que terminen las cargas. El paquete contiene menos de 100 archivos y cada archivo está por debajo de 25 MiB. Las carpetas deben conservar rutas como `R/01_importar.R` y `data/raw/BD 2020.xlsx`.
7. Escribe este mensaje de commit: **Añadir preparación y auditoría de datos SIMA**.
8. Selecciona la opción de crear una rama para los cambios. Usa `preparacion-sima-manual`, para distinguirla de la rama que está en la copia local de Codex. Confirma con el botón que muestre GitHub, normalmente **Propose changes** o **Commit changes**.
9. Abre la solicitud de integración (*pull request*) de esa rama hacia `trunk`. Usa el título y la descripción del apartado 4. Revisa la pestaña **Files changed** antes de integrarla.
10. Cuando el equipo revise e integre la solicitud, la entrega quedará en `trunk`. Si aún no se integra, los enlaces de entrega deben apuntar a `preparacion-sima-manual`, donde sí están los archivos.

No mezcles estos dos caminos: si subes desde la web, avisa a quien gestione la copia local antes de intentar publicar también la rama local. Así se evita crear dos versiones de la misma aportación.

El paquete conserva la plantilla y los dos Excel que ya estaban en la raíz de `data/`. No los usa para la nueva unión. **Antes de confirmar, revisa cualquier archivo existente que GitHub muestre como modificado**: si un compañero lo cambió después de preparar el paquete, conserva su trabajo y combina sólo los cambios de esta aportación. Esto es especialmente importante para `README.md` y `renv.lock`.

Referencia: [subir archivos desde GitHub](https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository). El límite web es 25 MiB por archivo y 100 archivos por carga.

## 4. Texto para la solicitud de integración

Título:

```text
Preparación reproducible de datos SIMA 2020–2026
```

Descripción:

```text
Se integra la lectura local de los siete Excel y se prepara una base de 830 908 registros para el proyecto de predicción de ozono. Se añaden la auditoría por estación, variable y año; las correcciones con trazabilidad; las variables temporales y circulares del viento; y el borrador de las secciones 2–4.

La base se comparte en siete CSV comprimidos por año para permitir la subida desde el navegador. Los originales se mantienen intactos. No se imputaron mediciones; las reglas provisionales deben contrastarse con los rangos de SIMA antes de cerrar la preparación para modelado.

Validación: ejecución sobre los siete Excel, pruebas de fechas y claves, comprobación de duplicados contradictorios, transformación circular, reconciliación de cifras, hashes de originales y equivalencia de la exportación anual con la base consolidada. Se actualiza data.table en renv.lock conservando las otras dependencias del equipo.
```

Este texto describe pruebas ejecutadas por Codex. No implica que el equipo ya haya revisado o aprobado científicamente los criterios.

## 5. Qué archivo va dónde y para qué sirve

Las rutas de esta tabla son relativas a la raíz del repositorio. No hay que pegar el contenido de todos los scripts en un único archivo: las carpetas y nombres ya vienen preparados.

| Ubicación | Qué poner | Por qué está ahí |
|---|---|---|
| `data/raw/` | Los siete `BD 20xx.xlsx` del ZIP original | Son la fuente intacta. Permiten repetir el análisis y comprobar cualquier corrección |
| `data/processed/` | `sima_horario_2020.csv.gz` hasta `sima_horario_2026.csv.gz` | Es la misma base preparada dividida por año. Suma 830 908 filas |
| `R/01_importar.R` | El archivo completo que ya está preparado | Une los Excel locales y normaliza el nombre de la fecha |
| `R/02_preparar.R` | El archivo completo que ya está preparado | Aplica las reglas y produce la auditoría; no instala paquetes |
| `R/03_exportar.R` | El archivo completo que ya está preparado | Guarda los siete archivos anuales y una copia consolidada local |
| `scripts/01_preparar_datos.R` | El archivo de ejecución principal | Permite repetir todo desde los Excel |
| `scripts/02_generar_informe.R` | El generador del borrador | Toma cifras de la auditoría y redacta las secciones 2–4 |
| `scripts/03_leer_base_preparada.R` | El lector de los siete CSV | Deja `base_sima` en R sin repetir toda la limpieza |
| `reports/auditoria/` | Todas las tablas ya generadas | Respaldan porcentajes, fechas, cambios, huecos y alertas |
| `reports/secciones_2_3_4.md` | El borrador de tu aportación | Es el texto que vas a integrar en el documento del equipo |
| `reports/criterios_y_diccionario.md` | El documento de criterios | Explica cada regla y sus limitaciones; es más detallado que el informe |
| `tests/verificar_preparacion.R` | Las comprobaciones preparadas | Detecta claves, fechas o conteos inconsistentes |
| `README.md` | El README preparado, combinado con aportaciones nuevas del equipo si las hay | Explica qué contiene el proyecto y cómo reproducirlo |
| `renv.lock` | El lock preparado, revisando conflictos con el del equipo | Fija las versiones de R y paquetes |
| `.Rprofile`, `renv/activate.R`, `renv/settings.json` | Los archivos de configuración del proyecto | Activan y configuran el entorno de R |
| `.gitignore`, `.gitattributes` | Los archivos preparados | Evitan subir caches y establecen el tratamiento de texto y binarios |
| `MA2003B_Blank.Rproj` | El proyecto existente | Es lo que abres con RStudio para trabajar desde la carpeta correcta |

El paquete ya incluye estos archivos. También conserva `LICENSE`, `_quarto.yml`, `quarto/` y `docs/` de la plantilla; no tienes que rehacerlos para tu aportación.

No subas `.git/`, `renv/library/`, `output/cache/`, `.Rhistory`, `.RData` ni credenciales. Esas carpetas y archivos no están incluidos en el paquete manual. El CSV consolidado local `sima_horario.csv.gz` tampoco está incluido, porque supera el límite web; lo sustituyen para compartir los siete CSV anuales.

## 6. Cómo ejecutar o abrir los datos en RStudio

En tu equipo puedes usar directamente la carpeta local de trabajo indicada en el apartado 2. En otro equipo, descarga el repositorio publicado o extrae el paquete completo y abre **`MA2003B_Blank.Rproj`**.

**Para leer la base que ya está preparada**, basta con ejecutar esto en la consola de RStudio, desde el proyecto:

```r
source("scripts/03_leer_base_preparada.R", encoding = "UTF-8")
dim(base_sima)     # Debe dar 830908 filas y 63 columnas.
head(base_sima)
```

Los `.csv.gz` se leen comprimidos; no hace falta abrirlos con Excel ni descomprimirlos uno a uno. `fecha_hora` queda como texto para no atribuirle una zona horaria que aún no se ha documentado.

**Para repetir la limpieza desde los originales**, ejecuta estos bloques en orden:

```r
# Bloque 1: restaurar las dependencias de esta preparación.
renv::restore(packages = c("readxl", "data.table", "digest", "jsonlite", "renv"))
```

```r
# Bloque 2: leer los siete Excel y generar la base y las auditorías.
source("scripts/01_preparar_datos.R", encoding = "UTF-8")
```

```r
# Bloque 3: comprobar la consistencia del resultado.
source("tests/verificar_preparacion.R", encoding = "UTF-8")
```

```r
# Bloque 4: generar el borrador con los resultados obtenidos.
source("scripts/02_generar_informe.R", encoding = "UTF-8")
```

No uses `renv::init()` porque el proyecto ya está inicializado. `renv::restore()` sin especificar paquetes restaura el entorno completo de la plantilla; puede instalar dependencias que esta preparación no utiliza. Se probó la limpieza con R 4.6.1, pero no se ejecutó el Quarto previo del equipo.

El bloque 4 vuelve a escribir el borrador Markdown. Si lo has editado a mano, conserva esa versión en el documento del equipo o en otro archivo antes de regenerarlo.

## 7. Qué copiar al informe del equipo y exactamente dónde

Abre `reports/secciones_2_3_4.md`. Es texto Markdown: los símbolos `#` y los acentos invertidos marcan formato y no tienen que copiarse literalmente a Word.

| Lugar del informe conjunto | Texto que debes integrar |
|---|---|
| **Parte 2 → después de la sección 1, Comprensión de los datos** | El apartado **2. Preparación de los datos** del borrador |
| **A continuación, Parte 2 → sección 3** | El apartado **3. Transformación** |
| **A continuación, Parte 2 → sección 4** | El apartado **4. Reformateo y reestructuración** |
| **En la sección 4 o en el lugar que indique la rúbrica** | El enlace comprobado al repositorio y a `data/processed/` de la rama publicada |
| **En la declaración de IA del equipo o al final de la Parte 2, según la rúbrica** | La declaratoria de uso de IA, ajustada a lo que el equipo realmente haya revisado |

No pegues todos los scripts ni las tablas completas en el cuerpo del informe. Van en el repositorio como respaldo. Tu texto tiene que dejar espacio a la sección 1 del compañero, porque el límite de 3–4 páginas es para toda la Parte 2, no sólo para tus secciones.

El párrafo inicial que dice que es un borrador y que faltan decisiones es una nota de trabajo. Cuando se resuelvan esas decisiones, actualiza el texto para describir lo que sí se hizo. Mientras sigan pendientes, no elimines la limitación para aparentar que el trabajo está cerrado.

## 8. Las cifras que respaldan tu explicación

| Resultado | Cómo interpretarlo | Dónde comprobarlo |
|---|---|---|
| 830 908 registros | Filas de estación y hora conservadas | `registros_por_anio.csv`, `resumen.json` |
| 0 duplicados eliminados; 0 % | No se repitió la clave fecha + estación tras reconstruir las fechas | `claves_repetidas.csv`, `duplicados_eliminados.csv` |
| 4 fechas reconstruidas | Se completó la fecha, no las mediciones, por la continuidad de las filas vecinas | `fechas_reconstruidas.csv` |
| 322 lecturas a NA; 0.0026 % | Porcentaje sobre 12 463 620 celdas originales de medición; reglas provisionales documentadas | `correcciones_celdas.csv` |
| 11.26 % de faltantes | Porcentaje de celdas de medición tras esas correcciones | `faltantes_por_variable.csv`, `resumen.json` |
| O3: 113 198 faltantes; 13.62 % | Porcentaje sobre las 830 908 filas existentes | `faltantes_por_variable.csv` |
| 144 656 celdas candidatas a atípicas; 1.53 % | Porcentaje sobre 9 439 534 celdas evaluables por la regla 3·RIC | `atipicos_por_variable.csv`, `limites_atipicos_descriptivos.csv` |
| 97 282 filas con alguna alerta; 11.71 % | Una fila puede contener varios candidatos; no son necesariamente errores | `resumen.json` |
| 187 horas sin fila dentro de intervalos observados | Huecos de calendario, distintos de celdas NA | `horas_sin_fila_interiores.csv` |
| 0 mediciones imputadas; 0 % | La imputación todavía no se ha aplicado | `imputacion.csv` |
| 0 filas eliminadas; 0 % | Las correcciones afectaron celdas, no borraron registros completos | `resumen.json` |

Todos los nombres de esta tabla se encuentran dentro de `reports/auditoria/`. Los porcentajes no tienen siempre el mismo denominador: no sumes 11.26 % de celdas faltantes con 11.71 % de filas con alertas.

## 9. Qué falta decidir sobre la imputación

El artículo recomendado, [Fang y Wang (2020)](https://arxiv.org/abs/2011.11347), revisa métodos. No demuestra que uno de ellos sea el mejor para SIMA. Una comparación razonable para comenzar es último valor observado limitado a huecos cortos frente a medianas por estación y hora calculadas con entrenamiento; todavía no se han evaluado ni aplicado esas alternativas.

El trabajo pendiente es concreto:

1. Obtener el diccionario de unidades y los rangos SIMA por año. Revisar las 322 correcciones y los candidatos con esa documentación; no tratarlos como errores de sensor confirmados sin comprobarlo.
2. Definir con el equipo los periodos de entrenamiento, validación y prueba. Los valores futuros no deben influir en la preparación que simula una predicción pasada.
3. Medir la duración de los huecos por variable y estación. No aplicar el mismo relleno a un hueco de una hora y a varios meses sin sensor.
4. Ocultar bloques de mediciones que sí se conocen, comparar los métodos y medir su error por variable y tamaño de hueco. Los métodos se ajustan con entrenamiento y se comparan en validación; la prueba final queda reservada.
5. Aplicar el método elegido a las predictoras admisibles, conservar el original y añadir banderas de imputación. Registrar cuántas celdas se rellenaron por método, cuántas siguen vacías y el denominador de cada porcentaje.
6. Mantener las respuestas de evaluación de O3 como observaciones reales. Si falta O3 en la hora que se quiere predecir, esa fila no sirve para medir el error del pronóstico, aunque pueda permanecer en la base general.
7. Actualizar los scripts, la base, `imputacion.csv`, el informe y, si hay nuevas dependencias, `renv.lock`. Sólo entonces se puede escribir que se realizó y evaluó la imputación.

Se puede empezar a comparar imputadores de predictoras antes de fijar el horizonte exacto. El horizonte sí hace falta para construir la etiqueta O3(t+h) y cerrar la validación del modelo predictivo. La etiqueta debe unirse por estación y hora exacta, no desplazando filas, porque hay horas ausentes.

## 10. Cómo cerrar la publicación y la entrega

Tras la subida web, abre la rama publicada y verifica que aparecen los siete CSV dentro de `data/processed/`, el README, los scripts y las auditorías. Abre al menos un CSV pequeño de auditoría y comprueba sus cifras. GitHub puede ofrecer descargar los `.csv.gz` en lugar de previsualizarlos; eso no significa que estén dañados.

Si usaste la rama sugerida, la dirección de la carpeta será:

```text
https://github.com/a01236941/Reto-Multi-Equipo4/tree/preparacion-sima-manual/data/processed
```

Después de integrarla en `trunk`, será:

```text
https://github.com/a01236941/Reto-Multi-Equipo4/tree/trunk/data/processed
```

Son direcciones previstas. **No se presentan como publicadas hasta comprobarlas.** Usa en el informe el enlace que realmente abra tus archivos. Actualiza también `reports/estado_publicacion.md`; por ahora dice correctamente que no se ha publicado.

Antes de entregar, asegúrate de que el informe, los scripts y la base describen la misma versión. Si todavía no hubo imputación o revisión con los rangos oficiales, dilo. No cambies únicamente la redacción para afirmar que esas tareas ya se hicieron.
