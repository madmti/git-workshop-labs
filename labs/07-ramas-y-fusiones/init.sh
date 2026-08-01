#!/usr/bin/env bash
set -u

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

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$LAB_DIR/proyecto"

if [ -d "$REPO_DIR" ]; then
  printf "${YELLOW}[!]${NC} La carpeta %s ya existe.\n" "$REPO_DIR"
  printf "${YELLOW}[i]${NC} Si quieres empezar de cero, bórrala y vuelve a ejecutar ./init.sh\n"
  exit 1
fi

mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q -b main
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

# --- Commit 1: pagina base -------------------------------------------------
cat > "$REPO_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Tienda Online</title>
</head>
<body>
  <header>
    <h1>Tienda Online</h1>
    <p class="contacto">contact : email.support@github.com</p>
  </header>

  <main>
    <p>Bienvenido a la tienda.</p>
  </main>

  <!-- TODO (step 1): agregar el footer (ver README, step 1) -->
</body>
</html>
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Pagina base de la tienda"

# --- Commit 2: estilos ------------------------------------------------------
mkdir -p "$REPO_DIR/css"

cat > "$REPO_DIR/css/estilos.css" <<'EOF'
/* Estilos base de la tienda */
body {
  font-family: sans-serif;
  margin: 0;
  padding: 1rem;
}

header h1 {
  color: #333;
}
EOF

cat > "$REPO_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Tienda Online</title>
  <link rel="stylesheet" href="css/estilos.css" />
</head>
<body>
  <header>
    <h1>Tienda Online</h1>
    <p class="contacto">contact : email.support@github.com</p>
  </header>

  <main>
    <p>Bienvenido a la tienda.</p>
  </main>

  <!-- TODO (step 1): agregar el footer (ver README, step 1) -->
</body>
</html>
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega los estilos del sitio"

# --- Commit 3: contenido y README ------------------------------------------
cat > "$REPO_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Tienda Online</title>
  <link rel="stylesheet" href="css/estilos.css" />
</head>
<body>
  <header>
    <h1>Tienda Online</h1>
    <p class="contacto">contact : email.support@github.com</p>
  </header>

  <main>
    <p>Bienvenido a la tienda.</p>
    <section>
      <h2>Novedades</h2>
      <p>Lanzamos la nueva colección de productos.</p>
    </section>
  </main>

  <!-- TODO (step 1): agregar el footer (ver README, step 1) -->
</body>
</html>
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# Tienda Online

Mini sitio web estático de la tienda.
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega la seccion de novedades y el README"

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} 3 commits en main que arman el sitio web (index.html + css/)\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
