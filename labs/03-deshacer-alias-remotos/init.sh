#!/usr/bin/env bash
set -euo pipefail

# --- Manejo de color -------------------------------------------------
# Se puede desactivar con: ./init.sh --no-color
# o con:                   COLORS=0 ./init.sh
USE_COLOR=1
[ "${COLORS:-1}" = "0" ] && USE_COLOR=0
[ -t 1 ] || USE_COLOR=0
for arg in "$@"; do
  [ "$arg" = "--no-color" ] && USE_COLOR=0
done

if [ "$USE_COLOR" = "1" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi
# -----------------------------------------------------------------------

LAB_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR_NAME="calculadora"
BARE_DIR_NAME="remoto-calculadora.git"
PROJECT_PATH="$LAB_DIR/$PROJECT_DIR_NAME"
BARE_PATH="$LAB_DIR/$BARE_DIR_NAME"

if [ -d "$PROJECT_PATH" ] || [ -d "$BARE_PATH" ]; then
  echo -e "${YELLOW}[!]${NC} Ya existe '$PROJECT_DIR_NAME' o '$BARE_DIR_NAME'."
  echo "    Si quieres reiniciar el ejercicio desde cero, borra ambos:"
  echo "    rm -rf $PROJECT_DIR_NAME $BARE_DIR_NAME"
  exit 1
fi

# --- 1. Crear el repositorio remoto (bare) ------------------------------
echo -e "${BLUE}[i]${NC} Preparando el repositorio remoto..."
git init --bare -q "$BARE_PATH"
git -C "$BARE_PATH" symbolic-ref HEAD refs/heads/main

# --- 2. Crear el repositorio local con su historia -----------------------
echo -e "${BLUE}[i]${NC} Preparando tu repositorio local..."
mkdir "$PROJECT_PATH"
git -C "$PROJECT_PATH" init -q
git -C "$PROJECT_PATH" symbolic-ref HEAD refs/heads/main
git -C "$PROJECT_PATH" config user.name "Taller Git"
git -C "$PROJECT_PATH" config user.email "taller@git-workshop.local"

cat > "$PROJECT_PATH/main.py" << 'PYEOF'
#!/usr/bin/env python3
"""Calculadora CLI simple."""

# TODO (step 5): cuando crees raiz_cuadrada() en operaciones.py, agregala a este import
from operaciones import suma, resta, multiplicacion, division, potencia
from utils import validar_numero

OPCIONES = {
    "1": ("Suma", suma),
    "2": ("Resta", resta),
    "3": ("Multiplicacion", multiplicacion),
    "4": ("Division", division),
    "5": ("Potencia", potencia),
    # TODO (step 5): agrega aqui la entrada para la nueva operacion, ej:
    # "6": ("Raiz cuadrada", raiz_cuadrada),
}


def mostrar_menu():
    print("\n=== Calculadora ===")
    for clave, (nombre, _) in OPCIONES.items():
        print(f"{clave}. {nombre}")
    print("0. Salir")


def pedir_numero(mensaje):
    while True:
        valor = input(mensaje)
        if validar_numero(valor):
            return float(valor)
        print("Numero invalido, intenta de nuevo.")


def main():
    while True:
        mostrar_menu()
        opcion = input("Elige una opcion: ").strip()

        if opcion == "0":
            print("Hasta luego!")
            break

        if opcion not in OPCIONES:
            print("Opcion invalida.")
            continue

        nombre, operacion = OPCIONES[opcion]
        a = pedir_numero("Primer numero: ")
        b = pedir_numero("Segundo numero: ")

        try:
            resultado = operacion(a, b)
            print(f"{nombre} -> {resultado}")
        except ZeroDivisionError:
            print("Error: no se puede dividir por cero.")


if __name__ == "__main__":
    main()
PYEOF

cat > "$PROJECT_PATH/operaciones.py" << 'PYEOF'
"""Operaciones matematicas basicas de la calculadora."""


def suma(a, b):
    return a + b


def resta(a, b):
    return a - b


def multiplicacion(a, b):
    return a * b


def division(a, b):
    return a / b


def potencia(base, exponente):
    # TODO: retornar 'base' elevado a 'exponente'
    return 0
PYEOF

cat > "$PROJECT_PATH/operaciones_legacy.py" << 'PYEOF'
"""
Version antigua de la calculadora.

Todas las operaciones estaban mezcladas en una sola funcion, sin separar
por archivo. Se reemplazo por operaciones.py + main.py.

Este archivo ya no se usa en ningun lado del proyecto.
"""


def calcular(operacion, a, b):
    if operacion == "suma":
        return a + b
    elif operacion == "resta":
        return a - b
    elif operacion == "multiplicacion":
        return a * b
    elif operacion == "division":
        return a / b
    else:
        raise ValueError(f"Operacion desconocida: {operacion}")
PYEOF

cat > "$PROJECT_PATH/utils.py" << 'PYEOF'
"""Funciones auxiliares de la calculadora."""


def validar_numero(valor):
    """Retorna True si 'valor' se puede convertir a float."""
    try:
        float(valor)
        return True
    except ValueError:
        return False
PYEOF

cat > "$PROJECT_PATH/README.md" << 'MDEOF'
# Calculadora CLI

Una calculadora de línea de comandos simple, escrita en Python puro
(sin dependencias externas).

## Uso

```bash
python3 main.py
```

## Estructura

- `main.py`: loop principal del CLI.
- `operaciones.py`: funciones matemáticas (suma, resta, multiplicación,
  división, potencia).
- `utils.py`: funciones auxiliares de validación.
MDEOF

git -C "$PROJECT_PATH" add -A
git -C "$PROJECT_PATH" commit -q -m "commit inicial"

# Completar potencia()
cat > "$PROJECT_PATH/operaciones.py" << 'PYEOF'
"""Operaciones matematicas basicas de la calculadora."""


def suma(a, b):
    return a + b


def resta(a, b):
    return a - b


def multiplicacion(a, b):
    return a * b


def division(a, b):
    return a / b


def potencia(base, exponente):
    return base ** exponente


# TODO (step 5): agrega aqui la funcion raiz_cuadrada(x)
# Pista: en Python, x ** 0.5 calcula la raiz cuadrada de x
PYEOF
git -C "$PROJECT_PATH" add operaciones.py
git -C "$PROJECT_PATH" commit -q -m "completar potencia()"

# Ignorar __pycache__/
echo "__pycache__/" > "$PROJECT_PATH/.gitignore"
git -C "$PROJECT_PATH" add .gitignore
git -C "$PROJECT_PATH" commit -q -m "ignorar __pycache__"

# Eliminar codigo legacy
git -C "$PROJECT_PATH" rm -q operaciones_legacy.py
git -C "$PROJECT_PATH" commit -q -m "eliminar codigo legacy"

# Renombrar utils.py a helpers.py
git -C "$PROJECT_PATH" mv utils.py helpers.py
sed -i 's/from utils import/from helpers import/' "$PROJECT_PATH/main.py"
git -C "$PROJECT_PATH" add main.py
git -C "$PROJECT_PATH" commit -q -m "renombrar utils a helpers"

# --- 3. Subir esta historia al remoto (sin configurar 'origin' todavia) --
git -C "$PROJECT_PATH" push -q "$BARE_PATH" main

# --- 4. Simular que un companero subio un cambio antes que el alumno -----
TMP_CLONE="$(mktemp -d)"
git clone -q "$BARE_PATH" "$TMP_CLONE"
git -C "$TMP_CLONE" config user.name "Compañero de equipo"
git -C "$TMP_CLONE" config user.email "companero@git-workshop.local"

cat > "$TMP_CLONE/CHANGELOG.md" << 'MDEOF'
# Changelog

- Renombrado utils.py a helpers.py
- Codigo legacy eliminado
MDEOF

git -C "$TMP_CLONE" add CHANGELOG.md
git -C "$TMP_CLONE" commit -q -m "agregar CHANGELOG.md"
git -C "$TMP_CLONE" push -q origin main
rm -rf "$TMP_CLONE"

# --- 5. Instrucciones -----------------------------------------------------
echo -e "${GREEN}[OK]${NC} Repositorio local creado en ./$PROJECT_DIR_NAME"
echo -e "${GREEN}[OK]${NC} Repositorio remoto creado en ./$BARE_DIR_NAME"
echo ""
echo -e "${BOLD}=========================================================="
echo " Lab 03 - Deshacer, Alias y Remotos"
echo -e "==========================================================${NC}"
echo ""
echo "Tu compañero ya subió un cambio al remoto que tú todavía no tienes."
echo ""
echo "Pasos:"
echo -e "  1. ${BLUE}cd $PROJECT_DIR_NAME${NC} y configura los alias locales"
echo "  2. Conecta el remoto y trae el cambio de tu compañero"
echo "  3. Prepara y luego deshace un archivo (git restore --staged)"
echo "  4. Modifica y luego descarta un archivo (git restore)"
echo "  5. Crea un commit, y enmiéndalo con un archivo que olvidaste"
echo "  6. Sube tus cambios al remoto"
echo ""
echo "Cuando termines, vuelve a esta carpeta y ejecuta:"
echo -e "  ${BLUE}./verify.sh${NC}"
echo ""
echo -e "${YELLOW}[i]${NC} Instrucciones completas (con los comandos exactos) en README.md"
echo -e "${YELLOW}[i]${NC} Si tu terminal no soporta colores, usa: ./init.sh --no-color"
