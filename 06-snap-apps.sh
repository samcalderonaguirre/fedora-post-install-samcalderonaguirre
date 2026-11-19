#!/usr/bin/env bash
# ==============================================================================
# Script: 06-snap-apps.sh
# Objetivo: Comprobar el funcionamiento de snapd con hello-world, instalar
#           snap-store y desplegar aplicaciones Snap (Sublime Text, Nextpad
#           y Ghostty).
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

if ! command -v snap >/dev/null 2>&1; then
  log_error "No se encontró el comando 'snap'. Ejecuta primero el script 05 y reinicia."
  exit 1
fi

sudo -v

log_info "1/3 Comprobando servicio snapd y ejecutando prueba hello-world..."
# Asegura que snapd.socket/snapd estén activos antes de instalar paquetes
sudo systemctl enable --now snapd.socket 2>/dev/null || true

if ! snap list hello-world >/dev/null 2>&1; then
  sudo snap install hello-world
fi
hello-world

log_info "2/3 Instalando Snap Store..."
if ! snap list snap-store >/dev/null 2>&1; then
  sudo snap install snap-store
else
  log_warn "snap-store ya está instalado; se omite."
fi

log_info "3/3 Instalando aplicaciones Snap (sublime-text, nextpad, ghostty)..."
if ! snap list sublime-text >/dev/null 2>&1; then
  sudo snap install sublime-text --classic
else
  log_warn "sublime-text ya está instalado; se omite."
fi

if ! snap list nextpad >/dev/null 2>&1; then
  sudo snap install nextpad
else
  log_warn "nextpad ya está instalado; se omite."
fi

if ! snap list ghostty >/dev/null 2>&1; then
  sudo snap install ghostty --classic
else
  log_warn "ghostty ya está instalado; se omite."
fi

log_info "Instalación de aplicaciones Snap completada."
snap list