# Git Workshop Labs

Ejercicios con repositorios reales para el Taller de Git.

- [Taller de Git (repositorio de clases)](https://github.com/madmti/git-workshop)
- [Taller de Git (sitio web)](https://madmti.github.io/git-workshop/)

## Laboratorios

| # | Laboratorio | Descripcion | Archivo | Instrucciones |
|---|-------------|-------------|---------|---------------|
| 01 | [Configuracion de Git](labs/01-configuracion-git/README.md) | Configuracion a nivel de repositorio con `--local` | [Descargar](dist/01-configuracion-git.tar.gz) | [Ver README](labs/01-configuracion-git/README.md) |
| 02 | [Flujo basico: init, add, commit](labs/02-flujo-basico-git/README.md) | Ciclo completo `init -> add -> commit` sobre un proyecto real | [Descargar](dist/02-flujo-basico-git.tar.gz) | [Ver README](labs/02-flujo-basico-git/README.md) |
| 03 | [Deshacer, Alias y Remotos](labs/03-deshacer-alias-remotos/README.md) | `restore`, `amend`, alias locales y colaboracion con remotos | [Descargar](dist/03-deshacer-alias-remotos.tar.gz) | [Ver README](labs/03-deshacer-alias-remotos/README.md) |
| 04 | [Construir un repo a mano](labs/04-repo-a-mano/README.md) | Fontaneria: blobs, trees y commits a mano sin `add` ni `commit` | [Descargar](dist/04-repo-a-mano.tar.gz) | [Ver README](labs/04-repo-a-mano/README.md) |
| 05 | [Referencias, HEAD y etiquetas](labs/05-referencias-head-tags/README.md) | Ramas y etiquetas como punteros: `update-ref`, `symbolic-ref`, `checkout` a un commit anterior y etiquetas ligeras vs. anotadas | [Descargar](dist/05-referencias-head-tags.tar.gz) | [Ver README](labs/05-referencias-head-tags/README.md) |
| 06 | [Recuperando commits perdidos](labs/06-recuperacion-commits/README.md) | Perder commits a proposito y recuperarlos con `git reflog` y, cuando el reflog fue limpiado, con `git fsck` sobre objetos _dangling_ | [Descargar](dist/06-recuperacion-commits.tar.gz) | [Ver README](labs/06-recuperacion-commits/README.md) |
| 07 | [Ramas y fusiones](labs/07-ramas-y-fusiones/README.md) | Flujo completo de ramificacion y fusion: `checkout -b`, fast-forward, merge commit con 2 padres y borrar ramas ya fusionadas | [Descargar](dist/07-ramas-y-fusiones.tar.gz) | [Ver README](labs/07-ramas-y-fusiones/README.md) |
| 08 | [Resolver conflictos](labs/08-resolver-conflictos/README.md) | Provocar un conflicto real de merge, leer sus marcadores, resolverlo y gestionar las ramas con `--merged`, `--no-merged`, `-d` y `-D` | [Descargar](dist/08-resolver-conflictos.tar.gz) | [Ver README](labs/08-resolver-conflictos/README.md) |
| 09 | [Ramas remotas](labs/09-ramas-remotas/README.md) | Clonar un repo compartido, `fetch` y divergencia, publicar ramas con `push`, ramas de seguimiento, segundo remoto y eliminar ramas remotas | [Descargar](dist/09-ramas-remotas.tar.gz) | [Ver README](labs/09-ramas-remotas/README.md) |
| 10 | [Rebase en accion](labs/10-rebase-onto/README.md) | Reorganizar ramas divergentes con `git rebase`, el escenario `server`/`client` con `git rebase --onto`, fast-forward de la rama principal y limpieza del historial | [Descargar](dist/10-rebase-onto.tar.gz) | [Ver README](labs/10-rebase-onto/README.md) |
| 11 | [Rangos de commits](labs/11-rangos-commits/README.md) | Rangos sobre un repo real: doble punto, `^`/`--not` y triple punto con `--left-right` para identificar commits exactos | [Descargar](dist/11-rangos-commits.tar.gz) | [Ver README](labs/11-rangos-commits/README.md) |

## Quizzes (Kahoot)

| # | Quiz | Preguntas | Temas |
|---|------|-----------|-------|
| 01 | [Introduccion a VCS](https://create.kahoot.it/details/e029edd6-0091-4ad9-a151-59dc39db3a61) | 11 | Conceptos esenciales de Git, estados de archivo, areas del proyecto, integridad de datos, ventajas frente a otros VCS |
| 02 | [Estados y Staging](https://create.kahoot.it/details/5ec7a1ba-6d0e-466b-8eed-594c5091cb41) | 11 | Ciclo de vida de archivos, estados Untracked/Staged/Committed, `.gitignore`, `git status -s`, `git mv`, `git rm`, `-a` en `git commit` |
| 03 | [Fontaneria y el modelo de objetos](https://create.kahoot.it/share/fontaneria-y-el-modelo-de-objetos/e0553081-5424-4d45-a2b9-d0c108542fc5) | 10 | Directorio `.git`, objetos internos de Git: blob, tree y commit |
| 04 | [Packfiles y compresion de objetos](https://create.kahoot.it/share/packfiles-y-compresion-de-objetos/f2306be8-d9d9-4f89-ac4f-213532448e94) | 9 | Como Git almacena y comprime objetos, packfiles y archivos `.idx`, cuando se generan y por que las versiones recientes se guardan completas y las demas como deltas |
| 05 | [Mantenimiento y limpieza del historial](https://create.kahoot.it/share/mantenimiento-y-limpieza-del-historial/b8a0aca1-b5ef-438d-aa57-395a0d621620) | 9 | Mantenimiento del historial en Git: git gc, reflog, objetos huerfanos, git fsck y buenas practicas para mantener repos ligeros y recuperables |
| 06 | [Ramas, HEAD y bifurcación](https://create.kahoot.it/details/76daec96-d53a-42b8-831a-3fd5bbac6aa9) | 9 | Ramas como punteros a commits, HEAD y git checkout, bifurcacion del historial y lectura de git log |
| 07 | [Flujos de trabajo y Ramas Remotas](https://create.kahoot.it/details/67f2cad3-d40e-4598-b450-0a4339e0c6fb) | 10 | Ramas de largo recorrido y puntuales, la metafora de los silos, ramas locales y remotas y el comportamiento de origin al clonar y sincronizar repositorios |
| 08 | [Rebase: conceptos y peligros](https://create.kahoot.it/details/6caf1b34-b01d-4e3e-9cf5-5eabc8c610df) | 9 | Como funciona el rebase por dentro, rebase vs merge, peligros de reorganizar trabajo ya publicado, patch-id, git pull --rebase y cuando conviene rebasear |
| 09 | [Seleccion de revision](https://create.kahoot.it/details/54e056a6-b199-4d3e-b8c1-820517051183) | 10 | Identificacion de commits con SHA-1 corto, git rev-parse, navegacion con HEAD^ y HEAD~, comportamiento de merge commits y funcionamiento del reflog |
