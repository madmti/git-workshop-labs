#!/usr/bin/env bash
set -u
# Nota: NO se usa 'pipefail' a proposito -- combinado con 'comando | grep -q'
# puede fallar de forma intermitente por una condicion de carrera con SIGPIPE.

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$LAB_DIR/calculadora"
BARE_DIR="$LAB_DIR/remoto-calculadora.git"
MAX_STEP=6
TARGET_STEP=$MAX_STEP

# --- Parseo de argumentos y color -------------------------------------
# ./verify.sh          -> corre todos los checks aplicables
# ./verify.sh 3         -> corre los checks aplicables hasta el step 3
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
  echo -e "${RED}[x]${NC} No se encontro la carpeta ./calculadora"
  echo "    ¿Ejecutaste ./init.sh primero?"
  exit 1
fi

print_ok()   { echo -e "${GREEN}[OK]${NC} (step $1) $2"; }
print_fail() { echo -e "${RED}[x]${NC} (step $1) $2"; }
print_hint() { echo "    $1"; }

has_git() { [ -d "$PROJECT_DIR/.git" ]; }

is_tracked() {
  # is_tracked <archivo>  (evita pipes con grep; compara linea por linea)
  local f
  while IFS= read -r f; do
    [ "$f" = "$1" ] && return 0
  done < <(cd "$PROJECT_DIR" && git ls-files 2>/dev/null)
  return 1
}

