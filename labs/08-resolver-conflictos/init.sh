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
    <p class="contacto">contact : support@github.com</p>
  </header>

  <main>
    <p>Bienvenido a la tienda.</p>
  </main>
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
    <p class="contacto">contact : support@github.com</p>
  </header>

  <main>
    <p>Bienvenido a la tienda.</p>
  </main>
</body>
</html>
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega los estilos del sitio"

# --- Commit 3: README del proyecto ------------------------------------------
cat > "$REPO_DIR/README.md" <<'EOF'
# Tienda Online

Mini sitio web estatico de la tienda.

## Ramas

- `main`: produccion
- `feat/header-v2`: rediseno del header (en desarrollo)
- `exp/colores`: experimento de colores (descartado)
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega el README del proyecto"

# --- Rama feat/header-v2: rediseno del header -------------------------------
git -C "$REPO_DIR" checkout -q -b feat/header-v2

cat > "$REPO_DIR/css/estilos.css" <<'EOF'
/* Estilos base de la tienda */
body {
  font-family: sans-serif;
  margin: 0;
  padding: 1rem;
}

header h1 {
  color: #1a3a6b;
  font-size: 2rem;
}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Rediseña el header del sitio"

# --- Rama exp/colores: experimento de colores -------------------------------
git -C "$REPO_DIR" checkout -q main
git -C "$REPO_DIR" checkout -q -b exp/colores

cat > "$REPO_DIR/css/estilos.css" <<'EOF'
/* Estilos base de la tienda */
body {
  font-family: sans-serif;
  margin: 0;
  padding: 1rem;
}

header h1 {
  color: #b8860b;
  letter-spacing: 0.1em;
}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Prueba colores dorados para el header"

# --- Commit 4 en main: ajuste urgente (despues de que las ramas divergieron) -
git -C "$REPO_DIR" checkout -q main

cat > "$REPO_DIR/css/estilos.css" <<'EOF'
/* Estilos base de la tienda */
body {
  font-family: sans-serif;
  margin: 0;
  padding: 1rem;
}

header h1 {
  color: #333;
  margin-bottom: 1.5rem;
}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Ajusta el espaciado del header"

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} main con el sitio en produccion y un ajuste al header (4 commits)\n"
printf "${BLUE}[i]${NC} feat/header-v2 y exp/colores modificaron la misma regla CSS\n"
printf "${BLUE}[i]${NC} Quedas en main con el working tree limpio\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
