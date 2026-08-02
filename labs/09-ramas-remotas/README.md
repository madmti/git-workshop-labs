# Lab 09 — Ramas remotas

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/09-ramas-remotas/README.md).

## Objetivo

Practicar la colaboración con ramas remotas sobre la tienda online del
equipo: clonar un repositorio compartido, comprobar que `origin/main` solo
se mueve cuando haces `fetch`, integrar el trabajo de una compañera,
publicar una rama nueva con `git push`, configurar ramas de seguimiento
(upstream, `git branch -vv`, `git branch -u`), agregar un segundo remoto y
eliminar ramas remotas.

## Antes de empezar

```bash
./init.sh
```

Esto prepara la simulación dentro de la carpeta del lab:

- `remoto-equipo.git/`: el repositorio compartido del equipo (bare), con la
  tienda online y 4 commits de historia en `main`.
- `remoto-teamone.git/`: un segundo servidor, con el proyecto en su estado
  original.
- `companero/`: la copia de trabajo de tu compañera María, con un commit
  **aún sin subir**.
- `push-companero.sh`: el script que simula que María sube su trabajo.

El lab **no** te crea el repositorio local: lo clonas tú en el step 1.

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks aplicables
hasta el step N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Clonar el repositorio del equipo

Clona el repositorio compartido (el mismo `remoto-equipo.git` que creó
`init.sh`):

```bash
git clone remoto-equipo.git proyecto
```

Al clonar, Git configura automáticamente el remoto `origin`, descarga todo
el historial y crea dos referencias: `origin/main` (el puntero a la rama
remota) y tu rama local `main`, ambas partiendo del mismo commit.

Entra al proyecto y mira las ramas:

```bash
cd proyecto
git branch -a
```

```
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```

### Step 2 — Trabajo local: `origin/main` no se mueve

Abre `index.html` y reemplaza el comentario `<!-- TODO (step 2) -->` por
este aviso:

```html
<p class="novedades">Novedades: abrimos envios a todo el pais.</p>
```

Guarda y confirma:

```bash
git add index.html
git commit -m "Agrega aviso de novedades"
```

Mira el historial:

```bash
git log --oneline --decorate --all
```

Tu rama local `main` avanzó un commit, pero `origin/main` quedó donde
estaba. Las ramas remotas son marcadores: **no se mueven solas**, solo las
mueve Git cuando te comunicas con el servidor.

> [!TIP]
> También lo ves con `git branch -vv`: tu `main` figura
> `[origin/main: ahead 1]`.

### Step 3 — El compañero sube cambios: `fetch` e integración

María trabajó por su cuenta. Simula que ella sube su cambio al servidor.
Vuelve a la carpeta del lab y ejecuta:

```bash
cd ..
./push-companero.sh
cd proyecto
```

Ahora el servidor tiene un commit que tu clon no tiene. Tráelo **sin
fusionarlo todavía**:

```bash
git fetch origin
```

El `fetch` descarga los datos y mueve el puntero `origin/main`, pero **no
toca tu rama local**. Fíjate:

```bash
git status
```

```
On branch main
Your branch and 'origin/main' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" if you want to integrate the remote branch with yours)

nothing to commit, working tree clean
```

Los historiales divergieron: tú tienes el aviso de novedades y el servidor
tiene el `CHANGELOG.md` que subió María. Integra su trabajo:

```bash
git merge origin/main -m "Integra los cambios de Maria"
```

```
Merge made by the 'ort' strategy.
```

Como cada uno tocó archivos distintos (`index.html` y `CHANGELOG.md`), la
fusión es limpia. Es un **merge commit**: un commit con 2 padres.

> [!NOTE]
> `git pull origin main` equivale a `git fetch` + `git merge`, pero la clase
> recomienda hacerlos por separado para ver qué hace cada uno.

### Step 4 — Publicar una rama nueva

El equipo necesita un estilo para el contenido destacado. Crea una rama y
sal a ella:

```bash
git checkout -b serverfix
```

Abre `css/estilos.css` y reemplaza el comentario `/* TODO (step 5) */` por:

```css
.destacado {
  color: #c00;
  font-weight: bold;
}
```

Guarda y confirma:

```bash
git add css/estilos.css
git commit -m "Estilo para contenido destacado"
```

