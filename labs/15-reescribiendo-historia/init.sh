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

mkdir -p "$REPO_DIR/tests"
git -C "$REPO_DIR" init -q -b master
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

commit() {
  local fecha="$1"
  local mensaje="$2"
  GIT_AUTHOR_DATE="$fecha" GIT_COMMITTER_DATE="$fecha" git -C "$REPO_DIR" commit -q -m "$mensaje"
}

# --- C0 (raiz): servidor con endpoint /health ---------------------------------
cat > "$REPO_DIR/README.md" <<'EOF'
# Test de endpoint HTTP

Suite de testing para el servidor HTTP de la aplicacion (`app.py`).
Cubre los endpoints /health, /version y /status con la stdlib de Python
(unittest, http.server y urllib), sin dependencias externas.
EOF

cat > "$REPO_DIR/app.py" <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self._responder(200, {"status": "ok"})
        else:
            self._responder(404, {"error": "not found"})

    def _responder(self, codigo, datos):
        cuerpo = json.dumps(datos).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
EOF

cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = HTTPServer(("127.0.0.1", 0), Handler)
        cls.puerto = cls.servidor.server_address[1]
        threading.Thread(target=cls.servidor.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:00:00" "Agrega servidor con endpoint /health"

# --- C1: endpoint /version y su test (a dividir en el step 5) -----------------
cat > "$REPO_DIR/app.py" <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self._responder(200, {"status": "ok"})
        elif self.path == "/version":
            self._responder(200, {"version": "1.0.0"})
        else:
            self._responder(404, {"error": "not found"})

    def _responder(self, codigo, datos):
        cuerpo = json.dumps(datos).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
EOF

cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = HTTPServer(("127.0.0.1", 0), Handler)
        cls.puerto = cls.servidor.server_address[1]
        threading.Thread(target=cls.servidor.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")

    def test_version(self):
        status, body = self._get("/version")
        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.0.0")


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:02:00" "Agrega endpoint /version y su test"

# --- C2: corrige la salida del /health (mensaje con typo, a reword) -----------
cat > "$REPO_DIR/app.py" <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self._responder(200, {"status": "ok", "service": "api"})
        elif self.path == "/version":
            self._responder(200, {"version": "1.0.0"})
        else:
            self._responder(404, {"error": "not found"})

    def _responder(self, codigo, datos):
        cuerpo = json.dumps(datos).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:04:00" "Corrige la salida del endpooint /health"

# --- C3: agrega helper para iniciar el servidor (a squash con C4) -------------
cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


def iniciar_servidor(handler):
    servidor = HTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    return servidor


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = HTTPServer(("127.0.0.1", 0), Handler)
        cls.puerto = cls.servidor.server_address[1]
        threading.Thread(target=cls.servidor.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")

    def test_version(self):
        status, body = self._get("/version")
        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.0.0")


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:06:00" "Agrega helper para iniciar el servidor"

# --- C4: usa el helper en los tests (a squash con C3) -------------------------
cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


def iniciar_servidor(handler):
    servidor = HTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    return servidor


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = iniciar_servidor(Handler)
        cls.puerto = cls.servidor.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")

    def test_version(self):
        status, body = self._get("/version")
        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.0.0")


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:08:00" "Usa el helper en los tests"

# --- C5: agrega test de /status (a reordenar en el step 4) --------------------
cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


def iniciar_servidor(handler):
    servidor = HTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    return servidor


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = iniciar_servidor(Handler)
        cls.puerto = cls.servidor.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")

    def test_version(self):
        status, body = self._get("/version")
        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.0.0")

    def test_status(self):
        status, body = self._get("/status")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "degradado")


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:10:00" "Agrega test de /status"

# --- C6: agrega endpoint /status (a reordenar en el step 4) -------------------
cat > "$REPO_DIR/app.py" <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self._responder(200, {"status": "ok", "service": "api"})
        elif self.path == "/version":
            self._responder(200, {"version": "1.0.0"})
        elif self.path == "/status":
            self._responder(200, {"status": "degradado"})
        else:
            self._responder(404, {"error": "not found"})

    def _responder(self, codigo, datos):
        cuerpo = json.dumps(datos).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 8000), Handler).serve_forever()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:12:00" "Agrega endpoint /status"

# --- C7: salida de debug (a eliminar en el step 4) ----------------------------
cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


def iniciar_servidor(handler):
    servidor = HTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    return servidor


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = iniciar_servidor(Handler)
        cls.puerto = cls.servidor.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        print("DEBUG:", path)
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")

    def test_version(self):
        status, body = self._get("/version")
        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.0.0")

    def test_status(self):
        status, body = self._get("/status")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "degradado")


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:14:00" "Agrega salida de debug al test"

# --- C8 (HEAD): tests de integirdad (a enmendar en el step 1) -----------------
cat > "$REPO_DIR/tests/test_api.py" <<'EOF'
import json
import threading
import unittest
import urllib.request

from http.server import HTTPServer

from app import Handler


def iniciar_servidor(handler):
    servidor = HTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=servidor.serve_forever, daemon=True).start()
    return servidor


class TestAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.servidor = iniciar_servidor(Handler)
        cls.puerto = cls.servidor.server_address[1]

    @classmethod
    def tearDownClass(cls):
        cls.servidor.shutdown()

    def _get(self, path):
        print("DEBUG:", path)
        with urllib.request.urlopen(f"http://127.0.0.1:{self.puerto}{path}") as resp:
            return resp.status, json.loads(resp.read())

    def test_health(self):
        status, body = self._get("/health")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "ok")

    def test_version(self):
        status, body = self._get("/version")
        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.0.0")

    def test_status(self):
        status, body = self._get("/status")
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "degradado")

    def test_integridad(self):
        status, _ = self._get("/health")
        self.assertEqual(status, 200)


if __name__ == "__main__":
    unittest.main()
EOF

git -C "$REPO_DIR" add -A
commit "2026-08-02T09:16:00" "Agrega tests de integirdad"

# --- cierre -------------------------------------------------------------------
printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} Historia inicial (git log --oneline):\n"
git -C "$REPO_DIR" log --oneline
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
