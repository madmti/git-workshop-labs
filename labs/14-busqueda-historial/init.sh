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

mkdir -p "$REPO_DIR/modules/networking"
git -C "$REPO_DIR" init -q -b master
git -C "$REPO_DIR" config --local user.name "Estudiante Taller Git"
git -C "$REPO_DIR" config --local user.email "estudiante@taller.local"

commit_letra() {
  local fecha="$1"
  local letra="$2"
  GIT_AUTHOR_DATE="$fecha" GIT_COMMITTER_DATE="$fecha" git -C "$REPO_DIR" commit -q -m "$letra"
}

# --- Commit 0: esqueleto base -------------------------------------------------
cat > "$REPO_DIR/.gitignore" <<'EOF'
# Terraform
.terraform/
*.tfstate
*.tfstate.backup

# Local
.DS_Store
EOF

cat > "$REPO_DIR/README.md" <<'EOF'
# Infraestructura del taller

Terraform que despliega una instancia EC2 con su grupo de seguridad y un
bucket S3 para los assets de la aplicacion web.
EOF

cat > "$REPO_DIR/variables.tf" <<'EOF'
variable "region" {
  description = "Region de AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para el servidor web"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "AMI de Amazon Linux 2023"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "app_name" {
  description = "Nombre de la aplicacion que se despliega"
  type        = string
  default     = "frontend"
}
EOF

cat > "$REPO_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = ["web-sg"]

  tags = {
    Name = "web"
  }
}
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:00:00-0400" "0"

# --- Commit A: se agrega el security group ------------------------------------
cat > "$REPO_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Habilita HTTP y SSH para la instancia web"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = ["web-sg"]

  tags = {
    Name = "web"
  }
}
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:02:00-0400" "A"

# --- Commit O: se agrega el bucket S3 y los outputs ---------------------------
cat > "$REPO_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Habilita HTTP y SSH para la instancia web"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = ["web-sg"]

  tags = {
    Name = "web"
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "assets-${var.app_name}"

  tags = {
    Name = "assets-${var.app_name}"
  }
}
EOF

cat > "$REPO_DIR/outputs.tf" <<'EOF'
output "web_public_ip" {
  description = "IP publica de la instancia web"
  value       = aws_instance.web.public_ip
}

output "assets_bucket" {
  description = "Bucket S3 que almacena los assets estaticos"
  value       = aws_s3_bucket.assets.id
}
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:10:00-0400" "O"

# --- Tag v1.0: punto de comparacion para buscar en arboles antiguos -----------
git -C "$REPO_DIR" tag v1.0

# --- Commit L: el security group se mueve a un modulo -------------------------
cat > "$REPO_DIR/modules/networking/main.tf" <<'EOF'
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Habilita HTTP y SSH para la instancia web"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

output "sg_name" {
  description = "Nombre del grupo de seguridad web"
  value       = aws_security_group.web.name
}
EOF

cat > "$REPO_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "networking" {
  source = "./modules/networking"
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = [module.networking.sg_name]

  tags = {
    Name = "web"
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "assets-${var.app_name}"

  tags = {
    Name = "assets-${var.app_name}"
  }
}
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:20:00-0400" "L"

# --- Commit V: el bucket se marca como destruible -----------------------------
cat > "$REPO_DIR/main.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "networking" {
  source = "./modules/networking"
}

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  security_groups = [module.networking.sg_name]

  tags = {
    Name = "web"
  }
}

resource "aws_s3_bucket" "assets" {
  bucket        = "assets-${var.app_name}"
  force_destroy = true

  tags = {
    Name = "assets-${var.app_name}"
  }
}
EOF

git -C "$REPO_DIR" add -A
commit_letra "2026-08-01T09:22:00-0400" "V"

# --- cierre ------------------------------------------------------------------
git -C "$REPO_DIR" checkout -q master

printf "${GREEN}[OK]${NC} Repositorio creado en %s\n" "$REPO_DIR"
printf "${BLUE}[i]${NC} Historia pre-armada (cada commit es una letra):\n"
printf "${BLUE}    master = 0 -> A -> O (tag v1.0) -> L -> V${NC}\n"
printf "${BLUE}[i]${NC} Proyecto: infraestructura en Terraform (EC2, security group, S3)\n"
printf "${BLUE}[i]${NC} Identidad git configurada a nivel local\n"
printf "${BLUE}[i]${NC} Siguiente paso: %s\n" "cd proyecto"
