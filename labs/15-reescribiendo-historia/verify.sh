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

# NOTE (cantidad de commits por target, no acumulativo):
# La cantidad de commits cambia con los steps: 9 tras init/amend/reword,
# 8 tras el squash, 7 tras el drop y 8 tras el split. Por eso el check de
# conteo solo se ejecuta con el valor esperado para el target pedido, en vez
# de intentar verificar los conteos intermedios en corridas posteriores.
# Los demas checks (contenido de archivos committeados, ausencia de typos o
# del commit de debug, orden endpoint/test, split) dejan rastro persistente
# y se acumulan sin invalidarse entre si.

count_commits() {
  git rev-list --count HEAD 2>/dev/null
}

chk_count() {
  local esperado="$1"
  [ "$(count_commits)" = "$esperado" ]
}

chk_editor() {
  local editor
  editor="$(git config --local core.editor 2>/dev/null)"
  [ -n "$editor" ] && case "$editor" in
    *code*) return 0 ;;
  esac
  return 1
}

chk_tree_limpio() {
  [ -z "$(git status --porcelain 2>/dev/null)" ]
}

chk_init_py() {
  git cat-file -e HEAD:tests/__init__.py 2>/dev/null
}

chk_typo_ausente() {
  local texto="$1"
  local msgs
  msgs="$(git log --all --format=%s 2>/dev/null)"
  case "$msgs" in
    *"$texto"*) return 1 ;;
    *) return 0 ;;
  esac
}

chk_helper() {
  local contenido
  contenido="$(git show HEAD:tests/test_api.py 2>/dev/null)"
  case "$contenido" in
    *"def iniciar_servidor"*) ;;
    *) return 1 ;;
  esac
  case "$contenido" in
    *"iniciar_servidor(Handler)"*) ;;
    *) return 1 ;;
  esac
}

chk_debug_gone() {
  [ -z "$(git log --all -S'DEBUG:' --format=%H 2>/dev/null)" ]
}

commit_marcador() {
  local marcador="$1"
  local archivo="$2"
  git log --all --format=%H --reverse -S"$marcador" -- "$archivo" 2>/dev/null | head -n 1
}

chk_reorder_status() {
  local app test
  app="$(commit_marcador 'self.path == "/status"' app.py)"
  test="$(commit_marcador 'def test_status' tests/test_api.py)"
  [ -n "$app" ] && [ -n "$test" ] && git merge-base --is-ancestor "$app" "$test" 2>/dev/null
}

chk_split_version() {
  local app test
  app="$(commit_marcador 'self.path == "/version"' app.py)"
  test="$(commit_marcador 'def test_version' tests/test_api.py)"
  [ -n "$app" ] && [ -n "$test" ] && [ "$app" != "$test" ] \
    && git merge-base --is-ancestor "$app" "$test" 2>/dev/null
}

run_all() {
  local target="$1"
  case "$target" in
    1)
      run_check "(step 1) Editor configurado localmente" chk_editor
      run_check "(step 1) 9 commits en la rama" chk_count 9
      ;;
    2)
      run_check "(step 1) Editor configurado localmente" chk_editor
      run_check "(step 2) 9 commits en la rama" chk_count 9
      run_check "(step 2) tests/__init__.py dentro del ultimo commit" chk_init_py
      run_check "(step 2) Mensaje con typo integirdad corregido" chk_typo_ausente integirdad
      run_check "(step 2) Working tree limpio" chk_tree_limpio
      ;;
    3)
      run_check "(step 1) Editor configurado localmente" chk_editor
      run_check "(step 3) 9 commits en la rama" chk_count 9
      run_check "(step 2) tests/__init__.py dentro del ultimo commit" chk_init_py
      run_check "(step 2) Mensaje con typo integirdad corregido" chk_typo_ausente integirdad
      run_check "(step 3) Mensaje con typo endpooint corregido" chk_typo_ausente endpooint
      run_check "(step 3) Working tree limpio" chk_tree_limpio
      ;;
    4)
      run_check "(step 1) Editor configurado localmente" chk_editor
      run_check "(step 4) 8 commits en la rama" chk_count 8
      run_check "(step 2) tests/__init__.py dentro del ultimo commit" chk_init_py
      run_check "(step 2) Mensaje con typo integirdad corregido" chk_typo_ausente integirdad
      run_check "(step 3) Mensaje con typo endpooint corregido" chk_typo_ausente endpooint
      run_check "(step 4) Helper definido y usado en el commit fusionado" chk_helper
      run_check "(step 4) Working tree limpio" chk_tree_limpio
      ;;
    5)
      run_check "(step 1) Editor configurado localmente" chk_editor
      run_check "(step 5) 7 commits en la rama" chk_count 7
      run_check "(step 2) tests/__init__.py dentro del ultimo commit" chk_init_py
      run_check "(step 2) Mensaje con typo integirdad corregido" chk_typo_ausente integirdad
      run_check "(step 3) Mensaje con typo endpooint corregido" chk_typo_ausente endpooint
      run_check "(step 4) Helper definido y usado en el commit fusionado" chk_helper
      run_check "(step 5) Commit de debug eliminado de la historia" chk_debug_gone
      run_check "(step 5) Endpoint /status antes que su test" chk_reorder_status
      run_check "(step 5) Working tree limpio" chk_tree_limpio
      ;;
    6)
      run_check "(step 1) Editor configurado localmente" chk_editor
      run_check "(step 6) 8 commits en la rama" chk_count 8
      run_check "(step 2) tests/__init__.py dentro del ultimo commit" chk_init_py
      run_check "(step 2) Mensaje con typo integirdad corregido" chk_typo_ausente integirdad
      run_check "(step 3) Mensaje con typo endpooint corregido" chk_typo_ausente endpooint
      run_check "(step 4) Helper definido y usado en el commit fusionado" chk_helper
      run_check "(step 5) Commit de debug eliminado de la historia" chk_debug_gone
      run_check "(step 5) Endpoint /status antes que su test" chk_reorder_status
      run_check "(step 6) Endpoint /version separado de su test" chk_split_version
      run_check "(step 6) Working tree limpio" chk_tree_limpio
      ;;
  esac
}

if [ -z "$TARGET" ]; then
  run_all 6
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
