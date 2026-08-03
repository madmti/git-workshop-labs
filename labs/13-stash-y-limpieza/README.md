# Lab 13 — Stash y limpieza

> ¿Prefieres leerlo en el navegador? Este mismo README esta en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/13-stash-y-limpieza/README.md).

## Objetivo

Practicar el ciclo de vida del guardado rapido (`git stash`) para no perder trabajo a
medias y la limpieza del directorio de trabajo con `git clean`. Vas a guardar cambios sin
confirmar, limpiar los archivos que no estan bajo seguimiento (untracked e ignorados) y
recuperar el trabajo guardado al final, cerrando el ciclo sin dejar cabos sueltos.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado y un proyecto real:
un compilador de paginas en Python (`compiler.py`) que lee los textos de `src/` y genera
paginas en `build/`. La carpeta `build/` y los archivos `*.tmp` estan ignorados por
`.gitignore`.

A proposito, `init.sh` te deja el directorio de trabajo **sucio**, como si estuvieras a
mitad de un cambio:

- `compiler.py` modificado y preparado (staged): agrega un sitemap al compilador.
- `src/guia.txt` modificado sin preparar (unstaged): cambia el titulo.
- Basura sin seguimiento: `debug.log`, `notas.txt` y la carpeta `tmp/`.
- Artefactos ignorados: `build/` y `cache.tmp`.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks aplicables hasta el step
N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Guarda el trabajo a medias

Mira el estado en el que te dejo `init.sh`:

```bash
git status -s
```

Vas a ver algo como:

```
M  compiler.py
 M src/guia.txt
?? debug.log
?? notas.txt
?? tmp/
```

Estas a mitad de un cambio y necesitas hacer otra cosa sin confirmar. Guarda todo el
trabajo de los archivos con seguimiento en un stash:

```bash
git stash
```

Vuelve a mirar el estado:

```bash
git status -s
```

Los cambios de `compiler.py` y `src/guia.txt` ya no estan: quedaron guardados. Fijate que
la basura sin seguimiento (`debug.log`, `notas.txt`, `tmp/`) sigue ahi: `git stash` por
defecto solo guarda los archivos que ya estan bajo seguimiento.

### Step 2 — Limpia lo que no esta bajo seguimiento

Antes de borrar nada, mira que es lo que Git eliminaria en modo simulacion:

```bash
git clean -n
```

La opcion `-n` (dry-run) solo te muestra que borraria, sin tocar nada. Cuando estes
seguro, borra de verdad incluyendo subdirectorios: `-d` para que Git tambien limpie
carpetas y `-f` para forzar, porque por seguridad `git clean` no hace nada sin fuerza:

```bash
git clean -f -d
```

Verifica que la basura desaparecio y que los archivos ignorados siguen intactos:

```bash
git status -s
ls build/
ls cache.tmp
```

`build/` y `cache.tmp` siguen ahi: `git clean` sin `-x` no toca los archivos ignorados.

### Step 3 — Limpia tambien los ignorados

Para eliminar tambien los archivos ignorados (los compilados y el cache), agrega `-x`:

```bash
git clean -n -d -x
```

```bash
git clean -f -d -x
```

Ahora `build/` y `cache.tmp` tampoco existen. Tu directorio quedo limpio de basura, pero
tu trabajo a medias sigue guardado en el stash.

### Step 4 — Recupera el trabajo guardado

Mira que el stash sigue ahi (los pasos de limpieza no lo tocan):

```bash
git stash list
```

Deberias ver una entrada `stash@{0}`. Recuperala:

```bash
git stash apply
```

Los cambios de `compiler.py` y `src/guia.txt` volvieron a tu directorio de trabajo.
Vuelve a mirar la lista:

```bash
git stash list
```

El stash sigue existiendo: `git stash apply` recupera los cambios pero **no** elimina el
stash de la lista. Eliminarlo es un paso aparte (lo haces en el siguiente).

### Step 5 — Cierra el ciclo

Ya recuperaste el trabajo, asi que el stash no te hace falta. Eliminalo:

```bash
git stash drop
```

Y ahora que el trabajo a medias volvio a tu directorio, confirmalo para no dejar cabos
sueltos (el mensaje del commit es libre):

```bash
git add -A
git commit -m "Agrega sitemap y actualiza el titulo de la guia"
```

Fijate que `git stash apply` volvio a poner los cambios sin restaurar el area de
preparacion: los dos archivos quedaron sin preparar, por eso `git add -A` los toma a los
dos.

## Verificar tu progreso

Desde la carpeta del lab (no desde `proyecto/`):

```bash
./verify.sh        # corre todos los steps
./verify.sh N      # corre los steps aplicables hasta el step N
```

Si algun check falla, el script te dice exactamente que falta.
