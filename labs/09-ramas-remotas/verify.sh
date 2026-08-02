#!/usr/bin/env bash
set -u
# Nota: NO se usa 'set -o pipefail' a proposito -- ver AGENTS.md (condicion
# de carrera con SIGPIPE al combinarlo con pipes).

# --- Manejo de color -------------------------------------------------
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
# -----------------------------------------------------------------------

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PROYECTO="$LAB_DIR/proyecto"
EQUIPO_BARE="$LAB_DIR/remoto-equipo.git"
TEAMONE_BARE="$LAB_DIR/remoto-teamone.git"

usage() {
  printf "Uso: %s [N]\n" "$0"
  printf "  Sin argumentos: corre todos los steps.\n"
  printf "  N: corre los steps aplicables hasta el step N (1-7).\n"
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
      [1-7]) TARGET="${ARGS[0]}" ;;
      *) usage ;;
    esac
    ;;
  *) usage ;;
esac

if [ ! -d "$PROYECTO/.git" ]; then
  printf "${RED}[x]${NC} No existe %s/.git. Corre ./init.sh y completa el step 1.\n" "$PROYECTO"
  exit 1
fi

cd "$PROYECTO"

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

# Verifica que un archivo committeado contenga un marcador.
file_has() {
  local ref_path="$1"
  local marker="$2"
  local content
  content="$(git show "$ref_path" 2>/dev/null || true)"
  [[ "$content" == *"$marker"* ]]
}

# Igual, pero contra un repositorio bare (los servidores).
bare_file_has() {
  local gitdir="$1"
  local ref_path="$2"
  local marker="$3"
  local content
  content="$(git --git-dir="$gitdir" show "$ref_path" 2>/dev/null || true)"
  [[ "$content" == *"$marker"* ]]
}

# ---------------------------------------------------------------------------
# NOTE (steps transitorios y mutuamente excluyentes):
# - S1_CLEAN (main == origin/main) solo vale en T=1: lo destruye el commit
#   del step 2. S2_AHEAD (main^ == origin/main) solo vale en T=2: lo
#   destruye el merge del step 3.
# - S3_SYNC (origin/main == main del servidor) se corre en T>=3: en T=1/2
#   no hubo fetch aun, la igualdad seria trivial. S1_ORIGIN y S1_TRACK
#   son permanentes y se corren siempre.
# - Los steps 4 y 5 publican la rama `serverfix` en remoto-equipo.git
#   (S4_BARE y S5_BARE verifican ese estado en el servidor). El step 7 la
#   elimina (git push origin --delete serverfix). Por eso, cuando
#   TARGET >= 7 (o corrida completa) NO se corren S4_BARE ni S5_BARE: el
#   estado que comprueban ya no existe; en su lugar se corre S7_DELETE,
#   que verifica el estado final (serverfix ya no esta en el servidor ni
#   como rama de seguimiento local).
# - Los checks sobre ramas LOCALES (serverfix, sf, otra: S4_LOCAL,
#   S5_TRACK_SF, S5_DOC_LOCAL, S5_OTRA) son permanentes: esas ramas nunca
#   se borran y se corren siempre.
# ---------------------------------------------------------------------------

RUN_S1_ORIGIN=0; RUN_S1_TRACK=0; RUN_S1_CLEAN=0
RUN_S2_NOVEDADES=0; RUN_S2_AHEAD=0
RUN_S3_CHANGELOG=0; RUN_S3_SYNC=0; RUN_S3_MERGE=0; RUN_S3_CONTENT=0; RUN_S3_PARENT=0
RUN_S4_LOCAL=0; RUN_S4_BARE=0
RUN_S5_TRACK_SF=0; RUN_S5_DOC_LOCAL=0; RUN_S5_BARE=0; RUN_S5_OTRA=0
RUN_S6_REMOTE=0; RUN_S6_FETCH=0
RUN_S7_DELETE=0

if [ -z "$TARGET" ]; then
  RUN_S1_ORIGIN=1; RUN_S1_TRACK=1
  RUN_S2_NOVEDADES=1
  RUN_S3_CHANGELOG=1; RUN_S3_SYNC=1; RUN_S3_MERGE=1; RUN_S3_CONTENT=1; RUN_S3_PARENT=1
  RUN_S4_LOCAL=1
  RUN_S5_TRACK_SF=1; RUN_S5_DOC_LOCAL=1; RUN_S5_OTRA=1
  RUN_S6_REMOTE=1; RUN_S6_FETCH=1
  RUN_S7_DELETE=1
