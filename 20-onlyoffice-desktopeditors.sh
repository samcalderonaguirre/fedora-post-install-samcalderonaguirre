#!/usr/bin/env bash
# ==============================================================================
# Script: 20-onlyoffice-desktopeditors.sh
# Objetivo: Instalar ONLYOFFICE Desktop Editors en Fedora desde el repositorio
#           oficial de ONLYOFFICE usando dnf directamente y sin depender de EPEL.
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

for cmd in dnf rpm sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

ONLYOFFICE_REPO_RPM="https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm"

log_info "1/2 Instalando el paquete de repositorio oficial de ONLYOFFICE..."
if rpm -q onlyoffice-repo >/dev/null 2>&1; then
  log_warn "El paquete onlyoffice-repo ya está instalado; se omite descarga."
else
  sudo dnf install -y "$ONLYOFFICE_REPO_RPM"
fi

log_info "2/2 Instalando onlyoffice-desktopeditors..."
sudo dnf install -y onlyoffice-desktopeditors

log_info "Verificando instalación de ONLYOFFICE Desktop Editors..."
rpm -q onlyoffice-repo onlyoffice-desktopeditors

log_info "Instalación de ONLYOFFICE Desktop Editors completada."