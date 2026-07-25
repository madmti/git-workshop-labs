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

PROJECT_DIR="calculadora"

if [ -d "$PROJECT_DIR" ]; then
  echo -e "${YELLOW}[!]${NC} El directorio '$PROJECT_DIR' ya existe."
  echo "    Si quieres reiniciar el ejercicio desde cero, bórralo primero:"
  echo "    rm -rf $PROJECT_DIR"
  exit 1
fi

mkdir "$PROJECT_DIR"

cat > "$PROJECT_DIR/main.py" << 'PYEOF'
#!/usr/bin/env python3
"""Calculadora CLI simple."""

from operaciones import suma, resta, multiplicacion, division, potencia
from utils import validar_numero

OPCIONES = {
    "1": ("Suma", suma),
    "2": ("Resta", resta),
    "3": ("Multiplicacion", multiplicacion),
    "4": ("Division", division),
    "5": ("Potencia", potencia),
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

cat > "$PROJECT_DIR/operaciones.py" << 'PYEOF'
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

cat > "$PROJECT_DIR/operaciones_legacy.py" << 'PYEOF'
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

cat > "$PROJECT_DIR/utils.py" << 'PYEOF'
"""Funciones auxiliares de la calculadora."""


def validar_numero(valor):
    """Retorna True si 'valor' se puede convertir a float."""
    try:
        float(valor)
        return True
    except ValueError:
        return False
PYEOF

cat > "$PROJECT_DIR/README.md" << 'MDEOF'
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

echo -e "${GREEN}[OK]${NC} Proyecto creado en ./$PROJECT_DIR"
echo ""
echo -e "${BOLD}=========================================================="
echo " Lab 02 - Flujo basico: init, add, commit"
echo -e "==========================================================${NC}"
echo ""
echo "El proyecto es una calculadora CLI en Python. Todavia NO es un"
echo "repositorio Git -- eso es parte del ejercicio."
echo ""
echo "Pasos:"
echo -e "  1. ${BLUE}cd $PROJECT_DIR && git init${NC}"
echo "  2. Commit inicial de todos los archivos semilla"
echo "  3. Completar la funcion potencia() en operaciones.py y commitear"
echo "  4. Correr el programa, ignorar __pycache__/ y commitear"
echo "  5. Eliminar operaciones_legacy.py con 'git rm' y commitear"
echo "  6. Renombrar utils.py a helpers.py con 'git mv' y commitear"
echo ""
echo "Cuando termines, vuelve a esta carpeta y ejecuta:"
echo -e "  ${BLUE}./verify.sh${NC}"
echo ""
echo -e "${YELLOW}[i]${NC} Instrucciones completas (con los comandos exactos) en README.md"
echo -e "${YELLOW}[i]${NC} Si tu terminal no soporta colores, usa: ./init.sh --no-color"
