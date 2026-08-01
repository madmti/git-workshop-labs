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
  printf "${YELLOW}[i]${NC} Si quieres empezar de cero, bórrala y vuelve a ejecutar ./init.sh\n"
  exit 1
fi

mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q -b main
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

# --- Commit 1: esqueleto -------------------------------------------------
cat > "$REPO_DIR/tareas.py" <<'EOF'
#!/usr/bin/env python3
import sys

def main():
    print("CLI de tareas - usa: agregar | listar | borrar")

if __name__ == "__main__":
    main()
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# tareas.py

CLI de lista de tareas en Python.
EOF

cat > "$REPO_DIR/.gitignore" <<'EOF'
tareas.json
__pycache__/
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Commit inicial: esqueleto de tareas.py"

# --- Commit 2: comando agregar -------------------------------------------
cat > "$REPO_DIR/tareas.py" <<'EOF'
#!/usr/bin/env python3
import json
import sys

ARCHIVO = "tareas.json"

def cargar():
    try:
        with open(ARCHIVO) as f:
            return json.load(f)
    except FileNotFoundError:
        return []

def guardar(tareas):
    with open(ARCHIVO, "w") as f:
        json.dump(tareas, f, indent=2)

def agregar(descripcion):
    tareas = cargar()
    tareas.append({"descripcion": descripcion, "hecha": False})
    guardar(tareas)
    print(f"Agregada: {descripcion}")

def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "agregar":
        agregar(" ".join(sys.argv[2:]))
    else:
        print("CLI de tareas - usa: agregar <descripcion> | listar | borrar <id>")

if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega el comando agregar"

# --- Commit 3: comando listar --------------------------------------------
cat > "$REPO_DIR/tareas.py" <<'EOF'
#!/usr/bin/env python3
import json
import sys

ARCHIVO = "tareas.json"

def cargar():
    try:
        with open(ARCHIVO) as f:
            return json.load(f)
    except FileNotFoundError:
        return []

def guardar(tareas):
    with open(ARCHIVO, "w") as f:
        json.dump(tareas, f, indent=2)

def agregar(descripcion):
    tareas = cargar()
    tareas.append({"descripcion": descripcion, "hecha": False})
    guardar(tareas)
    print(f"Agregada: {descripcion}")

def listar():
    tareas = cargar()
    for i, t in enumerate(tareas):
        estado = "x" if t["hecha"] else " "
        print(f"{i}) [{estado}] {t['descripcion']}")

def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "agregar":
        agregar(" ".join(sys.argv[2:]))
    elif len(sys.argv) >= 2 and sys.argv[1] == "listar":
        listar()
    else:
        print("CLI de tareas - usa: agregar <descripcion> | listar | borrar <id>")

if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega el comando listar"

# --- Commit 4: comando borrar (con bug) ----------------------------------
cat > "$REPO_DIR/tareas.py" <<'EOF'
#!/usr/bin/env python3
import json
import sys

ARCHIVO = "tareas.json"

def cargar():
    try:
        with open(ARCHIVO) as f:
            return json.load(f)
    except FileNotFoundError:
        return []

def guardar(tareas):
    with open(ARCHIVO, "w") as f:
        json.dump(tareas, f, indent=2)

def agregar(descripcion):
    tareas = cargar()
    tareas.append({"descripcion": descripcion, "hecha": False})
    guardar(tareas)
    print(f"Agregada: {descripcion}")

def listar():
    tareas = cargar()
    for i, t in enumerate(tareas):
        estado = "x" if t["hecha"] else " "
        print(f"{i}) [{estado}] {t['descripcion']}")

def borrar(indice):
    tareas = cargar()
    # BUG: ignora el indice y borra siempre la primera tarea.
    tareas.pop(0)
    guardar(tareas)
    print("Borrada")

def main():
    if len(sys.argv) >= 2 and sys.argv[1] == "agregar":
        agregar(" ".join(sys.argv[2:]))
    elif len(sys.argv) >= 2 and sys.argv[1] == "listar":
        listar()
    elif len(sys.argv) >= 2 and sys.argv[1] == "borrar":
        borrar(int(sys.argv[2]))
    else:
        print("CLI de tareas - usa: agregar <descripcion> | listar | borrar <id>")

if __name__ == "__main__":
    main()
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# tareas.py

CLI de lista de tareas en Python. Comandos: `agregar`, `listar`, `borrar`.
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Agrega el comando borrar"

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} 4 commits en main: el commit 'Agrega el comando listar' (main~1) es el bueno\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
