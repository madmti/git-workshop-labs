#!/usr/bin/env bash
set -euo pipefail

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
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi
# -----------------------------------------------------------------------

EXERCISE_DIR="mi-repo"

if [ -d "$EXERCISE_DIR" ]; then
  echo -e "${YELLOW}[!]${NC} El directorio '$EXERCISE_DIR' ya existe."
  echo "    Si quieres reiniciar el ejercicio desde cero, bórralo primero:"
  echo "    rm -rf $EXERCISE_DIR"
  exit 1
fi

mkdir "$EXERCISE_DIR"
cd "$EXERCISE_DIR"
git init -q

echo -e "${GREEN}[OK]${NC} Repositorio creado en ./$EXERCISE_DIR"
echo ""
echo -e "${BOLD}=========================================================="
echo " Ejercicio 02 - Configuracion de Git"
echo -e "==========================================================${NC}"
echo ""
echo "Objetivo:"
echo "  Configurar Git a nivel de repositorio (--local), y no a nivel"
echo "  global, para entender por que este nivel tiene prioridad."
echo ""
echo "Pasos:"
echo -e "  1. Entra a la carpeta:"
echo -e "     ${BLUE}cd $EXERCISE_DIR${NC}"
echo ""
echo "  2. Configura tu nombre SOLO para este repositorio:"
echo -e "     ${BLUE}git config --local user.name \"Tu Nombre\"${NC}"
echo ""
echo "  3. Configura tu email SOLO para este repositorio:"
echo -e "     ${BLUE}git config --local user.email \"tu@email.com\"${NC}"
echo ""
echo "  4. Vuelve a esta carpeta y ejecuta el verificador:"
echo -e "     ${BLUE}./verify.sh${NC}"
echo ""
echo "Recuerda: usa --local, no --global. El valor local sobre-escribe"
echo "al global, que a su vez sobre-escribe al de --system."
echo ""
echo -e "${YELLOW}[i]${NC} Instrucciones completas en README.md"
echo -e "${YELLOW}[i]${NC} Si tu terminal no soporta colores, usa: ./init.sh --no-color"
