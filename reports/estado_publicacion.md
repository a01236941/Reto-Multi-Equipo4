# Estado de publicación

La aportación está preparada en la rama local `preparacion-sima`. **No está publicada en GitHub.** El 30 de septiembre de 2026 se comprobó el acceso mediante `git push --dry-run`, y Git no pudo obtener una credencial en modo no interactivo. No se modificó ninguna rama remota.

La base para compartir está en los siete archivos `data/processed/sima_horario_AAAA.csv.gz` y el informe en `reports/secciones_2_3_4.md`. La copia consolidada `sima_horario.csv.gz` permanece local, fuera de Git. La guía completa para publicación manual está en `GUIA_PASO_A_PASO.md`.

Para publicarla, iniciar sesión en Git desde este equipo con una cuenta que tenga permisos de escritura en el repositorio del equipo. Después, desde la carpeta del proyecto:

```bash
git push -u origin preparacion-sima
```

Cuando el comando termine correctamente, revisar la rama en GitHub y abrir una solicitud de integración hacia `trunk`. El enlace de la base en esa rama será:

`https://github.com/a01236941/Reto-Multi-Equipo4/tree/preparacion-sima/data/processed`

Ese enlace no se presenta como disponible hasta que la publicación haya ocurrido. No compartir contraseñas ni tokens en el chat o en el repositorio.

Si la subida se hace desde la web con la rama sugerida `preparacion-sima-manual`, usar esa rama en el enlace. Después de integrar los cambios en `trunk`, actualizar el enlace y este estado para reflejarlo.
