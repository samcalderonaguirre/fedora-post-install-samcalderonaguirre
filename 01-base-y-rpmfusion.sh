#!/usr/bin/env bash
# ==============================================================================
# Script: 01-base-y-rpmfusion.sh
# Objetivo: Actualizar el sistema base en Fedora y habilitar RPM Fusion
#           (free y nonfree), repositorio Cisco OpenH264 y datos AppStream.
# ==============================================================================

# Salir inmediatamente si un comando falla (-e), si se usa una variable no
# definida (-u), o si falla cualquier comando dentro de un pipeline (-o pipefail).
set -euo pipefail

# Colores sencillos para diferenciar estados en terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Evitar ejecutar todo con sudo desde el inicio; pedimos credenciales al vuelo
# y mantenemos la sesión activa mientras corre el script.
if [[ "$EUID" -eq 0 ]]; then
  log_error "Ejecuta este script como usuario normal (usará sudo cuando corresponda)."
  exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
  log_error "No se encontró 'dnf'. Este script está pensado para Fedora."
  exit 1
fi

sudo -v

log_info "1/5 Actualizando metadatos y paquetes del sistema..."
sudo dnf update --refresh -y

log_info "2/5 Instalando repositorios RPM Fusion (free y nonfree) para Fedora $(rpm -E %fedora)..."
# $(rpm -E %fedora) expande automáticamente la versión mayor activa de Fedora
# (por ejemplo, 43, 44, 45...), evitando hardcodear números de versión.
sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

log_info "3/5 Habilitando el repositorio fedora-cisco-openh264..."
# En Fedora moderno (DNF5), la sintaxis estándar para activar/desactivar repos es:
# sudo dnf config-manager setopt <repo>.enabled=1
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

log_info "4/5 Actualizando el grupo @core..."
sudo dnf update @core -y

log_info "5/5 Instalando metadatos AppStream de RPM Fusion (útil para GNOME Software / Discover)..."
# Entrecomillar el patrón evita que el shell intente expandir '*' localmente
# antes de pasárselo a DNF.
sudo dnf install -y 'rpmfusion-*-appstream-data'

log_warn "Se requiere reiniciar el sistema para aplicar cambios de kernel/paquetes base."
read -r -p "¿Deseas reiniciar ahora mismo? [s/N]: " respuesta
case "${respuesta,,}" in
  s|si|sí|y|yes)
    log_info "Reiniciando el equipo..."
    sudo reboot
    ;;
  *)
    log_info "Reinicio pospuesto. Recuerda ejecutar 'sudo reboot' cuando termines."
    ;;
esac