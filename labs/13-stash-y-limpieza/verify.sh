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

# NOTE (steps transitorios, mutuamente excluyentes):
# Varios steps dejan estados que un step posterior destruye a proposito, por
# eso no se pueden verificar todos en una corrida que llega al final:
# - Step 1 (existe un stash + tree de tracked limpio): lo invalida el step 4
#   (git stash apply devuelve los cambios al working tree) y el step 5
#   (git stash drop elimina el stash). Se verifica solo para targets 1-3.
# - Step 2 (basura untracked eliminada + ignorados AUN presentes): lo
#   invalida el step 3 (git clean -x elimina tambien los ignorados). Se
#   verifica solo para target 2.
# - Step 4 (el stash sigue en la lista + cambios restaurados en el tree): lo
#   invalida el step 5 (drop + commit dejan el repositorio limpio). Se
#   verifica solo para target 4.
# Los steps 3 y 5 dejan estado persistente (basura e ignorados eliminados,
# commit con el contenido del trabajo recuperado) y se verifican de forma
# acumulativa en cada target posterior.

check_s1a() {
  [ -n "$(git stash list 2>/dev/null)" ]
}

check_s1b() {
  local out linea
  out="$(git status --porcelain 2>/dev/null)"
  while IFS= read -r linea; do
    case "$linea" in
      "?? "*) ;;
      "") ;;
      *) return 1 ;;
    esac
  done <<EOF
$out
EOF
}

check_s2() {
  [ ! -e debug.log ] && [ ! -e notas.txt ] && [ ! -d tmp ] \
    && [ -d build ] && [ -e cache.tmp ]
}

check_s3() {
  [ ! -d build ] && [ ! -e cache.tmp ] && [ ! -e debug.log ] \
    && [ ! -e notas.txt ] && [ ! -d tmp ]
}

check_s4a() {
  [ -n "$(git stash list 2>/dev/null)" ]
}

check_s4b() {
  local out
  out="$(git diff --name-only 2>/dev/null)"
  case "$out" in
    *compiler.py*) ;;
    *) return 1 ;;
  esac
  case "$out" in
    *src/guia.txt*) ;;
    *) return 1 ;;
  esac
}

check_s5a() {
  [ -z "$(git stash list 2>/dev/null)" ]
}

check_s5b() {
  [ -z "$(git status --porcelain 2>/dev/null)" ]
}

check_s5c() {
  local out
  out="$(git show HEAD:compiler.py 2>/dev/null)"
  case "$out" in
    *sitemap.txt*) ;;
    *) return 1 ;;
  esac
  out="$(git show HEAD:src/guia.txt 2>/dev/null)"
  case "$out" in
    *"Guia actualizada del taller"*) ;;
    *) return 1 ;;
  esac
}

case "$TARGET" in
  "")
    run_check "(step 3) Basura e ignorados eliminados" check_s3
    run_check "(step 5) No queda ningun stash" check_s5a
    run_check "(step 5) Working tree limpio" check_s5b
    run_check "(step 5) Commit con el trabajo recuperado" check_s5c
    ;;
  1)
    run_check "(step 1) Existe un stash" check_s1a
    run_check "(step 1) Working tree de archivos con seguimiento limpio" check_s1b
    ;;
  2)
    run_check "(step 1) Existe un stash" check_s1a
    run_check "(step 1) Working tree de archivos con seguimiento limpio" check_s1b
    run_check "(step 2) Basura untracked eliminada e ignorados intactos" check_s2
    ;;
  3)
    run_check "(step 1) Existe un stash" check_s1a
    run_check "(step 1) Working tree de archivos con seguimiento limpio" check_s1b
    run_check "(step 3) Basura e ignorados eliminados" check_s3
    ;;
  4)
    run_check "(step 3) Basura e ignorados eliminados" check_s3
    run_check "(step 4) El stash sigue en la lista tras el apply" check_s4a
    run_check "(step 4) Cambios restaurados en el working tree" check_s4b
    ;;
  5)
    run_check "(step 3) Basura e ignorados eliminados" check_s3
    run_check "(step 5) No queda ningun stash" check_s5a
    run_check "(step 5) Working tree limpio" check_s5b
    run_check "(step 5) Commit con el trabajo recuperado" check_s5c
    ;;
esac

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
