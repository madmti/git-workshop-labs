# Lab 15 — Reescribiendo la historia

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/15-reescribiendo-historia/README.md).

## Objetivo

Practicar la reescritura de historia sobre un proyecto real de testing:
`git commit --amend` para corregir el ultimo commit, y el rebase interactivo
(`git rebase -i`) con `reword`, `squash`, `drop`, `edit` para reescribir
commits mas antiguos. Todo ocurre sobre una rama local, sin remotos: como
dice la clase, nunca se reescriben commits que ya fueron publicados.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado y la
historia pre-armada de una suite de testing de un endpoint HTTP en Python
(`app.py` con un servidor de la stdlib y `tests/test_api.py` con casos
`unittest`). El codigo importa solo como contexto: lo que practicas aca es
reescribir la historia, no programar.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

La historia inicial se ve asi (los mensajes son la pista para ubicarte en
cada step):

```bash
git log --oneline
```

```text
<ultimo>  Agrega tests de integirdad
          Agrega salida de debug al test
          Agrega endpoint /status
          Agrega test de /status
          Usa el helper en los tests
          Agrega helper para iniciar el servidor
          Corrige la salida del endpooint /health
          Agrega endpoint /version y su test
<raiz>    Agrega servidor con endpoint /health
```

> [!TIP]
> El orden del script del rebase es al reves que `git log`: el commit mas
> viejo aparece arriba. Guardas y cierras para aplicar.

Cada step te indica a que commit apuntar con su **mensaje**, no con su
hash: los hashes cambian a cada rewrite, pero los mensajes te permiten
volver a ubicarte despues de cada rebase.

## Steps

El verificador es **acumulativo**: `./verify.sh N` corre los checks
aplicables hasta el step N.
`./verify.sh` sin argumentos corre todos los steps.

### Step 1 — Configurar el editor

Varias operaciones de este lab (el rebase interactivo, por ejemplo) abren
tu editor de texto. Configuralo a nivel local en este repositorio para que
git use VS Code:

```bash
git config --local core.editor "code --wait"
```

> [!TIP]
> `--wait` hace que `code` se quede esperando a que cierres el archivo en
> el editor antes de devolver el control a git. Sin eso, git no veria tus
> cambios.

### Step 2 — Corregir el ultimo commit con `--amend`

El ultimo commit (`Agrega tests de integirdad`) tiene dos problemas: el
mensaje tiene un typo (`integirdad`) y ademas olvido incluir el archivo
`tests/__init__.py`, que hace falta para que el descubrimiento de tests
funcione.

Crea el archivo que falta (puede estar vacio) y preparalo:

```bash
git add tests/__init__.py
```

Ahora enmienda el commit **sin pasarle mensaje**:

```bash
git commit --amend
```

Como configuraste el editor en el step 1, git lo abre con el mensaje
anterior (`Agrega tests de integirdad`). Corrige el typo
(`integridad`), guarda y cierra.

El commit se reemplaza: la cantidad de commits no cambia, pero ahora el
ultimo trae consigo el archivo que faltaba y el mensaje corregido.

### Step 3 — Reescribir un mensaje con `reword`

El commit `Corrige la salida del endpooint /health` tambien tiene un typo
en su mensaje (`endpooint`). Queremos reescribir solo su mensaje, sin tocar
su contenido.

Ubicate con `git log --oneline` y anota el hash del commit **padre** del
que quieres cambiar (el commit `Agrega endpoint /version y su test`):

```bash
git rebase -i <hash-de-agrega-endpoint-version>
```

En el script del rebase, cambia `pick` a `reword` en la linea del commit
con el typo, guarda y cierra. Git reabrira el editor con el mensaje de ese
commit: corregi el typo y guarda. Los commits siguientes se reescriben con
nuevos hashes, pero el contenido no cambia.

### Step 4 — Combinar commits con `squash`

Los commits `Agrega helper para iniciar el servidor` y
`Usa el helper en los tests` son en realidad un solo cambio logico
(extraer el helper y usarlo). Queremos combinarlos en uno.

Ubicate con `git log --oneline` y anota el hash del padre de
`Agrega helper para iniciar el servidor` (el commit ya corregido
`Corrige la salida del endpoint /health`):

```bash
git rebase -i <hash-de-corrige-la-salida>
```

En el script, deja `pick` en `Agrega helper para iniciar el servidor` y
cambia `pick` a `squash` en `Usa el helper en los tests`, guarda y cierra.
Git abrira el editor para combinar los dos mensajes: deja el del helper
(borra el del segundo). Al terminar, los dos commits quedan fusionados en
uno y la historia tiene un commit menos.

### Step 5 — Reordenar y eliminar commits

Hay dos problemas en la parte de arriba de la historia: los commits de
`/status` estan en orden invertido (primero se agrego el test y despues el
endpoint), y el commit `Agrega salida de debug al test` es ruido que no
deberia estar. Reordena y elimina en un solo rebase.

Ubicate con `git log --oneline` y anota el hash del padre del commit mas
viejo que vas a tocar (el padre de `Agrega test de /status`, que es el
commit resultante del step 4, `Agrega helper para iniciar el servidor`):

```bash
git rebase -i <hash-de-agrega-helper>
```

En el script, intercambia las dos lineas de `/status` para que quede
primero `Agrega endpoint /status` y despues `Agrega test de /status`, y
cambia `pick` a `drop` en `Agrega salida de debug al test`. Guarda y cierra.

### Step 6 — Dividir un commit con `edit`

El commit `Agrega endpoint /version y su test` mezcla dos cambios que
deberian ser commits separados: el endpoint en `app.py` y su test en
`tests/test_api.py`. Vamos a dividirlo en dos.

Ubicate con `git log --oneline` y anota el hash de la raiz
(`Agrega servidor con endpoint /health`):

```bash
git rebase -i <hash-de-agrega-servidor>
```

En el script, cambia `pick` a `edit` en `Agrega endpoint /version y su
test`, guarda y cierra. Git se detiene en ese commit, con su cambios
aplicados pero sin avanzar. Ahora deshacemos el commit y lo rearmamos en
dos partes:

```bash
git reset HEAD^
git add app.py
git commit -m "Agrega endpoint /version"
```
```bash
git add tests/test_api.py
git commit -m "Agrega test de /version"
git rebase --continue
```

Al terminar, la historia final se ve asi:

```text
<ultimo>  Agrega tests de integridad
          Agrega endpoint /status
          Agrega test de /status
          Agrega helper para iniciar el servidor
          Corrige la salida del endpoint /health
          Agrega test de /version
          Agrega endpoint /version
<raiz>    Agrega servidor con endpoint /health
```

## Verificar tu progreso

```bash
./verify.sh        # corre todos los steps
./verify.sh N        # corre los steps aplicables hasta el step N
```

Si algun check falla, el script te dice exactamente que falta.
