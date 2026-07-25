#!/usr/bin/env bash
set -uo pipefail

PROJECT_DIR="calculadora"
MAX_STEP=6
TARGET_STEP=$MAX_STEP

# --- Parseo de argumentos y color -------------------------------------
# ./verify.sh          -> corre todos los steps (1 al 6)
# ./verify.sh 3         -> corre los steps 1, 2 y 3 (acumulativo)
# ./verify.sh --no-color / COLORS=0 ./verify.sh -> desactiva color
USE_COLOR=1
[ "${COLORS:-1}" = "0" ] && USE_COLOR=0
[ -t 1 ] || USE_COLOR=0

for arg in "$@"; do
  case "$arg" in
    --no-color)
      USE_COLOR=0
      ;;
    ''|*[!0-9]*)
      echo "Argumento invalido: '$arg'"
      echo "Uso: ./verify.sh [1-$MAX_STEP] [--no-color]"
      exit 1
      ;;
    *)
      TARGET_STEP=$arg
      ;;
  esac
done

if [ "$TARGET_STEP" -lt 1 ] || [ "$TARGET_STEP" -gt "$MAX_STEP" ]; then
  echo "Step invalido: $TARGET_STEP (debe ser un numero entre 1 y $MAX_STEP)"
  exit 1
fi

if [ "$USE_COLOR" = "1" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi
# -----------------------------------------------------------------------

if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}[x]${NC} No se encontro la carpeta ./$PROJECT_DIR"
  echo "    ¿Ejecutaste ./init.sh primero?"
  exit 1
fi

print_ok()   { echo -e "${GREEN}[OK]${NC} (step $1) $2"; }
print_fail() { echo -e "${RED}[x]${NC} (step $1) $2"; }
print_hint() { echo "    $1"; }

has_git() { [ -d "$PROJECT_DIR/.git" ]; }

is_tracked() {
  # is_tracked <archivo>
  (cd "$PROJECT_DIR" && git ls-files 2>/dev/null | grep -qx "$1")
}

commit_count() {
  (cd "$PROJECT_DIR" && git rev-list --count HEAD 2>/dev/null) || echo 0
}

