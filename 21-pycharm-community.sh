#!/usr/bin/env bash
# ==============================================================================
# Script: 21-pycharm-community.sh
# Objetivo: Habilitar el repositorio COPR phracek/PyCharm e instalar
#           PyCharm Community Edition en Fedora.
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

for cmd in dnf sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

log_info "1/2 Habilitando repositorio COPR phracek/PyCharm..."
sudo dnf copr enable -y phracek/PyCharm

log_info "2/2 Instalando pycharm-community..."
sudo dnf install -y pycharm-community

log_info "Verificando instalación de PyCharm Community..."
rpm -q pycharm-community

log_info "Instalación de PyCharm Community completada."