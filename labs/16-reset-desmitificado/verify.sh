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
  printf "  N: corre los steps aplicables hasta el step N (1-4).\n"
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
      [1-4]) TARGET="${ARGS[0]}" ;;
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

# NOTE (pasos que se invalidan entre si / sin rastro persistente):
# - El step 3 (`reset --hard HEAD`) descarta trabajo sin confirmar, asi que
#   no deja rastro persistente. Su unico check posible es que el working tree
#   y el indice queden limpios; eso no detecta a quien se salte el paso por
#   completo. Por eso es un check de estado, documentado como tal.
# - El step 4 (squash) reduce la historia de 4 a 3 commits. El check de
#   conteo (3 commits) solo corre cuando el target es 4: en corridas hacia
#   steps anteriores la historia tiene 4 commits y ese check fallaria. El
#   resto de los checks (contenido committeado, rama, arbol limpio) dejan
#   rastro persistente y se acumulan sin invalidarse entre si.

count_commits() {
  git rev-list --count HEAD 2>/dev/null
}

chk_count() {
  local esperado="$1"
  [ "$(count_commits)" = "$esperado" ]
}

chk_main() {
  [ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" = "main" ]
}

chk_tree_limpio() {
  [ -z "$(git status --porcelain 2>/dev/null)" ]
}

chk_contenido() {
  local archivo="$1"
  local marcador="$2"
  local contenido
  contenido="$(git show HEAD:"$archivo" 2>/dev/null)"
  case "$contenido" in
    *"$marcador"*) return 0 ;;
  esac
  return 1
}

chk_alerta() {
  local contenido
  contenido="$(git show HEAD:backup.conf 2>/dev/null)"
  case "$contenido" in
    ALERTA_EMAIL=*|*$'\n'ALERTA_EMAIL=*) return 0 ;;
  esac
  return 1
}

run_all() {
  local target="$1"
  case "$target" in
    1)
      run_check "(step 1) Repositorio en la rama main" chk_main
      run_check "(step 1) README committeado menciona la compresion gzip" chk_contenido README.md "compresion gzip"
      run_check "(step 1) backup.sh committeado usa compresion (tar -zcvf)" chk_contenido backup.sh "-zcvf"
      ;;
    2)
      run_check "(step 1) Repositorio en la rama main" chk_main
      run_check "(step 1) README committeado menciona la compresion gzip" chk_contenido README.md "compresion gzip"
      run_check "(step 1) backup.sh committeado usa compresion (tar -zcvf)" chk_contenido backup.sh "-zcvf"
      run_check "(step 2) backup.conf committeado activa la alerta por email" chk_alerta
      ;;
    3)
      run_check "(step 1) Repositorio en la rama main" chk_main
      run_check "(step 1) README committeado menciona la compresion gzip" chk_contenido README.md "compresion gzip"
      run_check "(step 1) backup.sh committeado usa compresion (tar -zcvf)" chk_contenido backup.sh "-zcvf"
      run_check "(step 2) backup.conf committeado activa la alerta por email" chk_alerta
      run_check "(step 3) Working tree e indice limpios" chk_tree_limpio
      ;;
    4)
      run_check "(step 1) Repositorio en la rama main" chk_main
      run_check "(step 1) README committeado menciona la compresion gzip" chk_contenido README.md "compresion gzip"
      run_check "(step 1) backup.sh committeado usa compresion (tar -zcvf)" chk_contenido backup.sh "-zcvf"
      run_check "(step 2) backup.conf committeado activa la alerta por email" chk_alerta
      run_check "(step 3) Working tree e indice limpios" chk_tree_limpio
      run_check "(step 4) Historia con 3 commits (squash aplicado)" chk_count 3
      ;;
  esac
}

if [ -z "$TARGET" ]; then
  run_all 4
else
  run_all "$TARGET"
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
