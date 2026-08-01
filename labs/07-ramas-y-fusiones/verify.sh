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

contains_marker() {
  local ref="$1"
  local path="$2"
  local marker="$3"
  local content
  content="$(git show "$ref:$path" 2>/dev/null || true)"
  [[ "$content" == *"$marker"* ]]
}

# NOTE (steps transitorios, mutuamente excluyentes):
# Los estados de los steps 1, 2 y 4 los destruyen steps posteriores:
# - Step 1 (HEAD en iss53): lo invalida el step 2 (pasamos a hotfix).
# - Step 2 (HEAD en hotfix, rama hotfix): lo invalida el step 3 (hotfix se
#   fusiona y se borra).
# - Step 3 (main sin merge commit, punta lineal): lo invalida el step 5 (se
#   crea un merge commit de 2 padres).
# - Step 4 (HEAD en iss53, 2 commits adelante): lo invalida el step 5 (iss53
#   se borra).
# Por eso cada uno se verifica solo en su ventana valida, y la corrida
# completa (o target 5) verifica solo el estado final: merge commit con 2
# padres, ramas borradas, contenidos fusionados y working tree limpio.

RUN_S1=0; RUN_S2=0; RUN_S3=0; RUN_S4=0; RUN_S5_MERGE=0; RUN_S5_CONTENT=0; RUN_S5_CLEAN=0
if [ -z "$TARGET" ]; then
  RUN_S5_MERGE=1; RUN_S5_CONTENT=1; RUN_S5_CLEAN=1
else
  case "$TARGET" in
    1) RUN_S1=1 ;;
    2) RUN_S2=1 ;;
    3) RUN_S3=1 ;;
    4) RUN_S3=1; RUN_S4=1 ;;
    5) RUN_S5_MERGE=1; RUN_S5_CONTENT=1; RUN_S5_CLEAN=1 ;;
  esac
fi

check_step1() {
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "iss53" ] \
    && [ "$(git rev-list --count main..iss53 2>/dev/null)" = "1" ] \
    && contains_marker "iss53" "index.html" "<footer>"
}

check_step2() {
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "hotfix" ] \
    && [ "$(git rev-list --count main..hotfix 2>/dev/null)" = "1" ] \
    && contains_marker "hotfix" "index.html" "support@github.com" \
    && ! contains_marker "hotfix" "index.html" "email.support"
}

check_step3() {
  ! git show-ref --verify -q refs/heads/hotfix \
    && contains_marker "main" "index.html" "support@github.com" \
    && ! contains_marker "main" "index.html" "email.support" \
    && [ "$(git rev-list --count iss53..main 2>/dev/null)" = "1" ] \
    && [ "$(git show -s --format=%P main 2>/dev/null | wc -w)" = "1" ]
}

check_step4() {
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "iss53" ] \
    && [ "$(git rev-list --count main..iss53 2>/dev/null)" = "2" ] \
    && contains_marker "iss53" "index.html" "2026 Tienda Online"
}

check_step5_merge() {
  [ "$(git show -s --format=%P HEAD 2>/dev/null | wc -w)" = "2" ] \
    && ! git show-ref --verify -q refs/heads/iss53 \
    && ! git show-ref --verify -q refs/heads/hotfix
}

check_step5_content() {
  contains_marker "HEAD" "index.html" "support@github.com" \
    && ! contains_marker "HEAD" "index.html" "email.support" \
    && contains_marker "HEAD" "index.html" "2026 Tienda Online" \
    && contains_marker "HEAD" "index.html" "<footer>"
}

check_step5_clean() {
  [ -z "$(git status --porcelain 2>/dev/null)" ]
}

if [ "$RUN_S1" = "1" ]; then
  run_check "(step 1) Rama iss53 creada y footer committeado" check_step1
fi
if [ "$RUN_S2" = "1" ]; then
  run_check "(step 2) Rama hotfix con el email corregido" check_step2
fi
if [ "$RUN_S3" = "1" ]; then
  run_check "(step 3) hotfix fusionado en main (fast-forward) y borrado" check_step3
fi
if [ "$RUN_S4" = "1" ]; then
  run_check "(step 4) iss53 con el copyright committeado" check_step4
fi
if [ "$RUN_S5_MERGE" = "1" ]; then
  run_check "(step 5) Merge commit con 2 padres y ramas borradas" check_step5_merge
fi
if [ "$RUN_S5_CONTENT" = "1" ]; then
  run_check "(step 5) Contenidos del footer y del hotfix fusionados en main" check_step5_content
fi
if [ "$RUN_S5_CLEAN" = "1" ]; then
  run_check "(step 5) Working tree limpio" check_step5_clean
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
