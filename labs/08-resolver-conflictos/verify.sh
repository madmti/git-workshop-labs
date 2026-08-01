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

usage() {
  printf "Uso: %s [N]\n" "$0"
  printf "  Sin argumentos: corre todos los steps.\n"
  printf "  N: corre los steps aplicables hasta el step N (1-5).\n"
  exit 2
}

ARGS=()
for a in "$@"; do
  [ "$a" = "--no-color" ] && continue
  ARGS+=("$a")
done
TARGET=""
case "${#ARGS[@]}" in
  0) ;;
  1)
    case "${ARGS[0]}" in
      [1-5]) TARGET="${ARGS[0]}" ;;
      *) usage ;;
    esac
    ;;
  *) usage ;;
esac

if [ ! -d "$REPO_DIR/.git" ]; then
  printf "${RED}[x]${NC} No existe %s/.git. Corre ./init.sh primero.\n" "$REPO_DIR"
  exit 1
fi

cd "$REPO_DIR"

PASS=0
FAIL=0

run_check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf "${GREEN}[OK]${NC} %s\n" "$label"
    PASS=$((PASS + 1))
  else
    printf "${RED}[x]${NC} %s\n" "$label"
    FAIL=$((FAIL + 1))
  fi
}

contains_working_marker() {
  local path="$1"
  local marker="$2"
  local content
  content="$(cat "$path" 2>/dev/null || true)"
  [[ "$content" == *"$marker"* ]]
}

# NOTE (steps transitorios, mutuamente excluyentes):
# - Step 1 (conflicto activo: marcadores en el archivo) lo destruye el
#   step 3 (al resolver, los marcadores desaparecen). Solo valido en T=1/T=2.
# - Step 2 (leer el conflicto) es observacional, no deja estado: no tiene
#   check propio.
# - Step 3 (resuelto pero sin git add: sin marcadores y aun unmerged) lo
#   destruye el step 4 (git add + git commit vacia el indice unmerged).
#   Solo valido en T=3.
# - Steps 4 y 5 dejan estado permanente y se verifican en T=4/T=5/corrida
#   completa.

RUN_S1=0; RUN_S3=0; RUN_S4_MERGE=0; RUN_S4_CLEAN=0; RUN_S5=0
if [ -z "$TARGET" ]; then
  RUN_S4_MERGE=1; RUN_S4_CLEAN=1; RUN_S5=1
else
  case "$TARGET" in
    1) RUN_S1=1 ;;
    2) RUN_S1=1 ;;
    3) RUN_S3=1 ;;
    4) RUN_S4_MERGE=1; RUN_S4_CLEAN=1 ;;
    5) RUN_S4_MERGE=1; RUN_S4_CLEAN=1; RUN_S5=1 ;;
  esac
fi

check_step1() {
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "main" ] \
    && [ -n "$(git ls-files -u 2>/dev/null)" ] \
    && contains_working_marker "css/estilos.css" "<<<<<<< HEAD" \
    && contains_working_marker "css/estilos.css" "=======" \
    && contains_working_marker "css/estilos.css" ">>>>>>> feat/header-v2"
}

check_step3() {
  [ -n "$(git ls-files -u 2>/dev/null)" ] \
    && ! contains_working_marker "css/estilos.css" "<<<<<<< HEAD" \
    && ! contains_working_marker "css/estilos.css" "=======" \
    && ! contains_working_marker "css/estilos.css" ">>>>>>> feat/header-v2"
}

check_step4_merge() {
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "main" ] \
    && [ -z "$(git ls-files -u 2>/dev/null)" ] \
    && [ "$(git show -s --format=%P HEAD 2>/dev/null | wc -w)" = "2" ]
}

check_step4_clean() {
  [ -z "$(git status --porcelain 2>/dev/null)" ]
}

check_step5() {
  ! git show-ref --verify -q refs/heads/feat/header-v2 \
    && ! git show-ref --verify -q refs/heads/exp/colores \
    && [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "main" ]
}

if [ "$RUN_S1" = "1" ]; then
  run_check "(step 1) Conflicto activo en css/estilos.css con marcadores" check_step1
fi
if [ "$RUN_S3" = "1" ]; then
  run_check "(step 3) Conflicto resuelto sin marcadores y sin git add aun" check_step3
fi
if [ "$RUN_S4_MERGE" = "1" ]; then
  run_check "(step 4) Merge commit con 2 padres y conflicto marcado como resuelto" check_step4_merge
fi
if [ "$RUN_S4_CLEAN" = "1" ]; then
  run_check "(step 4) Working tree limpio" check_step4_clean
fi
if [ "$RUN_S5" = "1" ]; then
  run_check "(step 5) Ramas gestionadas: solo queda main" check_step5
fi

TOTAL=$((PASS + FAIL))
if [ -z "$TARGET" ]; then
  printf "\n%s/%s checks superados\n" "$PASS" "$TOTAL"
else
  printf "\n%s/%s checks superados (hasta el step %s)\n" "$PASS" "$TOTAL" "$TARGET"
fi
if [ "$FAIL" -eq 0 ]; then
  printf "${GREEN}[OK]${NC} Todo listo.\n"
  exit 0
else
  printf "${RED}[x]${NC} Hay checks pendientes.\n"
  exit 1
fi
