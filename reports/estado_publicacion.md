# Estado de publicación

La aportación está preparada en la rama local `preparacion-sima`. **No está publicada en GitHub.** El 30 de septiembre de 2026 se comprobó el acceso mediante `git push --dry-run`, y Git no pudo obtener una credencial en modo no interactivo. No se modificó ninguna rama remota.

La base se encuentra en `data/processed/sima_horario.csv.gz` y el informe en `reports/secciones_2_3_4.md`.

Para publicarla, iniciar sesión en Git desde este equipo con una cuenta que tenga permisos de escritura en el repositorio del equipo. Después, desde la carpeta del proyecto:

```bash
git push -u origin preparacion-sima
```

Cuando el comando termine correctamente, revisar la rama en GitHub y abrir una solicitud de integración hacia `trunk`. El enlace de la base en esa rama será:

`https://github.com/a01236941/Reto-Multi-Equipo4/blob/preparacion-sima/data/processed/sima_horario.csv.gz`

Ese enlace no se presenta como disponible hasta que la publicación haya ocurrido. No compartir contraseñas ni tokens en el chat o en el repositorio.
