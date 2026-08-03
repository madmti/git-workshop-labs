# Lab 12 — Organización interactiva

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/12-organizacion-interactiva/README.md).

## Objetivo

Practicar el staging interactivo sobre un repo real: preparar archivos enteros
con el menú de `git add -i`, preparar **partes** de archivos con `git add -p` y
dividir bloques de cambios con `s`, para armar dos commits parciales enfocados
en lugar de uno grande.

## Antes de empezar

```bash
./init.sh
```

Crea la carpeta `proyecto/` con un repositorio ya inicializado (rama `master`)
y un proyecto Prisma de ejemplo: `prisma/schema.prisma` y dos migraciones SQL.
El commit base ya está hecho, pero `init.sh` deja el working tree **sucio a
propósito**: hay cambios sin confirmar en dos archivos.

> No edites ningún archivo: este lab es 100% sobre preparar y commitear.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

## Steps

El verificador es **acumulativo**: `./verify.sh N` corre los checks aplicables
hasta el step N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — `git add -i`: organizar y desorganizar

Entra al modo interactivo:

```bash
git add -i
```

Dentro del menú:

1. `update` (tecla `2` o `u`): selecciona **ambos** archivos modificados
   (escribe `1,2` y Enter) para prepararlos.
2. `diff` (tecla `6` o `d`): elige un archivo y revisa su diff para ver qué
   quedó preparado, y vuelve al menú.
3. `revert` (tecla `3` o `r`): desprepara **solo** `prisma/schema.prisma`.
4. `quit` (tecla `7` o `q`): sal.

Estado esperado: `migration.sql` preparado y `schema.prisma` sin preparar.

> Pista: para confirmar la acción en `update` y `revert`, presiona **Enter
> con una entrada vacía** al final. El `*` antes de un archivo indica que
> está seleccionado.

### Step 2 — `git add -p`: un hunk sí, otro no

En `schema.prisma` hay dos bloques de cambios separados: los de `User` (que
vamos a dividir recién en el step 3) y el de `Task` (el campo `status`).
Prepara solo el de `Task`:

```bash
git add -p prisma/schema.prisma
```

- Primer bloque (cambios en `User`): teclea `n` (no preparar).
- Segundo bloque (campo `status` de `Task`): teclea `y` (preparar).

> Si te pierdes entre bloques, `?` dentro del prompt muestra todas las teclas
> disponibles.

### Step 3 — `git add -p` + `s`: dividir un hunk

El bloque de `User` junta dos cambios independientes: el `@db.VarChar(255)` y
el campo `updatedAt`. Divídelo para preparar solo el primero:

```bash
git add -p prisma/schema.prisma
```

- En el único bloque restante, teclea `s` para dividirlo en dos.
- Primer sub-bloque (`VarChar(255)`): teclea `y`.
- Segundo sub-bloque (`updatedAt`): teclea `n`.

Estado esperado: `VarChar(255)` preparado y `updatedAt` sin preparar.

### Step 4 — primer commit parcial

Confirma lo preparado (mensaje libre):

```bash
git commit -m "feat: agrega status a Task y ajusta User"
```

Mira qué entró al commit:

```bash
git show --stat
```

El `updatedAt` que dejaste afuera sigue sin confirmar en el working tree.

### Step 5 — segundo commit enfocado

Prepara el cambio que quedó pendiente y confírmalo en un segundo commit:

```bash
git add -p prisma/schema.prisma
```

- Teclea `y` en el único bloque restante.

```bash
git commit -m "feat: agrega updatedAt a User"
```

Estado esperado: working tree limpio.

## Verificar tu progreso

```bash
./verify.sh        # corre todos los steps
./verify.sh N      # corre los steps aplicables hasta el step N
```

Si algún check falla, el script te dice exactamente qué falta.
