#!/usr/bin/env bash
# ==============================================================================
# Script: 05-snapd-setup.sh
# Objetivo: Instalar snapd en Fedora, crear el enlace simbólico /snap ->
#           /var/lib/snapd/snap (requerido para snaps clásicos) y preparar
#           el sistema para reiniciar.
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

log_info "1/3 Instalando snapd..."
sudo dnf install -y snapd

log_info "2/3 Creando enlace simbólico /snap -> /var/lib/snapd/snap..."
# Evita que 'ln -s' falle si /snap ya existe (como archivo roto o enlace previo)
if [[ -L /snap || -e /snap ]]; then
  log_warn "/snap ya existe; actualizando enlace simbólico de forma segura."
  sudo ln -sfn /var/lib/snapd/snap /snap
else
  sudo ln -s /var/lib/snapd/snap /snap
fi

log_info "3/3 Habilitando socket de snapd..."
# En Fedora, snapd.socket gestiona la activación bajo demanda del servicio
# snapd al arrancar o cuando se invoca 'snap'.
sudo systemctl enable --now snapd.socket 2>/dev/null || sudo systemctl enable snapd.socket

log_warn "Reinicia el sistema para completar la integración de snapd y las rutas de entorno."
read -r -p "¿Deseas reiniciar ahora mismo? [s/N]: " respuesta
case "${respuesta,,}" in
  s|si|sí|y|yes)
    log_info "Reiniciando el equipo..."
    sudo reboot
    ;;
  *)
    log_info "Reinicio pospuesto. Tras reiniciar, prueba 'snap version'."
    ;;
esac