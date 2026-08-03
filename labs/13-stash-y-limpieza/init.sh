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

if [ -d "$REPO_DIR" ]; then
  printf "${YELLOW}[!]${NC} La carpeta %s ya existe.\n" "$REPO_DIR"
  printf "${YELLOW}[i]${NC} Si quieres empezar de cero, borrala y vuelve a ejecutar ./init.sh\n"
  exit 1
fi

mkdir -p "$REPO_DIR/src" "$REPO_DIR/build" "$REPO_DIR/tmp"
git -C "$REPO_DIR" init -q -b master
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

commit_msg() {
  local fecha="$1"
  local mensaje="$2"
  GIT_AUTHOR_DATE="$fecha" GIT_COMMITTER_DATE="$fecha" git -C "$REPO_DIR" commit -q -m "$mensaje"
}

# --- Commit 1: esqueleto del compilador de paginas --------------------------
cat > "$REPO_DIR/.gitignore" <<'EOF'
build/
*.tmp
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# Compilador de paginas

Script en Python que lee los textos de `src/` y genera paginas HTML en `build/`.
EOF

cat > "$REPO_DIR/compiler.py" <<'EOF'
#!/usr/bin/env python3
"""Compilador de paginas: lee los .txt de src/ y genera paginas HTML en build/."""

from pathlib import Path

SRC = Path("src")
BUILD = Path("build")
TEMPLATE = "<html><body><h1>{titulo}</h1><p>{contenido}</p></body></html>"


def compilar():
    BUILD.mkdir(exist_ok=True)
    for origen in sorted(SRC.glob("*.txt")):
        lineas = origen.read_text().splitlines()
        titulo = lineas[0].lstrip("# ").strip()
        contenido = " ".join(lineas[1:]).strip()
        destino = BUILD / f"{origen.stem}.html"
        destino.write_text(TEMPLATE.format(titulo=titulo, contenido=contenido))
        print(f"generado {destino}")


if __name__ == "__main__":
    compilar()
EOF

cat > "$REPO_DIR/src/index.txt" <<'EOF'
# Pagina principal

Bienvenida al sitio generado por el compilador.
EOF

cat > "$REPO_DIR/src/guia.txt" <<'EOF'
# Guia del taller

Instrucciones paso a paso para completar el taller de Git.
EOF

git -C "$REPO_DIR" add -A
commit_msg "2026-08-02T09:00:00" "Esqueleto del compilador de paginas"

# --- Commit 2: mejora, agrega pie de pagina al template ---------------------
cat > "$REPO_DIR/compiler.py" <<'EOF'
#!/usr/bin/env python3
"""Compilador de paginas: lee los .txt de src/ y genera paginas HTML en build/."""

from pathlib import Path

SRC = Path("src")
BUILD = Path("build")
TEMPLATE = "<html><body><h1>{titulo}</h1><p>{contenido}</p><footer>Taller Git</footer></body></html>"


def compilar():
    BUILD.mkdir(exist_ok=True)
    for origen in sorted(SRC.glob("*.txt")):
        lineas = origen.read_text().splitlines()
        titulo = lineas[0].lstrip("# ").strip()
        contenido = " ".join(lineas[1:]).strip()
        destino = BUILD / f"{origen.stem}.html"
        destino.write_text(TEMPLATE.format(titulo=titulo, contenido=contenido))
        print(f"generado {destino}")


if __name__ == "__main__":
    compilar()
EOF

git -C "$REPO_DIR" add -A
commit_msg "2026-08-02T09:05:00" "Agrega pie de pagina al template"

# --- Working tree sucio: trabajo a medias (staged + unstaged) ---------------
# compiler.py modificado y STAGED: agrega la generacion de sitemap.txt
cat > "$REPO_DIR/compiler.py" <<'EOF'
#!/usr/bin/env python3
"""Compilador de paginas: lee los .txt de src/ y genera paginas HTML en build/."""

from pathlib import Path

SRC = Path("src")
BUILD = Path("build")
TEMPLATE = "<html><body><h1>{titulo}</h1><p>{contenido}</p><footer>Taller Git</footer></body></html>"


def compilar():
    BUILD.mkdir(exist_ok=True)
    paginas = []
    for origen in sorted(SRC.glob("*.txt")):
        lineas = origen.read_text().splitlines()
        titulo = lineas[0].lstrip("# ").strip()
        contenido = " ".join(lineas[1:]).strip()
        destino = BUILD / f"{origen.stem}.html"
        destino.write_text(TEMPLATE.format(titulo=titulo, contenido=contenido))
        paginas.append(destino.name)
        print(f"generado {destino}")
    (BUILD / "sitemap.txt").write_text("\n".join(paginas) + "\n")


if __name__ == "__main__":
    compilar()
EOF

git -C "$REPO_DIR" add compiler.py

# src/guia.txt modificado y UNSTAGED: cambia el titulo
cat > "$REPO_DIR/src/guia.txt" <<'EOF'
# Guia actualizada del taller

Instrucciones paso a paso para completar el taller de Git.
EOF

# --- Basura sin seguimiento (untracked, no ignorada) ------------------------
cat > "$REPO_DIR/debug.log" <<'EOF'
[debug] 12:01:02 compilando src/index.txt
[debug] 12:01:03 compilando src/guia.txt
EOF

cat > "$REPO_DIR/notas.txt" <<'EOF'
recordar: revisar el sitemap antes de mergear
EOF

cat > "$REPO_DIR/tmp/borrador.txt" <<'EOF'
borrador del sitemap
EOF

cat > "$REPO_DIR/tmp/old.bin" <<'EOF'
datos viejos sin usar
EOF

# --- Artefactos ignorados (build/ y *.tmp) ----------------------------------
cat > "$REPO_DIR/build/index.html" <<'EOF'
<html><body><h1>Pagina principal</h1><p>Bienvenida al sitio generado por el compilador.</p><footer>Taller Git</footer></body></html>
EOF

cat > "$REPO_DIR/build/guia.html" <<'EOF'
<html><body><h1>Guia del taller</h1><p>Instrucciones paso a paso para completar el taller de Git.</p><footer>Taller Git</footer></body></html>
EOF

cat > "$REPO_DIR/cache.tmp" <<'EOF'
cache de compilacion: 3 archivos procesados
EOF

# --- Cierre -----------------------------------------------------------------
printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} 2 commits con el proyecto: compilador de paginas en Python\n"
printf "${BLUE}[i]${NC} Working tree sucio: compiler.py staged, src/guia.txt sin preparar\n"
printf "${BLUE}[i]${NC} Basura untracked (debug.log, notas.txt, tmp/) e ignorados (build/, cache.tmp)\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
