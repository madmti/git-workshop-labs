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
# Los estados de los steps 1, 2 y 3 son ventanas transitorias del index:
# cada uno lo pisa el siguiente (mas staging) y los steps 4 y 5 los destruyen
# por completo al commitear (al confirmar, el diff preparado desaparece).
# Por eso cada uno se verifica solo en su ventana valida:
#   - target 1/2/3 -> estado de staging de ese step puntual.
#   - target 4     -> contenido del primer commit parcial (HEAD).
#   - target 5 o completo -> estado final usando la evidencia que SOBREVIVE a
#     los commits: el contenido de HEAD^ (primer parcial, sin updatedAt) y de
#     HEAD (segundo parcial), mas el conteo de commits y el working tree
#     limpio. No se re-verifican los states transitorios 1-3 en el target 5.

RUN_S1=0; RUN_S2=0; RUN_S3=0; RUN_S4=0; RUN_S5=0
if [ -z "$TARGET" ]; then
  RUN_S5=1
else
  case "$TARGET" in
    1) RUN_S1=1 ;;
    2) RUN_S2=1 ;;
    3) RUN_S3=1 ;;
    4) RUN_S4=1 ;;
    5) RUN_S5=1 ;;
  esac
fi

# ---------------------------------------------------------------------------
# Steps 1-3: estado transitorio del index / working tree
# ---------------------------------------------------------------------------

# Step 1: migration.sql preparada, schema.prisma sin preparar pero modificado.
check_step1a() {
  [[ "$(git diff --cached --name-only 2>/dev/null)" == *migrations/0002_add_tasks/migration.sql* ]]
}
check_step1b() {
  [[ "$(git diff --cached --name-only 2>/dev/null)" != *schema.prisma* ]]
}
check_step1c() {
  [[ "$(git diff --name-only 2>/dev/null)" == *schema.prisma* ]]
}

# Step 2: + hunk de Task (status) preparado; User (VarChar/updatedAt) sin
# preparar.
check_step2a() {
  [[ "$(git diff --cached --name-only 2>/dev/null)" == *migrations/0002_add_tasks/migration.sql* ]]
}
check_step2b() {
  local d="$(git diff --cached -- prisma/schema.prisma 2>/dev/null)"
  [[ "$d" == *'@default("pending")'* ]]
}
check_step2c() {
  local d="$(git diff --cached -- prisma/schema.prisma 2>/dev/null)"
  [[ "$d" != *'@db.VarChar(255)'* ]]
}
check_step2d() {
  local d="$(git diff -- prisma/schema.prisma 2>/dev/null)"
  [[ "$d" == *updatedAt* ]]
}

# Step 3: + VarChar(255) preparado (hunk dividido); updatedAt sin preparar.
check_step3a() {
  [[ "$(git diff --cached --name-only 2>/dev/null)" == *migrations/0002_add_tasks/migration.sql* ]]
}
check_step3b() {
  local d="$(git diff --cached -- prisma/schema.prisma 2>/dev/null)"
  [[ "$d" == *'@default("pending")'* ]]
}
check_step3c() {
  local d="$(git diff --cached -- prisma/schema.prisma 2>/dev/null)"
  [[ "$d" == *'@db.VarChar(255)'* ]]
}
check_step3d() {
  local d="$(git diff -- prisma/schema.prisma 2>/dev/null)"
  [[ "$d" == *updatedAt* ]]
}

# ---------------------------------------------------------------------------
# Steps 4-5: estado committeado (nunca se lee el working tree como prueba de
# que algo fue confirmado; se extrae con git show).
# ---------------------------------------------------------------------------

# Step 4: primer commit parcial = base + 1. HEAD tiene status y VarChar(255)
# pero NO updatedAt; la migracion entro completa (status + updatedAt); el
# updatedAt de schema.prisma sigue sin confirmar en el working tree.
check_step4a() {
  [ "$(git rev-list --count HEAD 2>/dev/null)" = "2" ]
}
check_step4b() {
  local c="$(git show HEAD:prisma/schema.prisma 2>/dev/null)"
  [[ "$c" == *'@default("pending")'* ]] && [[ "$c" == *'@db.VarChar(255)'* ]]
}
check_step4c() {
  local c="$(git show HEAD:prisma/schema.prisma 2>/dev/null)"
  [[ "$c" != *updatedAt* ]]
}
check_step4d() {
  local c="$(git show HEAD:prisma/migrations/0002_add_tasks/migration.sql 2>/dev/null)"
  [[ "$c" == *"'pending'"* ]] && [[ "$c" == *"ADD COLUMN"* ]]
}
check_step4e() {
  [[ "$(git status --porcelain 2>/dev/null)" == *' M prisma/schema.prisma'* ]]
}

