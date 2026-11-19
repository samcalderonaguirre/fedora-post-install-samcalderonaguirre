#!/usr/bin/env bash
# ==============================================================================
# Script: 16-cargo-rust-setup.sh
# Objetivo: Instalar Cargo y Rust en Fedora, agregar $HOME/.cargo/bin al PATH
#           en ~/.bashrc y ~/.zshrc de forma idempotente, y verificar la
#           instalación con cargo --version.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

if [[ "$EUID" -eq 0 ]]; then
  log_error "Ejecuta este script como usuario normal (usará sudo cuando corresponda)."
  exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
  log_error "No se encontró 'dnf'. Este script está pensado para Fedora."
  exit 1
fi

sudo -v

CARGO_PATH_LINE='export PATH="$HOME/.cargo/bin:$PATH"'

log_info "1/3 Instalando paquetes cargo y rust desde los repositorios de Fedora..."
sudo dnf install -y cargo rust

log_info "2/3 Configurando $HOME/.cargo/bin en ~/.bashrc y ~/.zshrc..."
mkdir -p "$HOME/.cargo/bin"
touch "$HOME/.bashrc" "$HOME/.zshrc"

if ! grep -Fq '$HOME/.cargo/bin' "$HOME/.bashrc"; then
  printf '\n# Rust / Cargo\n%s\n' "$CARGO_PATH_LINE" >> "$HOME/.bashrc"
else
  log_warn "La ruta de Cargo ya está configurada en ~/.bashrc; se omite duplicado."
fi

if ! grep -Fq '$HOME/.cargo/bin' "$HOME/.zshrc"; then
  printf '\n# Rust / Cargo\n%s\n' "$CARGO_PATH_LINE" >> "$HOME/.zshrc"
else
  log_warn "La ruta de Cargo ya está configurada en ~/.zshrc; se omite duplicado."
fi

# Exportar la ruta en la sesión actual del script para comprobar cargo de inmediato
export PATH="$HOME/.cargo/bin:$PATH"

log_info "3/3 Verificando versiones de cargo y rustc..."
cargo --version
rustc --version

log_info "Configuración de Cargo y Rust completada."