Publica la rama en el servidor:

```bash
git push origin serverfix
```

```
To <carpeta-del-lab>/remoto-equipo.git
 * [new branch]      serverfix -> serverfix
```

Mira las ramas remotas:

```bash
git branch -r
```

```
  origin/HEAD -> origin/main
  origin/main
  origin/serverfix
```

Apareció `origin/serverfix`: el marcador que recuerda cómo está la rama
`serverfix` en el servidor.

### Step 5 — Ramas de seguimiento

Quieres seguir trabajando sobre esa rama remota, pero con un nombre local
más corto. Crea una rama local a partir de `origin/serverfix`:

```bash
git checkout -b sf origin/serverfix
```

```
Switched to a new branch 'sf'
branch 'sf' set up to track 'origin/serverfix'.
```

`sf` quedó asociada a `origin/serverfix`: es una **rama de seguimiento**.
Mira el estado de todas las ramas:

```bash
git branch -vv
```

```
  main       <sha> [origin/main]
  serverfix  <sha>
* sf         <sha> [origin/serverfix]
```

Fíjate la diferencia: `serverfix` no sigue ninguna rama remota, `sf` sí.

Abre `README.md` y reemplaza la línea `> TODO (step 6)` por:

```markdown
> La rama de seguimiento `sf` apunta a `origin/serverfix`.
```

Guarda y confirma:

```bash
git add README.md
git commit -m "Documenta la rama de seguimiento"
```

```bash
git branch -vv
```

```
* sf  <sha> [origin/serverfix: ahead 1]
```

Como `sf` sigue a `origin/serverfix`, `git status` y `git branch -vv` te
muestran cuántos commits te faltan o te sobran. Para subir, dale a Git la
relación explícita entre tu rama local y la rama del servidor:

```bash
git push origin HEAD:serverfix
```

```
To <carpeta-del-lab>/remoto-equipo.git
   <sha>..<sha>  HEAD -> serverfix
```

`HEAD:serverfix` significa: "envía la rama en la que estoy ahora
(`sf`) hacia la rama `serverfix` del remoto". No hace falta escribirlo a
mano: Git te sugiere exactamente este comando si intentas un `git push`
directo y el nombre de tu rama local (`sf`) no coincide con el de la
remota (`serverfix`).

Ahora asocia una rama local **existente** a un remoto con `-u`. Vuelve a
`main` y crea `otra` (sin seguimiento):

```bash
git checkout main
git checkout -b otra
git branch -vv
```

`otra` no figura con `[...]`: no sigue ninguna rama remota. Asóciala a
`origin/serverfix`:

```bash
git branch -u origin/serverfix
git branch -vv
```

```
* otra  <sha> [origin/serverfix: behind 2]
```

### Step 6 — Segundo remoto

El equipo de sprint mantiene su propio servidor. Agrégalo como remoto:

```bash
git remote add teamone ../remoto-teamone.git
```

Trae lo que ese servidor tiene y tú no:

```bash
git fetch teamone
```

```
From ../remoto-teamone
 * [new branch]      main       -> teamone/main
```

`teamone/main` apareció apuntando al **estado original** del proyecto (el
mismo commit con el que arrancó el lab, antes de los cambios de hoy). Como
ese servidor contiene un subconjunto de lo que ya tiene `origin`, Git **no
descargó ningún dato**: solo creó el marcador.

Mira todas las ramas remotas de ambos servidores:

```bash
git branch -r
```

```
  origin/HEAD -> origin/main
  origin/main
  origin/serverfix
  teamone/HEAD -> teamone/main
  teamone/main
```

### Step 7 — Eliminar ramas remotas

La rama `serverfix` ya cumplió su función en el servidor. Vuelve a `main` y
bórrala:

```bash
git checkout main
git push origin --delete serverfix
```

```
To <carpeta-del-lab>/remoto-equipo.git
 - [deleted]         serverfix
```

`origin/serverfix` ya no existe. Tus ramas locales `serverfix` y `sf`
quedan como están: solo se borró el puntero del servidor.

## Verificar tu progreso

Desde la carpeta del lab (no desde `proyecto/`):

```bash
./verify.sh        # corre todos los steps
./verify.sh 5      # corre los steps aplicables hasta el step 5
```

Si algún check falla, el script te dice exactamente qué falta.
