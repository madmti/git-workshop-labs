# Lab 03 — Deshacer, Alias y Remotos

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/03-deshacer-alias-remotos/README.md).

## Objetivo

Practicar cómo deshacer cambios (`restore`, `commit --amend`), configurar
alias locales, y colaborar con un remoto (`fetch`, `merge`/`pull`, `push`)
sobre el mismo proyecto de la calculadora, ahora con historia real.

## Antes de empezar

```bash
./init.sh
```

Esto crea dos carpetas:

- `calculadora/`: tu repositorio local, ya inicializado y con varios
  commits de historia.
- `remoto-calculadora.git/`: un repositorio remoto simulado en disco. **Ya tiene un commit que tu copia local no tiene**, como si un compañero de equipo hubiera subido un cambio antes que tú.

Todo esto ocurre dentro de `calculadora/`, así que entra ahí para
trabajar:

```bash
cd calculadora
```

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks desde el
step 1 hasta el N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Alias locales

Configura, a nivel de repositorio (`--local`), los alias que vas a usar
durante el resto del ejercicio:

```bash
git config --local alias.st status
git config --local alias.ci commit
git config --local alias.last "log -1 HEAD"
git config --local alias.unstage "restore --staged"
git config --local alias.lg "log --oneline --graph --all --decorate"
```

De aquí en adelante puedes usar `git st` en vez de `git status`, `git ci`
en vez de `git commit`, etc.

### Step 2 — Traer los cambios del remoto

Conecta tu repositorio local con el remoto:

```bash
git remote add origin ../remoto-calculadora.git
```

Ahora trae el commit que tu compañero ya subió. Puedes hacerlo en dos
pasos (recomendado para ver la diferencia entre descargar e integrar):

```bash
git fetch origin
git merge origin/main
```

O en un solo paso:

```bash
git pull origin main
```

Cualquiera de las dos formas es válida, mientras el commit termine
integrado en tu rama local.

### Step 3 — Deshacer un archivo preparado

Edita `README.md` (el del proyecto, dentro de `calculadora/`) y agrégale
una línea cualquiera. Prepáralo con `git add`, como si fueras a
confirmarlo:

```bash
git add README.md
```

Antes de confirmar, te das cuenta de que ese cambio no está listo
todavía. Sácalo del área de preparación (usando tu alias del step 1):

```bash
git unstage README.md
```

El archivo debe quedar modificado en tu directorio de trabajo, pero ya
no preparado.

### Step 4 — Deshacer cambios de un archivo modificado

Sigue pensando en ese mismo cambio de `README.md`. En realidad, ni
siquiera quieres mantenerlo — descártalo por completo y vuelve el
archivo a como estaba en el último commit:

```bash
git restore README.md
```

> **Recuerda:** `git restore <archivo>` es destructivo. El cambio que
> hiciste desaparece por completo.

### Step 5 — Enmendar el último commit

Abre `operaciones.py` y busca el comentario `# TODO (step 5)` al final
del archivo. Completa la función `raiz_cuadrada(x)` tal como indica la
pista. Prepárala y confírmala:

```bash
git add operaciones.py
git ci -m "agregar raiz_cuadrada"
```

Pero olvidaste conectar esta nueva función al menú del CLI. Abre
`main.py`: hay dos comentarios `# TODO (step 5)`, uno junto al import y
otro dentro del diccionario `OPCIONES`. Completa ambos siguiendo el
ejemplo que dejan comentado. En vez de crear un commit nuevo, enmienda
el anterior:

```bash
git add main.py
git commit --amend --no-edit
```

Verifica con tu alias que quedó todo en un solo commit:

```bash
git last
```

### Step 6 — Subir tus cambios al remoto

Como ya trajiste el commit del step 2 antes de crear los tuyos, tu
historial local está simplemente adelantado al del remoto — sin
divergencias. Confirma esto y sube tus cambios:

```bash
git push origin main
```

## Verificar tu progreso

Desde la carpeta del lab (no desde `calculadora/`):

```bash
./verify.sh        # corre todos los steps
./verify.sh 4       # corre los steps 1, 2, 3 y 4
```

Si algún check falla, el script te dice exactamente qué falta.
