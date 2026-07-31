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
REPO_DIR="$LAB_DIR/mi-repo"
MAX_STEPS=7

usage() {
  echo "Uso: ./verify.sh [N]"
  echo "  N: verifica los checks aplicables hasta el step N (1-$MAX_STEPS)"
  echo "  sin argumentos: verifica todos los steps"
  exit 2
}

TARGET="$MAX_STEPS"
ARGS=()
for a in "$@"; do
  [ "$a" = "--no-color" ] && continue
  ARGS+=("$a")
done
if [ "${#ARGS[@]}" -gt 0 ]; then
  case "${ARGS[0]}" in
    ''|*[!0-9]*) usage ;;
    *) TARGET="${ARGS[0]}" ;;
  esac
fi
if [ "$TARGET" -lt 1 ] || [ "$TARGET" -gt "$MAX_STEPS" ]; then
  usage
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  printf "${RED}[x]${NC} No se encontro el repositorio en \"%s\".\n" "$REPO_DIR"
  printf "${YELLOW}[i]${NC} Ejecuta ./init.sh desde la carpeta del lab y vuelve a intentar.\n"
  exit 1
fi

# --- Inspeccion de objetos --------------------------------------------
# El verificador NO compara el contenido de los archivos: no tiene sentido
# evaluar que el alumno copie un texto. Valida que las operaciones de
# fontaneria dejen un grafo de objetos bien armado:
#   - step 2: servidor.conf tiene contenido y su blob existe en la DB.
#   - steps 3-5: existen trees con las entradas correctas (los nombres son
#     fijos por los comandos del README; el contenido es libre).
#   - steps 6-7: commits encadenados apuntando a los trees correctos.
OBJ_LIST=$(git -C "$REPO_DIR" cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' 2>/dev/null)

obj_exists() {
  git -C "$REPO_DIR" cat-file -e "$1" >/dev/null 2>&1
}

tree_entries() { # $1 = sha de tree; imprime "nombre:tipo" ordenado por nombre
  git -C "$REPO_DIR" cat-file -p "$1" 2>/dev/null | awk '{print $4 ":" $2}' | sort
}

tree_class() { # $1 = sha; imprime viejo|nuevo|final (o vacio si no matchea ninguna)
  local e
  e=$(tree_entries "$1")
  if [ "$e" = "$(printf 'database.conf:blob\nservidor.conf:blob')" ]; then
    echo viejo
  elif [ "$e" = "$(printf 'database.conf:blob\nlogging.conf:blob\nservidor.conf:blob')" ]; then
    echo nuevo
  elif [ "$e" = "$(printf 'backup:tree\ndatabase.conf:blob\nlogging.conf:blob\nservidor.conf:blob')" ]; then
    echo final
  fi
}

backup_subtree() { # $1 = sha de tree; imprime el sha de la entrada "backup" si es tree
  git -C "$REPO_DIR" cat-file -p "$1" 2>/dev/null | awk '$4 == "backup" && $2 == "tree" {print $3; exit}'
}

has_tree_class() { # $1 = clase; 0 si existe al menos un tree de esa clase
  local sha type cls
  while read -r sha type _; do
    [ "$type" = "tree" ] || continue
    cls=$(tree_class "$sha")
    [ "$cls" = "$1" ] && return 0
  done <<< "$OBJ_LIST"
  return 1
}

find_commit() { # $1 = clase de tree esperada, $2 = parent esperado ("" = sin parent); imprime el sha
  local sha type info ctree cparent
  while read -r sha type _; do
    [ "$type" = "commit" ] || continue
    info=$(git -C "$REPO_DIR" cat-file -p "$sha" 2>/dev/null)
    ctree=$(printf '%s\n' "$info" | awk '/^tree /{print $2; exit}')
    cparent=$(printf '%s\n' "$info" | awk '/^parent /{print $2; exit}')
    [ "$(tree_class "$ctree")" = "$1" ] || continue
    if [ -z "$2" ]; then
      [ -z "$cparent" ] || continue
    else
      [ "$cparent" = "$2" ] || continue
    fi
    printf '%s' "$sha"
    return 0
  done <<< "$OBJ_LIST"
  return 1
}

# --- Steps -------------------------------------------------------------
step1() { # alias locales
  local a
  for a in guardar-blob ver-objeto tipo-objeto agregar-archivo guardar-arbol anidar-arbol crear-commit; do
    git -C "$REPO_DIR" config --local --get "alias.$a" >/dev/null 2>&1 || return 1
  done
  return 0
}

step2() { # blob de servidor.conf: el archivo tiene contenido y su blob existe
  local f hash
  f="$REPO_DIR/servidor.conf"
  [ -s "$f" ] || return 1
  hash=$(git -C "$REPO_DIR" hash-object --stdin < "$f" 2>/dev/null)
  [ -n "$hash" ] || return 1
  obj_exists "$hash"
}

step3() {
  has_tree_class viejo
}

step4() {
  has_tree_class nuevo
}

step5() {
  local sha type cls sub
  while read -r sha type _; do
    [ "$type" = "tree" ] || continue
    cls=$(tree_class "$sha")
    [ "$cls" = "final" ] || continue
    sub=$(backup_subtree "$sha")
    [ -n "$sub" ] && [ "$(tree_class "$sub")" = "viejo" ] && return 0
  done <<< "$OBJ_LIST"
  return 1
}

COMMIT6=""

step6() {
  local c
  c=$(find_commit viejo "")
  [ -z "$c" ] && return 1
  COMMIT6="$c"
  return 0
}

step7() {
  local c
  [ -z "${COMMIT6:-}" ] && return 1
  c=$(find_commit final "$COMMIT6")
  [ -z "$c" ] && return 1
  return 0
}

# --- Ejecucion ---------------------------------------------------------
OK=0
FAIL=0

for s in $(seq 1 "$TARGET"); do
  # Step 2 (el blob coincide con servidor.conf) solo es verificable mientras
  # el archivo conserve su contenido original. El step 4 lo reescribe, asi
  # que para target >= 4 ese check no se vuelve a correr: el rastro
  # persistente de los steps 2-3 lo cubre el check del tree config-viejo
  # (los trees nunca se borran). Steps mutuamente excluyentes, ver AGENTS
  # seccion 4.4.
  if [ "$s" -eq 2 ] && [ "$TARGET" -ge 4 ]; then
    continue
  fi

  status=1
  msg_ok=""
  msg_err=""
  case "$s" in
    1) msg_ok="Alias locales configurados";                                        msg_err="Faltan uno o mas alias locales (step 1)";                                              step1 && status=0 ;;
    2) msg_ok="Blob de servidor.conf creado";                                      msg_err="servidor.conf no tiene contenido o su blob no existe (step 2)";                            step2 && status=0 ;;
    3) msg_ok="Tree config-viejo creado (servidor.conf + database.conf)";          msg_err="No existe un tree con las entradas servidor.conf y database.conf (step 3)";               step3 && status=0 ;;
    4) msg_ok="Tree config-nuevo creado (con logging.conf)";                       msg_err="No existe un tree con las entradas servidor.conf, database.conf y logging.conf (step 4)"; step4 && status=0 ;;
    5) msg_ok="Tree final creado con backup/ anidado";                             msg_err="No existe un tree final con backup/ apuntando al tree config-viejo (step 5)";              step5 && status=0 ;;
    6) msg_ok="Primer commit (sin padre) apuntando a config-viejo";                msg_err="No existe un commit sin padre apuntando al tree config-viejo (step 6)";                    step6 && status=0 ;;
    7) msg_ok="Segundo commit (con padre) apuntando al tree final";                msg_err="No existe un commit con padre apuntando al tree final (step 7)";                          step7 && status=0 ;;
  esac
  if [ "$status" -eq 0 ]; then
    OK=$((OK + 1))
    printf "${GREEN}[OK]${NC} (step %s) %s\n" "$s" "$msg_ok"
  else
    FAIL=$((FAIL + 1))
    printf "${RED}[x]${NC} (step %s) %s\n" "$s" "$msg_err"
  fi
done

TOTAL=$((OK + FAIL))
echo ""
if [ "$FAIL" -eq 0 ]; then
  if [ "$TARGET" -lt "$MAX_STEPS" ]; then
    printf "${GREEN}%d/%d checks superados${NC} (hasta el step %s)\n" "$OK" "$TOTAL" "$TARGET"
  else
    printf "${GREEN}%d/%d checks superados${NC}\n" "$OK" "$TOTAL"
  fi
  printf "${GREEN}[OK]${NC} Repositorio construido a mano correctamente.\n"
  exit 0
else
  if [ "$TARGET" -lt "$MAX_STEPS" ]; then
    printf "${RED}%d/%d checks superados${NC} (hasta el step %s)\n" "$OK" "$TOTAL" "$TARGET"
  else
    printf "${RED}%d/%d checks superados${NC}\n" "$OK" "$TOTAL"
  fi
  printf "${RED}[x]${NC} Revisa los checks que fallan.\n"
  exit 1
fi
