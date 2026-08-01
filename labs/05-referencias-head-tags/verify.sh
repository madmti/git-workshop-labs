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

SHA_GOOD="$(git rev-parse main~1 2>/dev/null || true)"
SHA_MAIN="$(git rev-parse main 2>/dev/null || true)"
if [ -z "$SHA_GOOD" ] || [ -z "$SHA_MAIN" ]; then
  printf "${RED}[x]${NC} No se pudo leer el historial de main (corre ./init.sh).\n"
  exit 1
fi

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

# NOTE (steps 1 y 3 mutuamente excluyentes):
# El step 1 deja HEAD apuntando a un sha suelto (detached). El step 3
# sobreescribe ese estado fijando HEAD a la rama investigacion con
# git symbolic-ref. Por lo tanto, cuando el target es 3 o mayor (o en la
# corrida completa), el estado detached del step 1 ya no existe y no debe
# re-verificarse: se verifica el estado final (HEAD en investigacion).
# Con target 1 o 2, cuando HEAD todavia esta suelto, se verifica el
# estado del step 1.

RUN_STEP1=0; RUN_STEP2=0; RUN_STEP3=0; RUN_STEP4=0; RUN_STEP5=0
if [ -z "$TARGET" ]; then
  RUN_STEP2=1; RUN_STEP3=1; RUN_STEP4=1; RUN_STEP5=1
else
  if [ "$TARGET" -le 2 ]; then RUN_STEP1=1; fi
  if [ "$TARGET" -ge 2 ]; then RUN_STEP2=1; fi
  if [ "$TARGET" -ge 3 ]; then RUN_STEP3=1; fi
  if [ "$TARGET" -ge 4 ]; then RUN_STEP4=1; fi
  if [ "$TARGET" -ge 5 ]; then RUN_STEP5=1; fi
fi

check_step1() {
  ! git symbolic-ref -q HEAD >/dev/null 2>&1 \
    && [ "$(git rev-parse HEAD 2>/dev/null)" = "$SHA_GOOD" ] \
    && git diff --quiet "$SHA_GOOD"
}

check_step2() {
  [ -f "$REPO_DIR/.git/refs/heads/investigacion" ] \
    && [ "$(git rev-parse refs/heads/investigacion 2>/dev/null)" = "$SHA_GOOD" ]
}

check_step3() {
  [ "$(git symbolic-ref HEAD 2>/dev/null)" = "refs/heads/investigacion" ] \
    && [ "$(git rev-parse HEAD 2>/dev/null)" = "$SHA_GOOD" ] \
    && git diff --quiet
}

check_step4() {
  [ -f "$REPO_DIR/.git/refs/tags/v0.1" ] \
    && [ "$(git cat-file -t v0.1 2>/dev/null)" = "commit" ] \
    && [ "$(git rev-parse v0.1^{} 2>/dev/null)" = "$SHA_GOOD" ]
}

check_step5() {
  [ -f "$REPO_DIR/.git/refs/tags/v0.2" ] \
    && [ "$(git cat-file -t v0.2 2>/dev/null)" = "tag" ] \
    && [ "$(git rev-parse v0.2^{} 2>/dev/null)" = "$SHA_MAIN" ]
}

if [ "$RUN_STEP1" = "1" ]; then
  run_check "(step 1) HEAD detached apuntando al commit bueno (main~1)" check_step1
fi
if [ "$RUN_STEP2" = "1" ]; then
  run_check "(step 2) Rama investigacion creada con git update-ref apuntando a main~1" check_step2
fi
if [ "$RUN_STEP3" = "1" ]; then
  run_check "(step 3) HEAD fijado con git symbolic-ref a la rama investigacion" check_step3
fi
if [ "$RUN_STEP4" = "1" ]; then
  run_check "(step 4) Etiqueta ligera v0.1 apuntando al commit bueno (main~1)" check_step4
fi
if [ "$RUN_STEP5" = "1" ]; then
  run_check "(step 5) Etiqueta anotada v0.2 con objeto tag apuntando a main" check_step5
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