# Step 5: segundo commit parcial = base + 2. HEAD^ (primer parcial) tiene
# status/VarChar pero no updatedAt; HEAD ya lo tiene todo; working tree limpio.
check_step5a() {
  [ "$(git rev-list --count HEAD 2>/dev/null)" = "3" ]
}
check_step5b() {
  local c="$(git show HEAD^:prisma/schema.prisma 2>/dev/null)"
  [[ "$c" == *'@default("pending")'* ]] && [[ "$c" == *'@db.VarChar(255)'* ]] && [[ "$c" != *updatedAt* ]]
}
check_step5c() {
  local c="$(git show HEAD^:prisma/migrations/0002_add_tasks/migration.sql 2>/dev/null)"
  [[ "$c" == *"'pending'"* ]] && [[ "$c" == *"ADD COLUMN"* ]]
}
check_step5d() {
  local c="$(git show HEAD:prisma/schema.prisma 2>/dev/null)"
  [[ "$c" == *'@default("pending")'* ]] && [[ "$c" == *'@db.VarChar(255)'* ]] && [[ "$c" == *updatedAt* ]]
}
check_step5e() {
  local c="$(git show HEAD:prisma/migrations/0002_add_tasks/migration.sql 2>/dev/null)"
  [[ "$c" == *"'pending'"* ]] && [[ "$c" == *"ADD COLUMN"* ]]
}
check_step5f() {
  [ -z "$(git status --porcelain 2>/dev/null)" ]
}

if [ "$RUN_S1" = "1" ]; then
  run_check "(step 1) La migracion 0002_add_tasks esta en el index" check_step1a
  run_check "(step 1) schema.prisma NO esta en el index" check_step1b
  run_check "(step 1) schema.prisma tiene cambios sin confirmar" check_step1c
fi
if [ "$RUN_S2" = "1" ]; then
  run_check "(step 2) La migracion 0002_add_tasks sigue en el index" check_step2a
  run_check "(step 2) El hunk de Task (status) esta preparado" check_step2b
  run_check "(step 2) El hunk de User (VarChar) NO esta preparado aun" check_step2c
  run_check "(step 2) updatedAt sigue sin preparar (working tree)" check_step2d
fi
if [ "$RUN_S3" = "1" ]; then
  run_check "(step 3) La migracion 0002_add_tasks sigue en el index" check_step3a
  run_check "(step 3) El hunk de Task (status) sigue preparado" check_step3b
  run_check "(step 3) VarChar(255) preparado con el split del hunk" check_step3c
  run_check "(step 3) updatedAt sigue sin preparar (working tree)" check_step3d
fi
if [ "$RUN_S4" = "1" ]; then
  run_check "(step 4) Hay 2 commits (base + primer parcial)" check_step4a
  run_check "(step 4) HEAD tiene status y VarChar(255) en schema.prisma" check_step4b
  run_check "(step 4) HEAD NO tiene updatedAt en schema.prisma" check_step4c
  run_check "(step 4) La migracion entro completa (status + updatedAt)" check_step4d
  run_check "(step 4) updatedAt sigue sin confirmar en el working tree" check_step4e
fi
if [ "$RUN_S5" = "1" ]; then
  run_check "(step 5) Hay 3 commits (base + 2 parciales)" check_step5a
  run_check "(step 5) Primer parcial: schema.prisma sin updatedAt" check_step5b
  run_check "(step 5) Primer parcial: migracion completa" check_step5c
  run_check "(step 5) HEAD tiene status, VarChar(255) y updatedAt" check_step5d
  run_check "(step 5) HEAD: migracion con status y updatedAt" check_step5e
  run_check "(step 5) Working tree limpio" check_step5f
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
