# Ejercicio 02 — Configuración de Git

## Objetivo

Practicar la configuración de Git **a nivel de repositorio** (`--local`),
y entender por qué este nivel tiene prioridad sobre tu configuración
`--global`.

## Pasos

1. Ejecuta el script de inicialización:

   ```bash
   ./init.sh
   ```

   Esto crea un repositorio nuevo en `./mi-repo`.

2. Entra a la carpeta del repositorio:

   ```bash
   cd mi-repo
   ```

3. Configura tu nombre **solo para este repositorio** (nivel local, no global):

   ```bash
   git config --local user.name "Tu Nombre"
   ```

4. Configura tu email **solo para este repositorio**:

   ```bash
   git config --local user.email "tu@email.com"
   ```

5. Vuelve a esta carpeta y corre el verificador:

   ```bash
   cd ..
   ./verify.sh
   ```

6. Si algún check falla, el script te dice exactamente qué comando falta.

## Pista

Recuerda los 3 niveles de configuración vistos en clase:

- `--system`: todos los usuarios del sistema
- `--global`: tu usuario, en todos tus repositorios
- `--local`: solo el repositorio actual (por defecto si no pasas ninguna opción)

`--local` sobre-escribe a `--global`, que a su vez sobre-escribe a `--system`.
