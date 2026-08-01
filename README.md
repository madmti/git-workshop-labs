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

## Quizzes (Kahoot)

| # | Quiz | Preguntas | Temas |
|---|------|-----------|-------|
| 01 | [Introduccion a VCS](https://create.kahoot.it/details/e029edd6-0091-4ad9-a151-59dc39db3a61) | 11 | Conceptos esenciales de Git, estados de archivo, areas del proyecto, integridad de datos, ventajas frente a otros VCS |
| 02 | [Estados y Staging](https://create.kahoot.it/details/5ec7a1ba-6d0e-466b-8eed-594c5091cb41) | 11 | Ciclo de vida de archivos, estados Untracked/Staged/Committed, `.gitignore`, `git status -s`, `git mv`, `git rm`, `-a` en `git commit` |
| 03 | [Fontaneria y el modelo de objetos](https://create.kahoot.it/share/fontaneria-y-el-modelo-de-objetos/e0553081-5424-4d45-a2b9-d0c108542fc5) | 10 | Directorio `.git`, objetos internos de Git: blob, tree y commit |
| 04 | [Packfiles y compresion de objetos](https://create.kahoot.it/share/packfiles-y-compresion-de-objetos/f2306be8-d9d9-4f89-ac4f-213532448e94) | 9 | Como Git almacena y comprime objetos, packfiles y archivos `.idx`, cuando se generan y por que las versiones recientes se guardan completas y las demas como deltas |
| 05 | [Mantenimiento y limpieza del historial](https://create.kahoot.it/share/mantenimiento-y-limpieza-del-historial/b8a0aca1-b5ef-438d-aa57-395a0d621620) | 9 | Mantenimiento del historial en Git: git gc, reflog, objetos huerfanos, git fsck y buenas practicas para mantener repos ligeros y recuperables |
