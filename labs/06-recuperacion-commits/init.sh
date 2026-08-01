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

# --- Commit 1: configuracion base -----------------------------------------
cat > "$REPO_DIR/nginx.conf" <<'EOF'
# Configuracion principal del reverse proxy
# Carga los server blocks definidos en conf.d/

worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include conf.d/*.conf;

    sendfile on;
    keepalive_timeout 65;

    # TODO (step 5): agregar aqui el rate limiting (ver README, step 5)
}
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# Proxy nginx

Configuracion de un reverse proxy nginx para los servicios del equipo.

## Backends

- tienda -> 127.0.0.1:5000
- blog   -> 127.0.0.1:8080
EOF

cat > "$REPO_DIR/.gitignore" <<'EOF'
logs/
*.pid
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Configuracion base del proxy"

# --- Commit 2: server de la tienda ----------------------------------------
mkdir -p "$REPO_DIR/conf.d"

cat > "$REPO_DIR/conf.d/tienda.conf" <<'EOF'
# Server de la tienda
# Reverse proxy hacia el backend de la tienda (127.0.0.1:5000)

server {
    listen 80;
    server_name tienda.midominio.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # TODO (step 2): agregar aqui el bloque del healthcheck (ver README, step 2)
}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega el server de la tienda"

# --- Commit 3: server del blog --------------------------------------------
cat > "$REPO_DIR/conf.d/blog.conf" <<'EOF'
# Server del blog
# Reverse proxy hacia el backend del blog (127.0.0.1:8080)

server {
    listen 80;
    server_name blog.midominio.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
    }
}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega el server del blog"

# --- Commit 4: gzip y headers de seguridad --------------------------------
cat > "$REPO_DIR/nginx.conf" <<'EOF'
# Configuracion principal del reverse proxy
# Carga los server blocks definidos en conf.d/

worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include conf.d/*.conf;

    sendfile on;
    keepalive_timeout 65;

    # Compresion y headers de seguridad
    gzip on;
    gzip_types text/plain text/css application/json;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;

    # TODO (step 5): agregar aqui el rate limiting (ver README, step 5)
}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Habilita gzip y headers de seguridad"

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} 4 commits en main que arman el proxy nginx (nginx.conf + conf.d/)\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
