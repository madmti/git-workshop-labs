# Lab 11 — Rangos de commits

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/11-rangos-commits/README.md).

## Objetivo

Practicar las sintaxis de rango de la clase — `A..B`, `A --not B` (y su
equivalente `^B A`) y el triple punto `A...B` con `--left-right`. Cada
commit del repositorio tiene como mensaje una **sola letra**, así que cada
consulta que armes deletrea una palabra. El enunciado de cada step te da la
palabra objetivo: tú tienes que encontrar el **comando** que la produce.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado y el
grafo completo pre-armado: las ramas `master`, `experiment` y `feature`,
donde cada commit representa una letra del alfabeto. El proyecto es un
script de migración (`migrate.py`) que busca patrones de archivos en un
filesystem y los convierte a nuevas versiones; el código importa solo como
contexto, lo que practicamos aquí es consultar el historial.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

Si quieres ver el grafo completo antes de empezar (te sirve como mapa para
ubicar qué letras viven en cada rama):

```bash
git log --oneline --graph --decorate --all --format='%s %d'
```

Este lab es de **solo lectura**: no hay `verify.sh`. En cada step la
solución es el comando exacto, oculto en un collapse — destápalo solo
después de haberlo intentado.

### Step 1 — La palabra GIT

`GIT` son las letras que viven **solo** en `experiment`. Arma el comando
con la sintaxis de doble punto que devuelve los commits que tiene
`experiment` y que `master` no tiene, usando `--format=%s` para que solo se
impriman las letras.

<details>
<summary>Solución</summary>

```bash
git log --format=%s master..experiment
```

</details>

### Step 2 — La palabra SOL

`SOL` son las letras que viven **solo** en `master`. Es el mismo doble
punto que en el step 1, pero en la dirección contraria.

<details>
<summary>Solución</summary>

```bash
git log --format=%s experiment..master
```

</details>

### Step 3 — La palabra NUBE

`NUBE` son las letras exclusivas de `feature`: commits alcanzables desde
`feature` que no están ni en `master` ni en `experiment`. Usa la sintaxis
con `--not` o `^`.

> **Ojo con `--not`:** cada aparición de `--not` invierte el signo de las
> referencias que le siguen, no se van "sumando" exclusiones. Para excluir
> `master` y `experiment` a la vez, ambos van después de un único `--not`.

<details>
<summary>Solución</summary>

```bash
git log --format=%s feature --not master experiment
```

</details>

### Step 4 — Las palabras SOL GIT

Ahora junta los exclusivos de los dos lados a la vez. Usa el triple punto
y `--left-right` para distinguir el lado izquierdo (con `<`) del derecho
(con `>`): las `<` deletrean `SOL` y las `>` deletrean `GIT`.

> **Ojo con `--format`:** al usar un formato personalizado, `--left-right`
> ya no agrega el marcador `<`/`>` automáticamente — hay que pedirlo
> explícitamente con `%m` dentro del `--format`.

<details>
<summary>Solución</summary>

```bash
git log --left-right --format='%m %s' master...experiment
```

</details>

## Verificar tu progreso

Como este lab es de solo lectura, no hay un script que corra: la
autocorrección son los collapses de cada step. Si tu comando no deletreó la
palabra esperada, repasa la sintaxis de rango correspondiente antes de
seguir.