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

commit() {
  local fecha="$1"
  local mensaje="$2"
  GIT_AUTHOR_DATE="$fecha" GIT_COMMITTER_DATE="$fecha" git -C "$REPO_DIR" commit -q -m "$mensaje"
}

# --- C1 (raiz): script de backup basico -------------------------------------
cat > "$REPO_DIR/backup.sh" <<'EOF'
#!/usr/bin/env bash
set -u

# Script de backup: empaqueta DIR_ORIGEN en DESTINO usando tar.
# Uso: ./backup.sh

ORIGEN="./datos"
DESTINO="./backups"

mkdir -p "$DESTINO"
tar -cvf "$DESTINO/backup-$(date +%Y%m%d).tar" "$ORIGEN"
echo "Backup generado en $DESTINO"
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# Script de Backup

Backup de un directorio local usando tar. Incluye configuracion de
directorios de origen y destino.

## Uso

El backup se genera con tar.
./backup.sh
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-03T09:00:00" "Agrega script de backup"

# --- C2: configuracion de backup (backup.conf leida por backup.sh) -----------
cat > "$REPO_DIR/backup.conf" <<'EOF'
# Configuracion del backup

DIR_ORIGEN="./datos"
DESTINO="./backups"

# TODO (step 2): descomenta la siguiente linea para activar las alertas por email
# ALERTA_EMAIL="admin@example.com"
EOF

cat > "$REPO_DIR/backup.sh" <<'EOF'
#!/usr/bin/env bash
set -u

# Script de backup: empaqueta DIR_ORIGEN en DESTINO usando tar.
# Lee la configuracion de backup.conf.
# Uso: ./backup.sh

CONFIG="$(dirname "$0")/backup.conf"
[ -f "$CONFIG" ] && . "$CONFIG"

ORIGEN="${DIR_ORIGEN:-./datos}"
DESTINO="${DESTINO:-./backups}"

mkdir -p "$DESTINO"
tar -cvf "$DESTINO/backup-$(date +%Y%m%d).tar" "$ORIGEN"
echo "Backup generado en $DESTINO"
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-03T09:02:00" "Agrega configuracion de backup"

# --- C3 (HEAD): compresion gzip en el backup ---------------------------------
cat > "$REPO_DIR/backup.sh" <<'EOF'
#!/usr/bin/env bash
set -u

# Script de backup: empaqueta DIR_ORIGEN en DESTINO usando tar con compresion gzip.
# Lee la configuracion de backup.conf.
# Uso: ./backup.sh

CONFIG="$(dirname "$0")/backup.conf"
[ -f "$CONFIG" ] && . "$CONFIG"

ORIGEN="${DIR_ORIGEN:-./datos}"
DESTINO="${DESTINO:-./backups}"

mkdir -p "$DESTINO"
tar -zcvf "$DESTINO/backup-$(date +%Y%m%d).tar.gz" "$ORIGEN"
echo "Backup generado en $DESTINO"
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-03T09:04:00" "Agrega compresion al backup"

# --- cierre ------------------------------------------------------------------
printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} Historia inicial (git log --oneline):\n"
git -C "$REPO_DIR" log --oneline
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