else
  case "$TARGET" in
    1) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S1_CLEAN=1 ;;
    2) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S2_NOVEDADES=1; RUN_S2_AHEAD=1 ;;
    3) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S2_NOVEDADES=1;
       RUN_S3_CHANGELOG=1; RUN_S3_SYNC=1; RUN_S3_MERGE=1; RUN_S3_CONTENT=1; RUN_S3_PARENT=1 ;;
    4) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S2_NOVEDADES=1;
       RUN_S3_CHANGELOG=1; RUN_S3_SYNC=1; RUN_S3_MERGE=1; RUN_S3_CONTENT=1; RUN_S3_PARENT=1;
       RUN_S4_LOCAL=1; RUN_S4_BARE=1 ;;
    5) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S2_NOVEDADES=1;
       RUN_S3_CHANGELOG=1; RUN_S3_SYNC=1; RUN_S3_MERGE=1; RUN_S3_CONTENT=1; RUN_S3_PARENT=1;
       RUN_S4_LOCAL=1; RUN_S4_BARE=1;
       RUN_S5_TRACK_SF=1; RUN_S5_DOC_LOCAL=1; RUN_S5_BARE=1; RUN_S5_OTRA=1 ;;
    6) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S2_NOVEDADES=1;
       RUN_S3_CHANGELOG=1; RUN_S3_SYNC=1; RUN_S3_MERGE=1; RUN_S3_CONTENT=1; RUN_S3_PARENT=1;
       RUN_S4_LOCAL=1; RUN_S4_BARE=1;
       RUN_S5_TRACK_SF=1; RUN_S5_DOC_LOCAL=1; RUN_S5_BARE=1; RUN_S5_OTRA=1;
       RUN_S6_REMOTE=1; RUN_S6_FETCH=1 ;;
    7) RUN_S1_ORIGIN=1; RUN_S1_TRACK=1; RUN_S2_NOVEDADES=1;
       RUN_S3_CHANGELOG=1; RUN_S3_SYNC=1; RUN_S3_MERGE=1; RUN_S3_CONTENT=1; RUN_S3_PARENT=1;
       RUN_S4_LOCAL=1;
       RUN_S5_TRACK_SF=1; RUN_S5_DOC_LOCAL=1; RUN_S5_OTRA=1;
       RUN_S6_REMOTE=1; RUN_S6_FETCH=1;
       RUN_S7_DELETE=1 ;;
  esac
fi

check_s1_origin() {
  local url
  url="$(git remote get-url origin 2>/dev/null || true)"
  url="${url%/}"
  [ "$url" = "$EQUIPO_BARE" ]
}

check_s1_track() {
  [ "$(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/main)" = "main origin/main" ]
}

check_s1_clean() {
  [ "$(git rev-parse main 2>/dev/null)" = "$(git rev-parse origin/main 2>/dev/null)" ]
}

check_s2_novedades() {
  file_has "main:index.html" '<p class="novedades">Novedades: abrimos envios a todo el pais.</p>'
}

check_s2_ahead() {
  [ "$(git rev-parse main^ 2>/dev/null)" = "$(git rev-parse origin/main 2>/dev/null)" ]
}

check_s3_changelog() {
  git --git-dir="$EQUIPO_BARE" show main:CHANGELOG.md >/dev/null 2>&1
}

check_s3_sync() {
  [ "$(git rev-parse origin/main 2>/dev/null)" = "$(git --git-dir="$EQUIPO_BARE" rev-parse main 2>/dev/null)" ]
}

check_s3_merge() {
  [ "$(git show -s --format=%P main 2>/dev/null | wc -w)" = "2" ]
}

check_s3_content() {
  file_has "main:CHANGELOG.md" "Changelog"
}

check_s3_parent() {
  [ "$(git rev-parse main^2 2>/dev/null)" = "$(git rev-parse origin/main 2>/dev/null)" ]
}

check_s4_local() {
  git show-ref --verify -q refs/heads/serverfix \
    && file_has "serverfix:css/estilos.css" "color: #c00;"
}

check_s4_bare() {
  git --git-dir="$EQUIPO_BARE" show-ref --verify -q refs/heads/serverfix \
    && bare_file_has "$EQUIPO_BARE" "serverfix:css/estilos.css" "color: #c00;"
}

