# Lab 10 — Rebase en acción

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/10-rebase-onto/README.md).

## Objetivo

Practicar la reorganización (`git rebase`) sobre un grafo **ya armado**, tal
como en los ejemplos de la clase: primero un rebase básico de una rama
divergente sobre `master` con su fast-forward y limpieza, y después el caso
más interesante con `git rebase --onto` y las ramas `server` y `client`.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado y el
grafo completo pre-armado: la rama `experiment` ya viene **divergida** de
`master`, y también existen las ramas `server` y `client` (que vas a usar más
adelante). No tienes que crear commits ni ramas: el foco del lab es
rebasear, fusionar y borrar ramas.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks aplicables
hasta el step N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Configura el visor de grafo y observa el estado inicial

Configura el alias `git lg`, que vas a usar en cada paso para ver el grafo de
las ramas que se están trabajando:

```bash
git config --local alias.lg "log --oneline --graph --decorate"
git lg master experiment
```

Vas a ver el fork: `experiment` tiene un commit propio que `master` no tiene.
Es exactamente la situación de la clase antes de rebasear.

### Step 2 — Rebase básico de `experiment`

Salta a `experiment` y reorganiza su commit encima de `master`:

```bash
git checkout experiment
git rebase master
```

Git va a decir algo así (los shas cambian en tu repo):

```
First, rewinding head to replay your work on top of it...
Applying: ...
```

Mira el grafo de nuevo, con las mismas dos ramas:

```bash
git lg master experiment
```

El fork desapareció: `experiment` quedó reaplicada en serie encima de
`master`, como si el trabajo se hubiera hecho uno después del otro.

### Step 3 — Fast-forward de `master` y limpieza

Vuelve a `master` y fusiona `experiment`. Como ahora es descendiente directa,
el merge es un **fast-forward** (Git no crea ningún commit nuevo):

```bash
git checkout master
git merge experiment
```

Ya no necesitas `experiment`, bórrala:

```bash
git branch -d experiment
```

Mira el grafo de `master`:

```bash
git lg master
```

Todo quedó en una sola línea: el rebase + fast-forward dejó la historia
limpia, sin commit de fusión.

### Step 4 — El caso interesante: `git rebase --onto`

Ahora aparecen en juego las ramas `server` y `client` que estaban preparadas.
Mira el grafo de las tres ramas juntas:

```bash
git lg master server client
```

Vas a ver la cadena original: `client` sobre `server`, y `server` sobre el
mismo commit del que salió `master`. Quieres integrar `client` en `master`
**sin** arrastrar los cambios de `server` (todavía no están listos). Para eso
usa `git rebase --onto`:

```bash
git rebase --onto master server client
```

Esto significa: _toma `client`, averigua los cambios desde que divergió de
`server`, y aplícalos sobre `master`_. Mira el grafo de nuevo:

```bash
git lg master server client
```

`client` quedó encima de `master`, y `server` quedó sola en su propia línea:
sus commits **no** fueron arrastrados.

### Step 5 — Fast-forward de `master` con `client`

Integra `client` en `master`:

```bash
git checkout master
git merge client
```

Mira el grafo de las tres ramas:

```bash
git lg master server client
```

`master` y `client` están en la misma punta. `server` sigue esperando abajo,
con su trabajo todavía sin integrar.

### Step 6 — Rebase de `server` y cierre

Cuando `server` esté lista, puedes reorganizarla sobre `master` sin tener que
hacer checkout antes:

```bash
git rebase master server
```

Integra y limpia todo:

```bash
git checkout master
git merge server
git branch -d client
git branch -d server
```

Y el cierre del lab: mira el grafo completo con `git lg --all` (todas las
ramas):

```bash
git lg --all
```

La historia quedó **lineal**: 6 commits en serie, sin ramas ni merges.
Exactamente el resultado que buscaba el rebase.

## Verificar tu progreso

Desde la carpeta del lab (no desde `proyecto/`):

```bash
./verify.sh        # corre todos los steps
./verify.sh N      # corre los steps aplicables hasta el step N
```

Si algún check falla, el script te dice exactamente qué falta.
