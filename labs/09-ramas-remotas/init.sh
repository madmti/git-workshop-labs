#!/usr/bin/env bash
set -eu
# Nota: NO se usa 'set -o pipefail' a proposito -- ver AGENTS.md (condicion
# de carrera con SIGPIPE al combinarlo con pipes).

# --- Manejo de color -------------------------------------------------
# Se puede desactivar con: ./init.sh --no-color
# o con:                   COLORS=0 ./init.sh
USE_COLOR=1
[ "${COLORS:-1}" = "0" ] && USE_COLOR=0
[ -t 1 ] || USE_COLOR=0
for arg in "$@"; do
  [ "$arg" = "--no-color" ] && USE_COLOR=0
done

if [ "$USE_COLOR" = "1" ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi
# -----------------------------------------------------------------------

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
EQUIPO_BARE="$LAB_DIR/remoto-equipo.git"
TEAMONE_BARE="$LAB_DIR/remoto-teamone.git"
COMPANERO_DIR="$LAB_DIR/companero"
PUSH_SCRIPT="$LAB_DIR/push-companero.sh"

if [ -d "$EQUIPO_BARE" ] || [ -d "$TEAMONE_BARE" ] || [ -d "$COMPANERO_DIR" ]; then
  echo -e "${YELLOW}[!]${NC} Ya existe alguno de los elementos del lab."
  echo "    Si quieres reiniciar desde cero, borra todo lo que creo init.sh:"
  echo "    rm -rf remoto-equipo.git remoto-teamone.git companero push-companero.sh"
  exit 1
fi

# --- Identidad de git (solo si falta) ----------------------------------
# El alumno clona su propio repositorio, asi que la identidad para sus
# commits sale del config GLOBAL. Si no esta configurada, la dejamos
# preparada aca para que el alumno no se quede trabado al commitear.
echo -e "${BLUE}[i]${NC} Verificando la identidad de git..."
if [ -z "$(git config --global --get user.name 2>/dev/null)" ]; then
  git config --global user.name "Taller Git"
  echo -e "${YELLOW}[!]${NC} No tenias user.name global; se configuro 'Taller Git'"
fi
if [ -z "$(git config --global --get user.email 2>/dev/null)" ]; then
  git config --global user.email "taller@git-workshop.local"
  echo -e "${YELLOW}[!]${NC} No tenias user.email global; se configuro 'taller@git-workshop.local'"
fi

# --- Crear los dos servidores remotos (bare) ---------------------------
echo -e "${BLUE}[i]${NC} Creando los servidores remotos..."
git init --bare -q "$EQUIPO_BARE"
git -C "$EQUIPO_BARE" symbolic-ref HEAD refs/heads/main
git init --bare -q "$TEAMONE_BARE"
git -C "$TEAMONE_BARE" symbolic-ref HEAD refs/heads/main

# --- Construir la historia semilla (4 commits) -------------------------
# Se arma en un directorio temporal y se pushea a ambos servidores, para
# que los dos arranquen con el mismo estado inicial.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/css"

git -C "$TMP_DIR" init -q -b main
git -C "$TMP_DIR" config user.name "Taller Git"
git -C "$TMP_DIR" config user.email "taller@git-workshop.local"

# commit 1: sitio base
cat > "$TMP_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Tienda Online</title>
  <link rel="stylesheet" href="css/estilos.css">
</head>
<body>
  <header>
    <h1>Tienda Online</h1>
    <nav>
      <ul>
        <li><a href="#">Inicio</a></li>
        <li><a href="#">Productos</a></li>
        <li><a href="mailto:email.support@github.com">Contacto</a></li>
      </ul>
    </nav>
  </header>

  <main>
    <section>
      <h2>Bienvenidos</h2>
      <p>Lo mejor de la tecnologia al mejor precio.</p>
    </section>
    <!-- TODO (step 2) -->
  </main>
</body>
</html>
EOF

cat > "$TMP_DIR/css/estilos.css" << 'EOF'
body {
  font-family: sans-serif;
  margin: 0;
  padding: 0;
}

header {
  background-color: #f5f5f5;
  padding: 1rem;
}

header h1 {
  margin: 0;
  color: #333;
}

/* TODO (step 5) */
EOF

cat > "$TMP_DIR/README.md" << 'EOF'
# Tienda Online

Sitio web estatico de la tienda online del equipo.

## Estructura

- `index.html`: pagina principal.
- `css/estilos.css`: estilos del sitio.

> TODO (step 6)
EOF

git -C "$TMP_DIR" add -A
git -C "$TMP_DIR" commit -q -m "commit inicial"

# commit 2: agregar footer
cat > "$TMP_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Tienda Online</title>
  <link rel="stylesheet" href="css/estilos.css">
</head>
<body>
  <header>
    <h1>Tienda Online</h1>
    <nav>
      <ul>
        <li><a href="#">Inicio</a></li>
        <li><a href="#">Productos</a></li>
        <li><a href="mailto:email.support@github.com">Contacto</a></li>
      </ul>
    </nav>
  </header>

  <main>
    <section>
      <h2>Bienvenidos</h2>
      <p>Lo mejor de la tecnologia al mejor precio.</p>
    </section>
    <!-- TODO (step 2) -->
  </main>

  <footer>
    <p>Tienda Online</p>
  </footer>
</body>
</html>
EOF

git -C "$TMP_DIR" add index.html
git -C "$TMP_DIR" commit -q -m "agregar footer"

# commit 3: corregir email de contacto
sed -i 's/email.support@github.com/support@github.com/' "$TMP_DIR/index.html"
git -C "$TMP_DIR" add index.html
git -C "$TMP_DIR" commit -q -m "corregir email de contacto"

# commit 4: agregar copyright
cat > "$TMP_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Tienda Online</title>
  <link rel="stylesheet" href="css/estilos.css">
</head>
<body>
  <header>
    <h1>Tienda Online</h1>
    <nav>
      <ul>
        <li><a href="#">Inicio</a></li>
        <li><a href="#">Productos</a></li>
        <li><a href="mailto:support@github.com">Contacto</a></li>
      </ul>
    </nav>
  </header>

  <main>
    <section>
      <h2>Bienvenidos</h2>
      <p>Lo mejor de la tecnologia al mejor precio.</p>
    </section>
    <!-- TODO (step 2) -->
  </main>

  <footer>
    <p>Tienda Online</p>
    <p>&copy; 2026 Tienda Online</p>
  </footer>
</body>
</html>
EOF

git -C "$TMP_DIR" add index.html
git -C "$TMP_DIR" commit -q -m "agregar copyright"

# --- Subir la historia a ambos servidores ------------------------------
git -C "$TMP_DIR" push -q "$EQUIPO_BARE" main
git -C "$TMP_DIR" push -q "$TEAMONE_BARE" main

# --- Copia de trabajo de la companera (commit B listo, sin subir) -------
echo -e "${BLUE}[i]${NC} Preparando la copia de trabajo de Maria..."
git clone -q "$EQUIPO_BARE" "$COMPANERO_DIR"
git -C "$COMPANERO_DIR" config user.name "Maria Gomez"
git -C "$COMPANERO_DIR" config user.email "maria@git-workshop.local"

cat > "$COMPANERO_DIR/CHANGELOG.md" << 'EOF'
# Changelog

## 1.0.1 - 2026-08-01

- Agregado CHANGELOG.md para registrar los cambios del proyecto.
- Corregido el email de contacto en el header.
EOF

git -C "$COMPANERO_DIR" add CHANGELOG.md
git -C "$COMPANERO_DIR" commit -q -m "agregar CHANGELOG.md"

# --- Script que simula el push de la companera --------------------------
cat > "$PUSH_SCRIPT" << 'EOF'
#!/usr/bin/env bash
set -e
LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Simulando que Maria sube su trabajo al servidor..."
git -C "$LAB_DIR/companero" push origin main
echo "Listo: remoto-equipo.git tiene ahora el commit de Maria."
EOF
chmod +x "$PUSH_SCRIPT"

# --- Resumen final ------------------------------------------------------
echo ""
echo -e "${GREEN}[OK]${NC} Todo listo. Se crearon:"
echo "  - remoto-equipo.git/    servidor del equipo (bare, 4 commits)"
echo "  - remoto-teamone.git/   segundo servidor (mismo estado inicial)"
echo "  - companero/            copia de Maria, con un commit sin subir"
echo "  - push-companero.sh     simula que Maria sube su commit"
echo ""
echo "Sigue el README.md desde el step 1. Primera accion:"
echo -e "  ${BLUE}git clone remoto-equipo.git proyecto${NC}"
echo ""
echo -e "${YELLOW}[i]${NC} Si tu terminal no soporta colores, usa: ./init.sh --no-color"
