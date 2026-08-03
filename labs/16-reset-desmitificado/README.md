# Lab 16 — Reset desmitificado

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/16-reset-desmitificado/README.md).

## Objetivo

Practicar los tres modos de `git reset` (`--soft`, `--mixed` y `--hard`)
sobre un proyecto real de backup en Bash, observando como cada modo
manipula los tres arboles de Git (HEAD, indice y directorio de trabajo).
Termina con un squash de dos commits usando `reset --soft`. Todo ocurre
sobre una rama local, sin remotos: como dice la clase, no se reescribe
historia publicada.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado en la
rama `main` y la historia de un script de backup en Bash (`backup.sh`, su
configuracion `backup.conf` y el `README.md`). El codigo importa solo como
contexto: lo que practicas aca es `reset`, no programar.

La historia inicial se ve asi (los mensajes son la pista para ubicarte en
cada step):

```bash
git log --oneline
```

```text
<HEAD>  Agrega compresion al backup
        Agrega configuracion de backup
<raiz>  Agrega script de backup
```

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

Antes de empezar, explora los tres arboles de Git para tener presente el
punto de partida:

```bash
git ls-tree -r HEAD      # arbol HEAD: la ultima instantanea confirmada
git ls-files -s          # indice: la proxima instantanea propuesta
ls -R                    # directorio de trabajo: los archivos en disco
```

Como el repositorio esta limpio, los tres arboles muestran lo mismo. En
cada step vas a ejecutar un `reset` y a volver a mirar estos tres comandos
para ver cual arbol se movio y cual quedo intacto.

## Steps

El verificador es **acumulativo**: `./verify.sh N` corre los checks
aplicables hasta el step N. `./verify.sh` sin argumentos corre todos los
steps.

### Step 1 — `--soft`: rehacer el ultimo commit

El ultimo commit (`Agrega compresion al backup`) quedo incompleto:
modifico `backup.sh` para comprimir con gzip, pero olvido actualizar el
`README.md`. Vamos a deshacerlo y rehacerlo bien.

Deshaz el ultimo commit con `--soft`:

```bash
git reset --soft HEAD^
```

Observa que paso con los tres arboles:

```bash
git log --oneline            # HEAD: ahora hay solo 2 commits
git status                   # indice: los cambios siguen preparados (staged)
git diff                     # directorio de trabajo: sin cambios
```

`--soft` solo movio HEAD: el indice quedo intacto (los cambios de la
compresion siguen preparados) y el directorio de trabajo no se toco.

Ahora completa el README. Con tu editor, abre `README.md`, busca en la
seccion `## Uso` la linea `El backup se genera con tar.` y cambiala por:

```text
El backup se genera con tar y compresion gzip.
```

Guarda, prepara el README y rehaz el commit:

```bash
git add README.md
git commit -m "Agrega compresion al backup"
```

Al terminar hay 3 commits de nuevo, pero el ultimo ya incluye el README
actualizado. `--soft` es equivalente a deshacer el commit y dejar todo
preparado para volver a confirmar, sin perder nada del camino.

### Step 2 — `--mixed`: deshacer un commit y el add

Ahora quieres sumar una alerta por email al backup. El archivo de
configuracion deja una pista: con tu editor, abre `backup.conf` y busca el
comentario `# TODO (step 2)`. Descomenta la linea que sugiere
(`ALERTA_EMAIL="admin@example.com"`), guarda y confirma:

```bash
git add backup.conf
git commit -m "Agrega alertas por email"
```

Despues de confirmar te das cuenta de que querias armarlo de otra forma.
Deshaz el commit con `--mixed` (es el comportamiento por defecto, asi que
puedes escribir `git reset` a secas):

```bash
git reset HEAD^
```

Observa la diferencia con el step 1:

```bash
git status                   # indice: ya NO hay nada preparado
git diff --cached            # indice: vacio
git diff                     # directorio de trabajo: el cambio sigue ahi
```

A diferencia de `--soft`, `--mixed` ademas actualizo el indice: el cambio
quedo en el directorio de trabajo, sin preparar. Es como retroceder a antes
de ejecutar `git add` y `git commit`.

Vuelve a armar el commit:

```bash
git add backup.conf
git commit -m "Agrega alertas por email"
```

### Step 3 — `--hard`: descartar trabajo sin confirmar

Imagina que haces cambios a medio terminar: con tu editor, abre
`backup.sh` y agrega al final una linea de prueba cualquiera (por ejemplo
`echo "WIP"`), y en `backup.conf` cambia el valor de `DESTINO` por una ruta
inventada. Prepara uno de los dos archivos para dejar una parte en el
indice:

```bash
git add backup.conf
git status                   # hay cambios preparados y sin preparar
```

Era todo ruido: quieres descartarlo TODO, lo preparado y lo que no.
Apuntando a HEAD con `--hard`:

```bash
git reset --hard HEAD
```

`--hard` completa las tres operaciones: mueve HEAD, actualiza el indice y
**sobrescribe el directorio de trabajo**. Verifica que el repo quedo limpio
y que los commits siguen a salvo:

```bash
git status                   # limpio, sin cambios pendientes
git log --oneline            # siguen habiendo 4 commits
```

> `--hard` es la unica forma peligrosa de `reset`: los cambios descartados
> no tienen recuperacion facil. Solo el trabajo sin confirmar se perdio; el
> trabajo committeado sigue a salvo.

### Step 4 — Squash con `reset --soft`

Los dos ultimos commits (`Agrega compresion al backup` y `Agrega alertas
por email`) son en realidad un solo cambio: las mejoras del backup. Vamos a
fusionarlos en uno con la tecnica de squash que viste en la clase.

Mueve HEAD dos commits atras con `--soft`; el indice queda intacto, con el
trabajo de ambos commits preparado:

```bash
git reset --soft HEAD~2
git status                   # ambos cambios quedan preparados (staged)
```

Y confirma una sola vez para agruparlos:

```bash
git commit -m "Mejora el backup con compresion y alertas"
```

Verifica el resultado:

```bash
git log --oneline
```

```text
<HEAD>  Mejora el backup con compresion y alertas
        Agrega configuracion de backup
<raiz>  Agrega script de backup
```

La historia quedo con 3 commits: los dos de mejoras quedaron fusionados en
uno. El contenido total del proyecto no cambio — solo la historia.

## Verificar tu progreso

```bash
./verify.sh        # corre todos los steps
./verify.sh N        # corre los steps aplicables hasta el step N
```

Si algun check falla, el script te dice exactamente que falta.
