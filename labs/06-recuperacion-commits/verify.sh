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

# NOTE (steps mutuamente excluyentes):
# - Step 1 y steps 2+: el step 1 valida el estado inicial (main con 4
#   commits), que el step 2 destruye (main pasa a 6 commits). Por eso el
#   step 1 solo se verifica con target 1.
# - Step 2 y step 3: el step 2 deja el healthcheck commiteado en main (6
#   commits). El step 3 lo borra con `git reset --hard main~2` (main
#   vuelve a 4 commits). Cuando el target es 3 o mayor (o en la corrida
#   completa), el estado del step 2 ya no existe y no debe re-verificarse:
#   se verifica el estado del step 3. Con target 2, cuando el healthcheck
#   sigue en main, se verifica el step 2.
# - Los steps 3, 4 y 5 son acumulativos: los pasos posteriores solo crean
#   ramas y no destruyen el estado de los anteriores.

RUN_STEP1=0; RUN_STEP2=0; RUN_STEP3=0; RUN_STEP4=0; RUN_STEP5=0
if [ -z "$TARGET" ]; then
  RUN_STEP3=1; RUN_STEP4=1; RUN_STEP5=1
else
  if [ "$TARGET" -eq 1 ]; then RUN_STEP1=1; fi
  if [ "$TARGET" -eq 2 ]; then RUN_STEP2=1; fi
  if [ "$TARGET" -ge 3 ]; then RUN_STEP3=1; fi
  if [ "$TARGET" -ge 4 ]; then RUN_STEP4=1; fi
  if [ "$TARGET" -ge 5 ]; then RUN_STEP5=1; fi
fi

check_step1() {
  [ "$(git rev-list --count main 2>/dev/null)" = "4" ] \
    && [ -z "$(git status --porcelain 2>/dev/null)" ]
}

check_step2() {
  [ "$(git rev-list --count main 2>/dev/null)" = "6" ] \
    && contains_marker "HEAD" "conf.d/tienda.conf" "location /health"
}

check_step3() {
  [ "$(git rev-list --count main 2>/dev/null)" = "4" ] \
    && [ -z "$(git status --porcelain 2>/dev/null)" ] \
    && ! contains_marker "HEAD" "conf.d/tienda.conf" "location /health"
}

check_step4() {
  git show-ref --verify -q refs/heads/recuperado-reflog \
    && [ "$(git rev-list --count main..recuperado-reflog 2>/dev/null)" = "2" ] \
    && contains_marker "recuperado-reflog" "conf.d/tienda.conf" "location /health"
}

check_step5() {
  git show-ref --verify -q refs/heads/recuperado-fsck \
    && [ "$(git rev-list --count main..recuperado-fsck 2>/dev/null)" = "1" ] \
    && contains_marker "recuperado-fsck" "nginx.conf" "limit_req_zone"
}

if [ "$RUN_STEP1" = "1" ]; then
  run_check "(step 1) main con 4 commits y working tree limpio" check_step1
fi
if [ "$RUN_STEP2" = "1" ]; then
  run_check "(step 2) Healthcheck commiteado en main (6 commits)" check_step2
fi
if [ "$RUN_STEP3" = "1" ]; then
  run_check "(step 3) Commits perdidos: main con 4 commits y sin healthcheck" check_step3
fi
if [ "$RUN_STEP4" = "1" ]; then
  run_check "(step 4) Rama recuperado-reflog con los 2 commits perdidos" check_step4
fi
if [ "$RUN_STEP5" = "1" ]; then
  run_check "(step 5) Rama recuperado-fsck con el commit del rate limiting" check_step5
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
