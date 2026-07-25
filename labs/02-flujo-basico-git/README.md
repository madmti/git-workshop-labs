# Lab 02 — Flujo básico: init, add, commit

## Objetivo

Practicar el ciclo `init -> add -> commit` sobre un proyecto real (una
calculadora en Python), incluyendo modificar código ya existente, ignorar
archivos, eliminar código muerto y renombrar un archivo.

No necesitas saber Python para este ejercicio: el único cambio de código
que vas a hacer es completar una línea en una función que ya existe.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `calculadora/` con el proyecto semilla. **No** ejecuta
`git init` por ti — eso es parte del ejercicio.

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks desde el
step 1 hasta el N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Inicializar el repositorio

```bash
cd calculadora
git init
```

### Step 2 — Commit inicial

Agrega y confirma todos los archivos del proyecto semilla:

```bash
git add .
git commit -m "commit inicial"
```

### Step 3 — Completar `potencia()`

Abre `operaciones.py` y busca la función `potencia()`. Está incompleta:
siempre retorna `0`. Complétala para que retorne `base` elevado a
`exponente` (en Python, el operador de potencia es `**`).

Cuando funcione, prepara y confirma el cambio:

```bash
git add operaciones.py
git commit -m "completar potencia()"
```

### Step 4 — Ignorar `__pycache__/`

Corre el programa una vez para que Python genere su carpeta de cache:

```bash
python3 main.py
```

Vas a notar que aparece una carpeta `__pycache__/`. Esto no debería
subirse nunca a un repositorio. Agrégala a un archivo `.gitignore` y
confirma ese archivo:

```bash
echo "__pycache__/" >> .gitignore
git add .gitignore
git commit -m "ignorar __pycache__"
```

### Step 5 — Eliminar código legacy

El archivo `operaciones_legacy.py` es una versión vieja que ya nadie usa.
Elimínalo usando Git (no lo borres a mano) y confirma:

```bash
git rm operaciones_legacy.py
git commit -m "eliminar codigo legacy"
```

### Step 6 — Renombrar `utils.py`

El nombre `utils.py` es muy genérico. Renómbralo a `helpers.py` usando
Git y confirma:

```bash
git mv utils.py helpers.py
git commit -m "renombrar utils a helpers"
```

## Verificar tu progreso

```bash
cd ..
./verify.sh        # corre todos los steps
./verify.sh 3       # corre los steps 1, 2 y 3
```

Si algún check falla, el script te dice exactamente qué falta.
