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

mkdir -p "$REPO_DIR/configs"
git -C "$REPO_DIR" init -q -b master
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

commit_letra() {
  local fecha="$1"
  local letra="$2"
  GIT_AUTHOR_DATE="$fecha" GIT_COMMITTER_DATE="$fecha" git -C "$REPO_DIR" commit -q -m "$letra"
}

# --- Commit raiz (0): esqueleto del migrador ---------------------------------
cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    print(f"Migrando configuraciones en {directorio}")


if __name__ == "__main__":
    main()
EOF

cat > "$REPO_DIR/configs/app.legacy" <<'EOF'
# Configuracion legacy de la aplicacion
host=localhost
port=8080
version=1
EOF

cat > "$REPO_DIR/configs/db.legacy" <<'EOF'
# Configuracion legacy de la base de datos
host=localhost
port=5432
version=1
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# Migrador de configuraciones

Script en Python que recorre un filesystem buscando archivos legacy
(patron *.legacy) y los convierte a versiones nuevas aplicando
modificaciones y calculos.
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:00:00" "0"

# --- Commit A: descubrimiento de archivos por patron (base compartida) -------
cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for archivo in buscar_legacy(directorio):
        print(f"Encontrado: {archivo.name}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:02:00" "A"

# --- experiment (T, I, G): pipeline parsear -> calcular -> escribir ----------
git -C "$REPO_DIR" checkout -q -b experiment

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def parsear_configuracion(archivo):
    """Lee un archivo legacy y devuelve sus pares clave=valor."""
    config = {}
    for linea in archivo.read_text().splitlines():
        if linea and not linea.startswith("#") and "=" in linea:
            clave, valor = linea.split("=", 1)
            config[clave.strip()] = valor.strip()
    return config


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for archivo in buscar_legacy(directorio):
        print(f"{archivo.name}: {parsear_configuracion(archivo)}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:10:00" "T"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def parsear_configuracion(archivo):
    """Lee un archivo legacy y devuelve sus pares clave=valor."""
    config = {}
    for linea in archivo.read_text().splitlines():
        if linea and not linea.startswith("#") and "=" in linea:
            clave, valor = linea.split("=", 1)
            config[clave.strip()] = valor.strip()
    return config


def calcular_nueva_version(config):
    """Aplica los calculos de la migracion a una configuracion."""
    nueva = dict(config)
    nueva["port"] = str(int(config["port"]) + 1000)
    nueva["version"] = str(int(config["version"]) + 1)
    return nueva


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for archivo in buscar_legacy(directorio):
        config = parsear_configuracion(archivo)
        print(f"{archivo.name}: {calcular_nueva_version(config)}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:11:00" "I"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def parsear_configuracion(archivo):
    """Lee un archivo legacy y devuelve sus pares clave=valor."""
    config = {}
    for linea in archivo.read_text().splitlines():
        if linea and not linea.startswith("#") and "=" in linea:
            clave, valor = linea.split("=", 1)
            config[clave.strip()] = valor.strip()
    return config


def calcular_nueva_version(config):
    """Aplica los calculos de la migracion a una configuracion."""
    nueva = dict(config)
    nueva["port"] = str(int(config["port"]) + 1000)
    nueva["version"] = str(int(config["version"]) + 1)
    return nueva


def escribir_nueva_version(archivo, config):
    """Escribe la version nueva con extension .v2 al lado del original."""
    salida = archivo.with_suffix(".v2")
    lineas = [f"{clave}={valor}\n" for clave, valor in config.items()]
    salida.write_text("".join(lineas))
    return salida


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for archivo in buscar_legacy(directorio):
        config = calcular_nueva_version(parsear_configuracion(archivo))
        print(f"Generado: {escribir_nueva_version(archivo, config)}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:12:00" "G"

# --- feature (E, B, U, N): CLI con opciones ----------------------------------
git -C "$REPO_DIR" checkout -q master
git -C "$REPO_DIR" checkout -q -b feature

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import argparse
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def crear_argumentos():
    parser = argparse.ArgumentParser(description="Migra configuraciones legacy")
    parser.add_argument("--dir", default=".", help="directorio a migrar")
    return parser.parse_args()


def main():
    args = crear_argumentos()
    for archivo in buscar_legacy(Path(args.dir)):
        print(f"Encontrado: {archivo.name}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:20:00" "E"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import argparse
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def crear_argumentos():
    parser = argparse.ArgumentParser(description="Migra configuraciones legacy")
    parser.add_argument("--dir", default=".", help="directorio a migrar")
    parser.add_argument("--dry-run", action="store_true", help="solo muestra lo que haria")
    return parser.parse_args()


def main():
    args = crear_argumentos()
    modo = "simulacion" if args.dry_run else "migracion"
    print(f"Modo: {modo}")
    for archivo in buscar_legacy(Path(args.dir)):
        print(f"Encontrado: {archivo.name}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:21:00" "B"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import argparse
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def crear_argumentos():
    parser = argparse.ArgumentParser(description="Migra configuraciones legacy")
    parser.add_argument("--dir", default=".", help="directorio a migrar")
    parser.add_argument("--dry-run", action="store_true", help="solo muestra lo que haria")
    parser.add_argument("--verbose", action="store_true", help="imprime detalle de cada paso")
    return parser.parse_args()


def main():
    args = crear_argumentos()
    modo = "simulacion" if args.dry_run else "migracion"
    print(f"Modo: {modo}")
    for archivo in buscar_legacy(Path(args.dir)):
        if args.verbose:
            print(f"Procesando {archivo.name}")
        print(f"Encontrado: {archivo.name}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:22:00" "U"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import argparse
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def crear_argumentos():
    parser = argparse.ArgumentParser(description="Migra configuraciones legacy")
    parser.add_argument("--dir", default=".", help="directorio a migrar")
    parser.add_argument("--dry-run", action="store_true", help="solo muestra lo que haria")
    parser.add_argument("--verbose", action="store_true", help="imprime detalle de cada paso")
    return parser.parse_args()


def main():
    args = crear_argumentos()
    modo = "simulacion" if args.dry_run else "migracion"
    archivos = buscar_legacy(Path(args.dir))
    print(f"Modo: {modo}")
    print(f"Archivos legacy encontrados: {len(archivos)}")
    for archivo in archivos:
        if args.verbose:
            print(f"Procesando {archivo.name}")
        print(f"Encontrado: {archivo.name}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:23:00" "N"

# --- master (L, O, S): ruta destino, transformacion y orquestador ------------
git -C "$REPO_DIR" checkout -q master

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def ruta_destino(archivo):
    """Calcula la ruta de la version nueva a partir del nombre legacy."""
    return archivo.with_suffix(".v2")


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for archivo in buscar_legacy(directorio):
        print(f"{archivo.name} -> {ruta_destino(archivo).name}")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:30:00" "L"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def ruta_destino(archivo):
    """Calcula la ruta de la version nueva a partir del nombre legacy."""
    return archivo.with_suffix(".v2")


def transformar_linea(linea):
    """Aplica la modificacion a una linea legacy (clave=valor)."""
    if linea.startswith("#") or "=" not in linea:
        return linea
    clave, valor = linea.split("=", 1)
    if clave.strip() == "port":
        valor = str(int(valor) + 1000)
    return f"{clave}={valor}\n"


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for archivo in buscar_legacy(directorio):
        print(f"{archivo.name} -> {ruta_destino(archivo).name}")
        for linea in archivo.read_text().splitlines():
            print(f"  {transformar_linea(linea)}", end="")


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:31:00" "O"

cat > "$REPO_DIR/migrate.py" <<'EOF'
#!/usr/bin/env python3
"""Migrador de configuraciones legacy.

Busca archivos con patrones viejos en el filesystem y los convierte
a nuevas versiones aplicando modificaciones y calculos.
"""
import sys
from pathlib import Path

LEGACY_SUFFIX = ".legacy"


def buscar_legacy(directorio):
    """Devuelve los archivos legacy presentes en el directorio."""
    return sorted(directorio.glob(f"*{LEGACY_SUFFIX}"))


def ruta_destino(archivo):
    """Calcula la ruta de la version nueva a partir del nombre legacy."""
    return archivo.with_suffix(".v2")


def transformar_linea(linea):
    """Aplica la modificacion a una linea legacy (clave=valor)."""
    if linea.startswith("#") or "=" not in linea:
        return linea
    clave, valor = linea.split("=", 1)
    if clave.strip() == "port":
        valor = str(int(valor) + 1000)
    return f"{clave}={valor}\n"


def migrar(directorio):
    """Orquesta la migracion de todos los archivos legacy."""
    for archivo in buscar_legacy(directorio):
        destino = ruta_destino(archivo)
        lineas = [transformar_linea(linea) for linea in archivo.read_text().splitlines()]
        destino.write_text("".join(lineas))
        print(f"Migrado: {archivo.name} -> {destino.name}")


def main():
    directorio = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    migrar(directorio)


if __name__ == "__main__":
    main()
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:32:00" "S"

# --- cierre ------------------------------------------------------------------
git -C "$REPO_DIR" checkout -q master

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} Grafo pre-armado (cada commit es una letra):\n"
printf "${BLUE}    master     = 0 -> A -> L -> O -> S${NC}\n"
printf "${BLUE}    experiment = 0 -> A -> T -> I -> G${NC}\n"
printf "${BLUE}    feature    = 0 -> A -> E -> B -> U -> N${NC}\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