in_initial_commit() {
  # in_initial_commit <archivo>
  # Verifica si un archivo existia en el commit raiz (el primero)
  local root
  root=$(cd "$PROJECT_DIR" && git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
  [ -n "$root" ] && (cd "$PROJECT_DIR" && git ls-tree "$root" -- "$1" 2>/dev/null | grep -q .)
}

# --- Step 1: repositorio inicializado ---------------------------------
check_step1() {
  if has_git; then
    print_ok 1 "Repositorio Git inicializado"
    return 0
  fi
  print_fail 1 "No se encontro un repositorio Git en ./$PROJECT_DIR"
  print_hint "Ejecuta: cd $PROJECT_DIR && git init"
  return 1
}

# --- Step 2: commit inicial con los archivos semilla ------------------
check_step2() {
  if ! has_git; then
    print_fail 2 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local commits
  commits=$(commit_count)

  if [ "$commits" -lt 1 ]; then
    print_fail 2 "Falta el commit inicial"
    print_hint "Todavia no hay commits"
    return 1
  fi

  local missing=""
  for f in main.py operaciones.py operaciones_legacy.py utils.py README.md; do
    in_initial_commit "$f" || missing="$missing $f"
  done

  if [ -z "$missing" ]; then
    print_ok 2 "Commit inicial con los archivos semilla"
    return 0
  fi

  print_fail 2 "Falta el commit inicial o hay archivos sin trackear"
  print_hint "Archivos ausentes en el commit inicial:$missing"
  return 1
}

# --- Step 3: potencia() implementada -----------------------------------
check_step3() {
  if ! has_git; then
    print_fail 3 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local resultado="ERROR"
  if [ -f "$PROJECT_DIR/operaciones.py" ]; then
    resultado=$(cd "$PROJECT_DIR" && python3 -c "
from operaciones import potencia
print(potencia(2, 3))
" 2>/dev/null || echo "ERROR")
  fi

  local commits
  commits=$(commit_count)

  if [ "$commits" -ge 2 ] && [ "$resultado" = "8" ]; then
    print_ok 3 "potencia() implementada y confirmada"
    return 0
  fi

  print_fail 3 "potencia() no esta implementada correctamente, o falta el commit"
  [ "$resultado" != "8" ] && print_hint "potencia(2, 3) deberia retornar 8 (dio: $resultado)"
  [ "$commits" -lt 2 ] && print_hint "Debe haber al menos 2 commits"
  return 1
}

# --- Step 4: __pycache__/ ignorado -------------------------------------
check_step4() {
  if ! has_git; then
    print_fail 4 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local ignored=1
  (cd "$PROJECT_DIR" && git check-ignore -q "__pycache__/dummy.pyc") && ignored=0

  local gitignore_tracked=1
  is_tracked ".gitignore" && gitignore_tracked=0

  if [ "$ignored" -eq 0 ] && [ "$gitignore_tracked" -eq 0 ]; then
    print_ok 4 "__pycache__/ esta ignorado y .gitignore confirmado"
    return 0
  fi

  print_fail 4 "__pycache__/ no esta ignorado, o .gitignore no esta confirmado"
  [ "$ignored" -ne 0 ] && print_hint "Agrega __pycache__/ a un archivo .gitignore"
  [ "$gitignore_tracked" -ne 0 ] && print_hint "Confirma el archivo .gitignore con git add + git commit"
  return 1
}

# --- Step 5: operaciones_legacy.py eliminado ----------------------------
check_step5() {
  if ! has_git; then
    print_fail 5 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local exists_disk=1
  [ -f "$PROJECT_DIR/operaciones_legacy.py" ] && exists_disk=0

  local tracked=1
  is_tracked "operaciones_legacy.py" && tracked=0

  if [ "$exists_disk" -ne 0 ] && [ "$tracked" -ne 0 ]; then
    print_ok 5 "operaciones_legacy.py eliminado"
    return 0
  fi

  print_fail 5 "operaciones_legacy.py todavia existe en disco o en el indice"
  print_hint "Ejecuta: git rm operaciones_legacy.py, luego confirma el cambio"
  return 1
}

# --- Step 6: utils.py renombrado a helpers.py ----------------------------
check_step6() {
  if ! has_git; then
    print_fail 6 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local helpers_tracked=1
  is_tracked "helpers.py" && helpers_tracked=0

  local utils_gone=1
  [ -f "$PROJECT_DIR/utils.py" ] && utils_gone=0

  local utils_tracked=1
  is_tracked "utils.py" && utils_tracked=0

  if [ "$helpers_tracked" -eq 0 ] && [ "$utils_gone" -ne 0 ] && [ "$utils_tracked" -ne 0 ]; then
    print_ok 6 "utils.py renombrado a helpers.py"
    return 0
  fi

  print_fail 6 "Falta renombrar utils.py a helpers.py"
  print_hint "Ejecuta: git mv utils.py helpers.py, luego confirma el cambio"
  return 1
}

# --- Ejecucion -----------------------------------------------------------
echo "Verificando Lab 02: Flujo basico de Git"
echo "-----------------------------------------------------"

PASS=0
for step in $(seq 1 "$TARGET_STEP"); do
  if "check_step${step}"; then
    PASS=$((PASS + 1))
  fi
done

echo "-----------------------------------------------------"
if [ "$TARGET_STEP" -eq "$MAX_STEP" ]; then
  echo "$PASS/$TARGET_STEP checks superados"
else
  echo "$PASS/$TARGET_STEP checks superados (hasta el step $TARGET_STEP)"
fi

if [ "$PASS" -eq "$TARGET_STEP" ]; then
  echo -e "${GREEN}[OK]${NC} Todo correcto hasta el step $TARGET_STEP"
  exit 0
else
  echo -e "${RED}[x]${NC} Todavia faltan cosas por completar."
  exit 1
fi
