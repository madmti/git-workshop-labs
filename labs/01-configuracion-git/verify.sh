#!/usr/bin/env bash
set -uo pipefail

# --- Manejo de color -------------------------------------------------
# Se puede desactivar con: ./verify.sh --no-color
# o con:                   COLORS=0 ./verify.sh
USE_COLOR=1
[ "${COLORS:-1}" = "0" ] && USE_COLOR=0
[ -t 1 ] || USE_COLOR=0
for arg in "$@"; do
  [ "$arg" = "--no-color" ] && USE_COLOR=0
done

if [ "$USE_COLOR" = "1" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi
# -----------------------------------------------------------------------

EXERCISE_DIR="mi-repo"
PASS=0
TOTAL=2

echo "Verificando ejercicio 02: Configuracion local de Git"
echo "-----------------------------------------------------"

if [ ! -d "$EXERCISE_DIR/.git" ]; then
  echo -e "${RED}[x]${NC} No se encontro un repositorio Git en ./$EXERCISE_DIR"
  echo "    ¿Ejecutaste ./init.sh primero?"
  exit 1
fi

cd "$EXERCISE_DIR"

# --- Check 1: user.name a nivel LOCAL (no heredado de --global) ---
LOCAL_NAME=$(git config --local --get user.name 2>/dev/null || true)
if [ -n "$LOCAL_NAME" ]; then
  echo -e "${GREEN}[OK]${NC} user.name configurado localmente: \"$LOCAL_NAME\""
  PASS=$((PASS + 1))
else
  echo -e "${RED}[x]${NC} user.name no esta configurado a nivel local"
  echo "    Ejecuta: git config --local user.name \"Tu Nombre\""
fi

# --- Check 2: user.email a nivel LOCAL, con formato valido ---
LOCAL_EMAIL=$(git config --local --get user.email 2>/dev/null || true)
if [ -n "$LOCAL_EMAIL" ] && [[ "$LOCAL_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
  echo -e "${GREEN}[OK]${NC} user.email configurado localmente: \"$LOCAL_EMAIL\""
  PASS=$((PASS + 1))
else
  echo -e "${RED}[x]${NC} user.email no esta configurado (o no tiene formato valido) a nivel local"
  echo "    Ejecuta: git config --local user.email \"tu@email.com\""
fi

# --- Bonus informativo: mostrar precedencia local vs global ---
GLOBAL_NAME=$(git config --global --get user.name 2>/dev/null || true)
if [ -n "$LOCAL_NAME" ] && [ -n "$GLOBAL_NAME" ] && [ "$GLOBAL_NAME" != "$LOCAL_NAME" ]; then
  echo ""
  echo -e "${YELLOW}[i]${NC} Tip: tu user.name global es \"$GLOBAL_NAME\", pero en este repo"
  echo "    Git usara \"$LOCAL_NAME\" porque el valor local tiene prioridad."
fi

echo "-----------------------------------------------------"
echo "$PASS/$TOTAL checks superados"

if [ "$PASS" -eq "$TOTAL" ]; then
  echo -e "${GREEN}[OK]${NC} Ejercicio completado"
  exit 0
else
  echo -e "${RED}[x]${NC} Todavia faltan cosas por configurar."
  exit 1
fi
