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
  printf "  N: corre los steps aplicables hasta el step N (1-6).\n"
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
      [1-6]) TARGET="${ARGS[0]}" ;;
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

has_file() {
  local ref="$1"
  local path="$2"
  git cat-file -e "$ref:$path" 2>/dev/null
}

# NOTE (steps transitorios, mutuamente excluyentes):
# Los estados de los steps 2 y 4 los destruyen steps posteriores:
# - Step 2 (experiment reaplicada en serie sobre master, HEAD en experiment):
#   lo invalida el step 3 (master hace fast-forward y experiment se borra).
# - Step 4 (client reaplicada sobre master, 1 commit adelante): lo invalida el
#   step 5 (master hace fast-forward hasta client y ambas quedan en la misma
#   punta).
# Por eso cada uno se verifica solo en su ventana valida. El resto de los
# steps deja estado persistente (alias, contenido integrado en master, ramas
# borradas) y se verifica de forma acumulativa en cada target posterior.

RUN_S1=0; RUN_S2=0; RUN_S3=0; RUN_S4=0; RUN_S5=0; RUN_S6=0
if [ -z "$TARGET" ]; then
  RUN_S1=1; RUN_S3=1; RUN_S5=1; RUN_S6=1
else
  case "$TARGET" in
    1) RUN_S1=1 ;;
    2) RUN_S1=1; RUN_S2=1 ;;
    3) RUN_S1=1; RUN_S3=1 ;;
    4) RUN_S1=1; RUN_S3=1; RUN_S4=1 ;;
    5) RUN_S1=1; RUN_S3=1; RUN_S5=1 ;;
    6) RUN_S1=1; RUN_S3=1; RUN_S5=1; RUN_S6=1 ;;
  esac
fi

check_step1() {
  [ "$(git config --local alias.lg 2>/dev/null)" = "log --oneline --graph --decorate" ]
}

check_step2() {
  [ "$(git rev-list --count master..experiment 2>/dev/null)" = "1" ] \
    && [ "$(git rev-list --count experiment..master 2>/dev/null)" = "0" ] \
    && [ "$(git rev-parse experiment^ 2>/dev/null)" = "$(git rev-parse master 2>/dev/null)" ] \
    && has_file experiment search.py
}

check_step3() {
  ! git show-ref --verify -q refs/heads/experiment \
    && has_file master search.py \
    && [ "$(git show -s --format=%P master 2>/dev/null | wc -w)" = "1" ]
}

check_step4() {
  [ "$(git rev-list --count master..client 2>/dev/null)" = "1" ] \
    && [ "$(git rev-list --count client..master 2>/dev/null)" = "0" ] \
    && [ "$(git rev-parse client^ 2>/dev/null)" = "$(git rev-parse master 2>/dev/null)" ] \
    && ! git merge-base --is-ancestor master server 2>/dev/null \
    && has_file client client.py
}

check_step5() {
  has_file master client.py \
    && [ "$(git show -s --format=%P master 2>/dev/null | wc -w)" = "1" ]
}

check_step6() {
  ! git show-ref --verify -q refs/heads/experiment \
    && ! git show-ref --verify -q refs/heads/client \
    && ! git show-ref --verify -q refs/heads/server \
    && [ "$(git rev-list --count master 2>/dev/null)" = "6" ] \
    && [ "$(git rev-list --count --first-parent master 2>/dev/null)" = "6" ] \
    && [ "$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)" = "master" ] \
    && has_file master main.py \
    && has_file master requirements.txt \
    && has_file master README.md \
    && has_file master config.py \
    && has_file master search.py \
    && has_file master server.py \
    && has_file master client.py \
    && [ -z "$(git status --porcelain 2>/dev/null)" ] \
    && [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = "master" ]
}

if [ "$RUN_S1" = "1" ]; then
  run_check "(step 1) Alias lg configurado a nivel local" check_step1
fi
if [ "$RUN_S2" = "1" ]; then
  run_check "(step 2) experiment reaplicada en serie sobre master" check_step2
fi
if [ "$RUN_S3" = "1" ]; then
  run_check "(step 3) master con fast-forward y experiment borrada" check_step3
fi
if [ "$RUN_S4" = "1" ]; then
  run_check "(step 4) client reaplicada sobre master sin arrastrar server" check_step4
fi
if [ "$RUN_S5" = "1" ]; then
  run_check "(step 5) client integrada en master con fast-forward" check_step5
fi
if [ "$RUN_S6" = "1" ]; then
  run_check "(step 6) Historial final lineal de 6 commits y ramas limpias" check_step6
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