check_s5_track_sf() {
  [ "$(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/sf)" = "sf origin/serverfix" ]
}

check_s5_doc_local() {
  file_has "sf:README.md" "La rama de seguimiento"
}

check_s5_bare() {
  git --git-dir="$EQUIPO_BARE" show-ref --verify -q refs/heads/serverfix \
    && bare_file_has "$EQUIPO_BARE" "serverfix:README.md" "La rama de seguimiento"
}

check_s5_otra() {
  [ "$(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads/otra)" = "otra origin/serverfix" ]
}

check_s6_remote() {
  local url
  url="$(git remote get-url teamone 2>/dev/null || true)"
  url="${url%/}"
  [ "$url" = "../remoto-teamone.git" ]
}

check_s6_fetch() {
  [ "$(git rev-parse teamone/main 2>/dev/null)" = "$(git --git-dir="$TEAMONE_BARE" rev-parse main 2>/dev/null)" ]
}

check_s7_bare_gone() {
  ! git --git-dir="$EQUIPO_BARE" show-ref --verify -q refs/heads/serverfix
}

check_s7_track_gone() {
  ! git show-ref --verify -q refs/remotes/origin/serverfix
}

if [ "$RUN_S1_ORIGIN" = "1" ]; then
  run_check "(step 1) Clonado con origin apuntando a remoto-equipo.git" check_s1_origin
fi
if [ "$RUN_S1_TRACK" = "1" ]; then
  run_check "(step 1) main local hace seguimiento de origin/main" check_s1_track
fi
if [ "$RUN_S1_CLEAN" = "1" ]; then
  run_check "(step 1) main local en el mismo commit que origin/main" check_s1_clean
fi
if [ "$RUN_S2_NOVEDADES" = "1" ]; then
  run_check "(step 2) Commit local con el aviso de novedades en index.html" check_s2_novedades
fi
if [ "$RUN_S2_AHEAD" = "1" ]; then
  run_check "(step 2) main tiene exactamente 1 commit local sin integrar" check_s2_ahead
fi
if [ "$RUN_S3_CHANGELOG" = "1" ]; then
  run_check "(step 3) El servidor recibio el CHANGELOG.md de Maria" check_s3_changelog
fi
if [ "$RUN_S3_SYNC" = "1" ]; then
  run_check "(step 3) origin/main actualizado con git fetch" check_s3_sync
fi
if [ "$RUN_S3_MERGE" = "1" ]; then
  run_check "(step 3) main es un merge commit con 2 padres" check_s3_merge
fi
if [ "$RUN_S3_CONTENT" = "1" ]; then
  run_check "(step 3) CHANGELOG.md integrado en main" check_s3_content
fi
if [ "$RUN_S3_PARENT" = "1" ]; then
  run_check "(step 3) La fusion integro origin/main" check_s3_parent
fi
if [ "$RUN_S4_LOCAL" = "1" ]; then
  run_check "(step 4) Rama local serverfix con el estilo destacado" check_s4_local
fi
if [ "$RUN_S4_BARE" = "1" ]; then
  run_check "(step 4) serverfix publicada en el servidor con el estilo" check_s4_bare
fi
if [ "$RUN_S5_TRACK_SF" = "1" ]; then
  run_check "(step 5) sf hace seguimiento de origin/serverfix" check_s5_track_sf
fi
if [ "$RUN_S5_DOC_LOCAL" = "1" ]; then
  run_check "(step 5) Commit en sf documentando la rama de seguimiento" check_s5_doc_local
fi
if [ "$RUN_S5_BARE" = "1" ]; then
  run_check "(step 5) El commit de sf publicado en origin/serverfix" check_s5_bare
fi
if [ "$RUN_S5_OTRA" = "1" ]; then
  run_check "(step 5) otra asociada a origin/serverfix con -u" check_s5_otra
fi
if [ "$RUN_S6_REMOTE" = "1" ]; then
  run_check "(step 6) Remoto teamone configurado" check_s6_remote
fi
if [ "$RUN_S6_FETCH" = "1" ]; then
  run_check "(step 6) teamone/main traida con git fetch teamone" check_s6_fetch
fi
if [ "$RUN_S7_DELETE" = "1" ]; then
  run_check "(step 7) serverfix eliminada del servidor" check_s7_bare_gone
  run_check "(step 7) origin/serverfix eliminada como rama de seguimiento" check_s7_track_gone
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
