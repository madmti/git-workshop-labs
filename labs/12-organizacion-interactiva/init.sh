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

mkdir -p "$REPO_DIR/prisma/migrations/0001_init"
mkdir -p "$REPO_DIR/prisma/migrations/0002_add_tasks"

git -C "$REPO_DIR" init -q -b master
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

# --- Commit base -------------------------------------------------------------

cat > "$REPO_DIR/README.md" <<'EOF'
# Backend de tareas con Prisma

API de tareas con Prisma y PostgreSQL. El schema define los modelos
`User` y `Task`, y las migraciones SQL están versionadas en
`prisma/migrations/`.
EOF

cat > "$REPO_DIR/prisma/schema.prisma" <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String   @db.VarChar(120)
  createdAt DateTime @default(now())
}

model Task {
  id          Int     @id @default(autoincrement())
  title       String
  description String?
  done        Boolean @default(false)
}
EOF

cat > "$REPO_DIR/prisma/migrations/0001_init/migration.sql" <<'EOF'
-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
EOF

cat > "$REPO_DIR/prisma/migrations/0002_add_tasks/migration.sql" <<'EOF'
-- CreateTable
CREATE TABLE "Task" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "done" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);
EOF

git -C "$REPO_DIR" add -A
git -C "$REPO_DIR" commit -q -m "Commit base: schema Prisma y migraciones"

# --- Cambios sin confirmar (working tree sucio a proposito) -------------------

cat > "$REPO_DIR/prisma/schema.prisma" <<'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String   @db.VarChar(255)
  createdAt DateTime @default(now())
  updatedAt DateTime @default(now())
}

model Task {
  id          Int     @id @default(autoincrement())
  title       String
  description String?
  done        Boolean @default(false)
  status      String  @default("pending")
}
EOF

cat > "$REPO_DIR/prisma/migrations/0002_add_tasks/migration.sql" <<'EOF'
-- CreateTable
CREATE TABLE "Task" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "done" BOOLEAN NOT NULL DEFAULT false,
    "status" TEXT NOT NULL DEFAULT 'pending',

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "User" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
EOF

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} Commit base en la rama master\n"
printf "${YELLOW}[!]${NC} Working tree sucio a proposito: cambios sin confirmar en\n"
printf "${YELLOW}    - prisma/schema.prisma${NC}\n"
printf "${YELLOW}    - prisma/migrations/0002_add_tasks/migration.sql${NC}\n"
printf "${BLUE}[i]${NC} No edites codigo: este lab es sobre preparar y commitear.\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