log_contains() {
  # log_contains <patron-case-insensitive-simple>
  local log_output
  log_output=$(cd "$PROJECT_DIR" && git log --oneline 2>/dev/null)
  local lower_log lower_pat
  lower_log=$(printf '%s' "$log_output" | tr '[:upper:]' '[:lower:]')
  lower_pat=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$lower_log" in
    *"$lower_pat"*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Step 1: alias locales ---------------------------------------------
check_step1() {
  if ! has_git; then
    print_fail 1 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local keys="st ci last unstage lg"
  local expected_st="status"
  local expected_ci="commit"
  local expected_last="log -1 HEAD"
  local expected_unstage="restore --staged"
  local expected_lg="log --oneline --graph --all --decorate"

  local missing=""
  for key in $keys; do
    local expected_var="expected_$key"
    local expected_val="${!expected_var}"
    local val
    val=$(cd "$PROJECT_DIR" && git config --local --get "alias.$key" 2>/dev/null)
    [ "$val" = "$expected_val" ] || missing="$missing $key"
  done

  if [ -z "$missing" ]; then
    print_ok 1 "Los 5 alias locales estan configurados correctamente"
    return 0
  fi

  print_fail 1 "Faltan o estan mal configurados estos alias:$missing"
  print_hint "Revisa el step 1 del README"
  return 1
}

# --- Step 2: remoto conectado + cambios integrados -----------------------
check_step2() {
  if ! has_git; then
    print_fail 2 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local origin_url
  origin_url=$(cd "$PROJECT_DIR" && git config --local --get remote.origin.url 2>/dev/null)

  local changelog_tracked=1
  is_tracked "CHANGELOG.md" && changelog_tracked=0

  local changelog_in_log=1
  log_contains "changelog" && changelog_in_log=0

  if [ -n "$origin_url" ] && [ "$changelog_tracked" -eq 0 ] && [ "$changelog_in_log" -eq 0 ]; then
    print_ok 2 "Remoto conectado y cambios del compañero integrados"
    return 0
  fi

  print_fail 2 "Falta conectar el remoto, o traer/integrar los cambios"
  [ -z "$origin_url" ] && print_hint "Ejecuta: git remote add origin ../remoto-calculadora.git"
  [ "$changelog_in_log" -ne 0 ] && print_hint "Trae los cambios con: git fetch origin && git merge origin/main (o git pull origin main)"
  return 1
}

# --- Step 3: archivo preparado -> deshecho (solo si NO se ha hecho el step 4) --
# Este check solo tiene sentido mientras el archivo siga modificado y sin
# preparar. Si ya se descarto el cambio (step 4), ya no hay nada que
# verificar aca -- ese caso lo cubre directamente check_step4.
check_step3() {
  if ! has_git; then
    print_fail 3 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local staged unstaged_diff
  staged=$(cd "$PROJECT_DIR" && git diff --cached --name-only -- README.md 2>/dev/null)
  unstaged_diff=$(cd "$PROJECT_DIR" && git diff -- README.md 2>/dev/null)

  if [ -z "$staged" ] && [ -n "$unstaged_diff" ]; then
    print_ok 3 "README.md quedo modificado y sin preparar"
    return 0
  fi

  print_fail 3 "README.md no esta en el estado esperado (modificado, sin preparar)"
  [ -n "$staged" ] && print_hint "Todavia esta preparado -- ejecuta: git unstage README.md"
  [ -z "$unstaged_diff" ] && print_hint "No hay ningun cambio en README.md. Sigue el step 3 del README"
  return 1
}

# --- Step 4: cambio descartado por completo -------------------------------
# Este check reemplaza al del step 3 una vez que se pide verificar hasta
# aca: si el alumno ya avanzo hasta este punto, lo unico que importa es
# el estado final (archivo identico al ultimo commit).
check_step4() {
  if ! has_git; then
    print_fail 4 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  local diffs
  diffs=$(cd "$PROJECT_DIR" && git diff -- README.md 2>/dev/null)

  if [ -z "$diffs" ]; then
    print_ok 4 "README.md coincide con el ultimo commit"
    return 0
  fi

  print_fail 4 "README.md todavia tiene cambios sin descartar"
  print_hint "Ejecuta: git restore README.md"
  return 1
}

# --- Step 5: raiz_cuadrada() + commit --amend -----------------------------
check_step5() {
  if ! has_git; then
    print_fail 5 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  # Commits esperados: 5 del proyecto semilla + 1 del companero (CHANGELOG,
  # ya presentes en el remoto desde que corriste init.sh) + 1 tuyo (la nueva
  # funcion, ya sea que la hayas confirmado en un commit nuevo o enmendado
  # el anterior -- en ambos casos el total debe ser 7, nunca 8).
  local total_commits expected_total=7
  total_commits=$(cd "$PROJECT_DIR" && git rev-list --count HEAD 2>/dev/null)
  [ -z "$total_commits" ] && total_commits=0

  # Se verifica el contenido YA CONFIRMADO (HEAD), no el working tree --
  # asi el check falla de verdad si olvidaste hacer commit/amend, en vez
  # de pasar solo porque el archivo en disco se ve bien.
  local TMP_CHECK
  TMP_CHECK=$(mktemp -d)
  (cd "$PROJECT_DIR" && git show HEAD:operaciones.py) > "$TMP_CHECK/operaciones.py" 2>/dev/null
  (cd "$PROJECT_DIR" && git show HEAD:main.py) > "$TMP_CHECK/main.py" 2>/dev/null
  (cd "$PROJECT_DIR" && git show HEAD:helpers.py) > "$TMP_CHECK/helpers.py" 2>/dev/null

  local func_ok="ERROR"
  if [ -s "$TMP_CHECK/operaciones.py" ]; then
    func_ok=$(cd "$TMP_CHECK" && python3 -c "
from operaciones import raiz_cuadrada
print(raiz_cuadrada(9))
" 2>/dev/null)
    [ -z "$func_ok" ] && func_ok="ERROR"
  fi

  local wired_ok="NO"
  if [ -s "$TMP_CHECK/main.py" ] && [ -s "$TMP_CHECK/helpers.py" ]; then
    wired_ok=$(cd "$TMP_CHECK" && python3 -c "
import main
from operaciones import raiz_cuadrada
print('SI' if any(fn is raiz_cuadrada for _, fn in main.OPCIONES.values()) else 'NO')
" 2>/dev/null)
    [ -z "$wired_ok" ] && wired_ok="ERROR"
  fi

  rm -rf "$TMP_CHECK"

  if [ "$total_commits" -eq "$expected_total" ] && [ "$func_ok" = "3.0" ] && [ "$wired_ok" = "SI" ]; then
    print_ok 5 "raiz_cuadrada() implementada, conectada al CLI, y confirmada (commit --amend)"
    return 0
  fi

  print_fail 5 "Falta completar raiz_cuadrada(), conectarla, confirmarla, o el amend no quedo bien"
  [ "$func_ok" != "3.0" ] && print_hint "En tu ultimo commit, operaciones.py no tiene raiz_cuadrada() funcionando (dio: $func_ok)"
  [ "$wired_ok" != "SI" ] && print_hint "En tu ultimo commit, main.py no tiene raiz_cuadrada conectada en OPCIONES"
  if [ "$total_commits" -gt "$expected_total" ]; then
    print_hint "Hay mas commits de los esperados -- usa 'git commit --amend', no un commit nuevo"
  elif [ "$total_commits" -lt "$expected_total" ] && [ "$func_ok" = "3.0" ]; then
    print_hint "El codigo se ve bien en disco, pero no esta confirmado -- revisa si hiciste git add + git commit/--amend"
  fi
  return 1
}

# --- Step 6: push al remoto ------------------------------------------------
check_step6() {
  if ! has_git; then
    print_fail 6 "No se puede verificar (todavia no hay repositorio Git)"
    return 1
  fi

  if [ ! -d "$BARE_DIR" ]; then
    print_fail 6 "No se encontro el repositorio remoto ./remoto-calculadora.git"
    return 1
  fi

  local local_head remote_head
  local_head=$(cd "$PROJECT_DIR" && git rev-parse main 2>/dev/null)
  remote_head=$(git --git-dir="$BARE_DIR" rev-parse main 2>/dev/null)

  if [ -n "$local_head" ] && [ "$local_head" = "$remote_head" ]; then
    print_ok 6 "El remoto esta sincronizado con tu historial local"
    return 0
  fi

  print_fail 6 "El remoto no coincide con tu historial local"
  print_hint "Ejecuta: git push origin main"
  return 1
}

# --- Armar la lista de checks aplicables para el target pedido ------------
# Los steps 3 y 4 son mutuamente excluyentes: el 4 revierte lo que el 3
# dejo, asi que solo se verifica uno de los dos, nunca ambos.
CHECKS=()
[ "$TARGET_STEP" -ge 1 ] && CHECKS+=(1)
[ "$TARGET_STEP" -ge 2 ] && CHECKS+=(2)
if [ "$TARGET_STEP" -eq 3 ]; then
  CHECKS+=(3)
elif [ "$TARGET_STEP" -ge 4 ]; then
  CHECKS+=(4)
fi
[ "$TARGET_STEP" -ge 5 ] && CHECKS+=(5)
[ "$TARGET_STEP" -ge 6 ] && CHECKS+=(6)

# --- Ejecucion -----------------------------------------------------------
echo "Verificando Lab 03: Deshacer, Alias y Remotos"
echo "-----------------------------------------------------"

PASS=0
TOTAL=${#CHECKS[@]}
for step in "${CHECKS[@]}"; do
  if "check_step${step}"; then
    PASS=$((PASS + 1))
  fi
done

echo "-----------------------------------------------------"
if [ "$TARGET_STEP" -eq "$MAX_STEP" ]; then
  echo "$PASS/$TOTAL checks superados"
else
  echo "$PASS/$TOTAL checks superados (hasta el step $TARGET_STEP)"
fi

if [ "$PASS" -eq "$TOTAL" ]; then
  echo -e "${GREEN}[OK]${NC} Todo correcto hasta el step $TARGET_STEP"
  exit 0
else
  echo -e "${RED}[x]${NC} Todavia faltan cosas por completar."
  exit 1
fi
