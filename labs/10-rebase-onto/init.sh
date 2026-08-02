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
git -C "$REPO_DIR" init -q -b master
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

# --- Commit raiz (X): API base ----------------------------------------------
cat > "$REPO_DIR/main.py" <<'EOF'
from fastapi import FastAPI

app = FastAPI(title="API de productos")


@app.get("/")
def root():
    return {"message": "API de productos"}
EOF

cat > "$REPO_DIR/requirements.txt" <<'EOF'
fastapi==0.115.6
uvicorn[standard]==0.32.1
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# API de productos

API minimalista construida con FastAPI.

## Puesta en marcha

1. Instalar dependencias: `pip install -r requirements.txt`
2. Levantar el servidor: `uvicorn main:app --reload`
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "API base de productos"

# --- master (M1): endpoint /health ------------------------------------------
cat > "$REPO_DIR/main.py" <<'EOF'
from fastapi import FastAPI

app = FastAPI(title="API de productos")


@app.get("/")
def root():
    return {"message": "API de productos"}


@app.get("/health")
def health():
    return {"status": "ok"}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega endpoint /health"

# --- master (M2): archivo de configuracion ----------------------------------
cat > "$REPO_DIR/config.py" <<'EOF'
APP_NAME = "API de productos"
VERSION = "0.1.0"
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega archivo de configuracion"

# --- experiment (E1): modulo de busqueda, desde el commit raiz ---------------
BASE="$(git -C "$REPO_DIR" rev-list --max-parents=0 HEAD)"
git -C "$REPO_DIR" checkout -q -b experiment "$BASE"

cat > "$REPO_DIR/search.py" <<'EOF'
def buscar_productos(termino, catalogo):
    """Busca productos por nombre (experimental)."""
    return [p for p in catalogo if termino.lower() in p["nombre"].lower()]
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Modulo de busqueda experimental"

# --- server (S1): logica de servidor, desde el commit raiz -------------------
git -C "$REPO_DIR" checkout -q master
git -C "$REPO_DIR" checkout -q -b server "$BASE"

cat > "$REPO_DIR/server.py" <<'EOF'
def procesar_pedido(pedido):
    """Server-side: valida y procesa un pedido."""
    if not pedido.get("items"):
        raise ValueError("El pedido no tiene items")
    return {"estado": "procesado", "pedido_id": pedido["id"]}
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Logica de servidor para pedidos"

# --- client (C1): cliente para descargar el catalogo, sobre server -----------
git -C "$REPO_DIR" checkout -q -b client server

cat > "$REPO_DIR/client.py" <<'EOF'
import httpx


def descargar_catalogo(base_url):
    """Client-side: baja el catalogo desde la API."""
    resp = httpx.get(f"{base_url}/")
    resp.raise_for_status()
    return resp.json()
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Cliente para descargar el catalogo"

# --- cierre ------------------------------------------------------------------
git -C "$REPO_DIR" checkout -q master

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} Grafo pre-armado:\n"
printf "${BLUE}    master     = X -> M1 -> M2${NC} (2 commits sobre la base)\n"
printf "${BLUE}    experiment = X -> E1${NC} (divergida de master)\n"
printf "${BLUE}    server     = X -> S1${NC}\n"
printf "${BLUE}    client     = X -> S1 -> C1${NC} (sobre server)\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
