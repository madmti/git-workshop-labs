# Lab 14 — Busqueda en el historial

> ¿Prefieres leerlo en el navegador? Este mismo README está en [GitHub](https://github.com/madmti/git-workshop-labs/blob/main/labs/14-busqueda-historial/README.md).

## Objetivo

Practicar las herramientas de busqueda de la clase — `git grep` con sus
opciones (`-n`, `--count`, `--and`, `--break`, `--heading`) y la busqueda en
el historial con `git log -S`, `-G` y `-L`. Cada commit del repositorio tiene
como mensaje una **sola letra**, así que las busquedas en el historial
deletrean una palabra: tú tienes que encontrar el **comando** que la produce.

## Antes de empezar

```bash
./init.sh
```

Esto crea la carpeta `proyecto/` con un repositorio ya inicializado y la
historia completa pre-armada: 5 commits (`0`, `A`, `O`, `L`, `V`) y un tag
`v1.0` a mitad de camino. El proyecto es **infraestructura como codigo en
Terraform**: una instancia EC2 con su grupo de seguridad y un bucket S3 para
los assets. El código importa solo como contexto; lo que practicamos aquí es
buscar en el historial.

Todos los steps se ejecutan dentro de `proyecto/`:

```bash
cd proyecto
```

Si quieres ver la historia completa antes de empezar (te sirve como mapa para
saber qué letra va en qué commit):

```bash
git log --oneline --decorate --all --format='%s %d'
```

Este lab es de **solo lectura**: no hay `verify.sh`. Cada step incluye el
**output esperado** para que compruebes tu comando sin ver la solución. Prueba
distintos comandos hasta llegar al output esperado; si te trabas, solo entonces
destapa el collapse con el comando exacto.

### Step 1 — Dónde se usa la instancia EC2

¿En qué archivos se referencia el recurso `aws_instance` y en qué líneas?
`git grep` busca en el directorio de trabajo; con `-n` agrega el número de
línea de cada coincidencia. Deberías encontrar coincidencias en dos archivos.

**Output esperado:**

```text
main.tf:18:resource "aws_instance" "web" {
outputs.tf:3:  value       = aws_instance.web.public_ip
```

<details>
<summary>Solución</summary>

```bash
git grep -n "aws_instance"
```

</details>

### Step 2 — Cuántas veces aparece por archivo

En lugar de ver cada coincidencia, `--count` resume cuántas veces aparece una
cadena en cada archivo. Cuenta cuántas veces aparece la palabra `resource` en
todo el proyecto (pista: el resultado tiene dos líneas, una por archivo).

**Output esperado:**

```text
main.tf:2
modules/networking/main.tf:1
```

<details>
<summary>Solución</summary>

```bash
git grep --count "resource"
```

</details>

### Step 3 — Buscar en un árbol antiguo

A diferencia de `grep` común, `git grep` no se limita al directorio de trabajo:
puedes buscar en cualquier árbol del historial. Busca en el tag `v1.0` las
líneas que son declaraciones de recursos — es decir, que contienen `resource`
**y** `aws_` en la **misma línea** (`--and`). Para que el resultado sea más
legible, usa `--break` y `--heading`.

Deberías ver tres coincidencias agrupadas bajo el header `v1.0:main.tf`.

**Output esperado:**

```text
v1.0:main.tf
14:resource "aws_security_group" "web" {
37:resource "aws_instance" "web" {
47:resource "aws_s3_bucket" "assets" {
```

<details>
<summary>Solución</summary>

```bash
git grep --break --heading -n -e 'resource' --and -e 'aws_' v1.0
```

> Ejecuta el mismo comando **sin** el tag `v1.0` para comparar: ahora el output
> se agrupa en dos headers (`main.tf` y `modules/networking/main.tf`) porque el
> security group se movió a un módulo.

</details>

### Step 4 — La palabra LA

`git log -S"<cadena>"` lista los commits que **agregaron o eliminaron** esa
cadena (el pickaxe). Como cada commit tiene una letra como mensaje, usar
`--format=%s` hace que el output deletree una palabra.

¿En qué commits apareció o desapareció el string `aws_security_group`? El
resultado debe deletrear la palabra **LA** (del más nuevo al más viejo).

**Output esperado:**

```text
L
A
```

<details>
<summary>Solución</summary>

```bash
git log -S"aws_security_group" --format=%s
```

> Si en vez de una cadena exacta quieres usar una expresión regular, la
> variante es `git log -G"<regex>"`.

</details>

### Step 5 — El historial de un bloque

`git log -L <inicio>,<fin>:<archivo>` muestra el historial de las líneas que
van de `<inicio>` a `<fin>`. Cuando Git puede detectar funciones las toma por
nombre; cuando no (como en Terraform), `<inicio>` y `<fin>` aceptan una
**expresión regular** escrita entre `/`.

No hace falta saber armar expresiones regulares: usa estas dos, ya explicadas:

- `/resource "aws_s3_bucket"/` — la línea que declara el bucket.
- `/^}/` — la primera línea que es solo una llave `}` (el `^` significa
  "empieza la línea").

Con esas dos expresiones, arma el comando de `git log -L` para el archivo
`main.tf`. El output debe mostrar los commits **V** y **O** (en ese orden, del
más nuevo al más viejo).

**Output esperado:**

```text
commit de94508d0f0034fc492daf6323ad152ee808c139
Author: Estudiante Taller Git <estudiante@taller.local>
Date:   Sat Aug 1 09:22:00 2026 -0400

    V

diff --git a/main.tf b/main.tf
index 48d23e1..c7bd965 100644
--- a/main.tf
+++ b/main.tf
@@ -28,7 +28,8 @@ resource "aws_instance" "web" {
 resource "aws_s3_bucket" "assets" {
-  bucket = "assets-${var.app_name}"
+  bucket        = "assets-${var.app_name}"
+  force_destroy = true
 
   tags = {
     Name = "assets-${var.app_name}"
   }
 }

commit c13bf499820691713c76c3b029630ba8a409cae4
Author: Estudiante Taller Git <estudiante@taller.local>
Date:   Sat Aug 1 09:10:00 2026 -0400

    O

diff --git a/main.tf b/main.tf
index 0d22fcb..a2f2893 100644
--- a/main.tf
+++ b/main.tf
@@ -46,0 +47,7 @@ resource "aws_instance" "web" {
+resource "aws_s3_bucket" "assets" {
+  bucket = "assets-${var.app_name}"
+
+  tags = {
+    Name = "assets-${var.app_name}"
+  }
+}
```

<details>
<summary>Solución</summary>

```bash
git log -L '/resource "aws_s3_bucket"/,/^}/:main.tf'
```

</details>

## Verificar tu progreso

Como este lab es de solo lectura, no hay un script que corra: la
autocorrección es el **output esperado** de cada step. Si tu comando no
produce ese output, prueba variantes de la opción correspondiente; y si después
de intentarlo te trabas, solo entonces destapa el collapse con la solución.
