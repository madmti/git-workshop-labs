# Lab 06 — Recuperando commits perdidos

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/06-recuperacion-commits/README.md).

## Objetivo

Perder commits por accidente y aprender a recuperarlos: con `git reflog`
(la bitácora de movimientos del `HEAD`) y, cuando el reflog ya fue
limpiado, con `git fsck` (los objetos "huérfanos" o _dangling_ que Git
conserva). Vas a trabajar sobre la configuración de un _reverse proxy_
nginx.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado
(`git init -b main`), tu identidad configurada a nivel local y 4 commits
en `main` que evolucionan la configuración de un _reverse proxy_ nginx
(`nginx.conf` + los server blocks de `conf.d/`).

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

## Steps

El verificador es acumulativo: `./verify.sh N` corre los checks desde el
step 1 hasta el N. `./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Explorar la configuración

Mira el historial y el estado del repo:

```bash
git log --oneline
```

Hay 4 commits en `main` que fueron armando el proxy. Abre la carpeta en tu
editor de código (por ejemplo `code .`) y explora la estructura:
`nginx.conf` es la configuración principal, y `conf.d/tienda.conf` y
`conf.d/blog.conf` son server blocks que hacen de _reverse proxy_ hacia los
backends.

Fíjate que `conf.d/tienda.conf` tiene un comentario
`# TODO (step 2)` donde vas a trabajar más adelante.

### Step 2 — Agregar un healthcheck (2 commits)

El equipo quiere un endpoint de salud para la tienda. Abre
`conf.d/tienda.conf` y, **reemplazando** el comentario `# TODO (step 2)`,
pega este bloque:

```nginx
    location /health {
        return 200 "ok";
    }
```

Guarda y haz el primer commit:

```bash
git add conf.d/tienda.conf
git commit -m "Agrega healthcheck de la tienda"
```

Ahora un segundo commit: documenta el endpoint en el `README.md` del
proyecto (agrega una línea, por ejemplo):

```markdown
El healthcheck de la tienda responde en `/health`.
```

```bash
git add README.md
git commit -m "Documenta el endpoint de salud"
```

Ya tienes 2 commits nuevos sobre `main`: el historial pasó de 4 a 6 commits.

### Step 3 — Perder los commits

Simula un accidente real: un `reset --hard` que te lleva 2 commits atrás
(es lo mismo que pasa cuando fuerzas el borrado de una rama con trabajo,
o cuando reseteas a un commit anterior):

```bash
git reset --hard main~2
```

Comprueba el "daño":

```bash
git log --oneline
git status
```

`main` volvió a 4 commits y el healthcheck ya no está. Pero los 2 commits
no se borraron del disco: Git los dejó apuntados en el reflog. A
recuperarlos.

### Step 4 — Recuperar con el reflog

El reflog registra el valor de `HEAD` cada vez que cambia. Consúltalo:

```bash
git reflog
```

Deberías ver algo así (los shas cambian en tu repo):

```
<sha-C4> HEAD@{0}: reset: moving to main~2
<sha-S2> HEAD@{1}: commit: Documenta el endpoint de salud
<sha-S1> HEAD@{2}: commit: Agrega healthcheck de la tienda
```

Los 2 commits que "perdiste" son los de `HEAD@{1}` y `HEAD@{2}`. Recupéralos
creando una rama que apunte al más reciente, `HEAD@{1}` (el que documenta
el endpoint). Anota ese sha y úsalo:

```bash
git branch recuperado-reflog <sha-de-HEAD@{1}>
```

Comprueba que recuperaste toda la historia:

```bash
git log --oneline recuperado-reflog
```

Ahí están los 6 commits: los 4 originales más los 2 que habías perdido.

### Step 5 — Recuperar con `git fsck`

El reflog puede ser limpiado (por ejemplo, cuando `gc` pasa un tiempo sin
que recuperes nada), y entonces el método anterior ya no sirve. Para
reproducir ese escenario, primero necesitas otro commit que perder.

Crea uno nuevo: agrega _rate limiting_ al proxy. Abre `nginx.conf` y,
**reemplazando** el comentario `# TODO (step 5)`, pega esta línea:

```nginx
    limit_req_zone $binary_remote_addr zone=api:10m rate=5r/s;
```

Guarda y haz el commit:

```bash
git add nginx.conf
git commit -m "Agrega rate limiting al proxy"
```

Ahora pierde ese commit de la misma forma que antes:

```bash
git reset --hard main~1
```

Hasta acá ese commit todavía se puede recuperar con el reflog. Simula que
el reflog se limpió:

```bash
git reflog expire --expire=now --all
```

> [!TIP]
> Esto borra todas las entradas del reflog, como si hubiera pasado mucho
> tiempo. No borra objetos del disco: los commits perdidos quedan como
> objetos "huérfanos" (_dangling_).

Como el reflog ya no tiene información, usa `git fsck` para que Git
compruebe la integridad de su base de datos y liste los objetos a los que
no se puede llegar:

```bash
git fsck --full
```

Entre las líneas `dangling blob` y `dangling tree` deberías ver una línea
`dangling commit <sha>`. Ese es el commit que perdiste hace un momento. Anota su sha
y recupéralo creando otra rama:

```bash
git branch recuperado-fsck <sha-del-dangling-commit>
```

```bash
git log --oneline recuperado-fsck
```

Listo: recuperaste el _rate limiting_ con `git fsck`.

## Verificar tu progreso

Desde la carpeta del lab (no desde `proyecto/`):

```bash
./verify.sh        # corre todos los steps
./verify.sh N        # corre los steps aplicables hasta el step N
```

Si algún check falla, el script te dice exactamente qué falta.
