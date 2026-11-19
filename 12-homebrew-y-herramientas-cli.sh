#!/usr/bin/env bash
# ==============================================================================
# Script: 12-homebrew-y-herramientas-cli.sh
# Objetivo: Instalar dependencias de desarrollo, Homebrew (Linuxbrew),
#           configurar su entorno en Bash (~/.bashrc) y Zsh (~/.zshrc),
#           verificar la instalación e instalar herramientas CLI con brew.
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
  log_error "Ejecuta este script como usuario normal (Homebrew no debe instalarse como root)."
  exit 1
fi

for cmd in dnf curl git sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"

log_info "1/5 Instalando herramientas de desarrollo y dependencias de Homebrew..."
# En DNF5 funciona tanto 'dnf group install development-tools' como '@development-tools'
sudo dnf group install -y development-tools
sudo dnf install -y procps-ng curl file git

log_info "2/5 Instalando Homebrew en /home/linuxbrew/.linuxbrew..."
if [[ ! -x "$BREW_BIN" ]]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log_warn "Homebrew ya está instalado en $BREW_BIN; se omite descarga."
fi

log_info "3/5 Configurando variables de entorno de Homebrew en ~/.bashrc y ~/.zshrc..."
BASH_BREW_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"'
ZSH_BREW_LINE='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"'

touch "$HOME/.bashrc" "$HOME/.zshrc"

if ! grep -Fq "/home/linuxbrew/.linuxbrew/bin/brew shellenv" "$HOME/.bashrc"; then
  printf '\n# Homebrew (Linuxbrew)\n%s\n' "$BASH_BREW_LINE" >> "$HOME/.bashrc"
else
  log_warn "Configuración de Homebrew ya presente en ~/.bashrc."
fi

if ! grep -Fq "/home/linuxbrew/.linuxbrew/bin/brew shellenv" "$HOME/.zshrc"; then
  printf '\n# Homebrew (Linuxbrew)\n%s\n' "$ZSH_BREW_LINE" >> "$HOME/.zshrc"
else
  log_warn "Configuración de Homebrew ya presente en ~/.zshrc."
fi

# Cargar el entorno de brew en la sesión actual del script (usando sintaxis bash)
eval "$("$BREW_BIN" shellenv bash)"

log_info "4/5 Verificando instalación con brew --version y brew doctor..."
brew --version
# brew doctor puede devolver código != 0 si emite advertencias menores (ej. PATH o gcc);
# usamos '|| true' para mostrar el diagnóstico sin detener el script.
brew doctor || log_warn "brew doctor reportó advertencias menores (revisa la salida arriba)."

log_info "5/5 Instalando herramientas CLI con Homebrew (broot, joshuto, lf, ncurses, tty-clock)..."
brew install broot joshuto lf ncurses tty-clock

log_info "Instalación de Homebrew y herramientas CLI completada."