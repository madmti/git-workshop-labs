# Lab 08 — Resolver conflictos

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/08-resolver-conflictos/README.md).

## Objetivo

Forzar un conflicto real de fusión y resolverlo de punta a punta: provocarlo
con `git merge`, leer los marcadores que Git inserta en el archivo, elegir cómo
combinar las versiones, marcar la resolución con `git add` y finalizar la
fusión con `git commit`. De paso gestionas las ramas que quedaron
(`git branch --merged`, `--no-merged`, `-d` vs `-D`).

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con la misma tienda online de un lab
anterior, pero ya con el trabajo en curso de un equipo:

- `main` con el sitio en producción y un ajuste urgente al header.
- `feat/header-v2` con el rediseño del header.
- `exp/colores` con un experimento de colores que quedó a mitad de camino.

Las tres ramas tocaron **la misma regla CSS del header**, así que podrás
provocar un conflicto real sin armar nada. Quedas en `main`, con el working
tree limpio.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks aplicables
hasta el step N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Fusionar `feat/header-v2` y provocar el conflicto

Primero mira qué ramas hay:

```bash
git branch -v
```

Deberías ver `main`, `feat/header-v2` y `exp/colores`, cada una con su último
commit. Ahora fusiona el rediseño del header:

```bash
git merge feat/header-v2
```

Git no puede combinar el trabajo: tanto `main` como `feat/header-v2` cambiaron
las mismas líneas del header. Verás algo así (los shas cambian):

```
Auto-merging css/estilos.css
CONFLICT (content): Merge conflict in css/estilos.css
Automatic merge failed; fix conflicts and then commit the result.
```

### Step 2 — Leer el conflicto

Mira en qué estado quedó la fusión:

```bash
git status
```

Verás `both modified: css/estilos.css` bajo `Unmerged paths`. Git pausó la
fusión: todavía no hay commit nuevo, espera a que la resuelvas.

> [!TIP]
> Si en algún momento te equivocas, puedes abortar todo con
> `git merge --abort` y empezar de nuevo.

Abre `css/estilos.css` y busca la regla del `header h1`. Git insertó los
marcadores de conflicto:

- Lo que está entre `<<<<<<< HEAD` y `=======` es la versión de `main` (la
  rama actual).
- Lo que está entre `=======` y `>>>>>>> feat/header-v2` es la versión de la
  rama que estás fusionando.

### Step 3 — Resolver el conflicto

Borra los marcadores `<<<<<<<`, `=======` y `>>>>>>>` y deja el resultado que
quieras: puedes quedarte con cualquiera de las dos versiones o combinarlas a
mano. Lo único importante es que el archivo quede válido (una sola regla
`header h1`) y sin marcadores de conflicto.

### Step 4 — Marcar resuelto y confirmar la fusión

Avísale a Git que resolviste el archivo:

```bash
git add css/estilos.css
```

Recién ahí confirma la fusión. Pasa el mensaje con `-m` para que Git no abra
el editor:

```bash
git commit -m "Fusiona el rediseño del header"
```

Con esto se crea el **merge commit**: un commit con 2 padres (las dos
historias). Comprueba que quedó:

```bash
git log --oneline --graph
```

### Step 5 — Gestionar ramas

La rama `feat/header-v2` ya quedó fusionada. Bórrala:

```bash
git branch -d feat/header-v2
```

La rama `exp/colores`, en cambio, tiene trabajo que no está fusionado. Git se
niega a borrarla con `-d`:

```bash
git branch -d exp/colores
```

```bash
# error: the branch 'exp/colores' is not fully merged
# hint: If you are sure you want to delete it, run 'git branch -D exp/colores'
```

Como es un experimento que el equipo descartó, puedes forzar el borrado:

```bash
git branch -D exp/colores
```

Verifica que quedó solo `main`:

```bash
git branch
```

## Verificar tu progreso

Desde la carpeta del lab (no desde `proyecto/`):

```bash
./verify.sh        # corre todos los steps
./verify.sh N        # corre los steps aplicables hasta el step N
```

Si algún check falla, el script te dice exactamente qué falta.
