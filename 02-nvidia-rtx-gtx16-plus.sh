#!/usr/bin/env bash
# ==============================================================================
# Script: 02-nvidia-rtx-gtx16-plus.sh
# Objetivo: Instalar los controladores NVIDIA (akmod-nvidia) y pila multimedia /
#           CUDA / Vulkan para GPUs RTX 20, GTX 16 y RTX 30/40/50 en Fedora,
#           esperar la compilación de akmods y habilitar suspensión/hibernación.
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

if ! dnf repolist --enabled | grep -qi "rpmfusion-nonfree"; then
  log_error "No se detectó RPM Fusion nonfree habilitado. Ejecuta primero el script 01."
  exit 1
fi

log_info "1/3 Instalando driver NVIDIA, CUDA, Vulkan, VA-API/VDPAU y utilidades..."
sudo dnf install -y \
  akmod-nvidia \
  xorg-x11-drv-nvidia-cuda \
  xorg-x11-drv-nvidia-power \
  vulkan \
  xorg-x11-drv-nvidia-cuda-libs \
  libva-nvidia-driver \
  libva-utils \
  vdpauinfo

log_info "2/3 Esperando 5 minutos (300 s) para la compilación de los módulos akmods..."
# Cuenta regresiva de 300 segundos para dar margen suficiente a la compilación
# del módulo del kernel en segundo plano antes de habilitar servicios o reiniciar.
TOTAL_SECONDS=300
INTERVAL=30
elapsed=0

while (( elapsed < TOTAL_SECONDS )); do
  remaining=$(( TOTAL_SECONDS - elapsed ))
  log_warn "Compilación de akmods en curso... faltan ${remaining}s"
  sleep "$INTERVAL"
  elapsed=$(( elapsed + INTERVAL ))
done

log_info "3/3 Habilitando servicios de suspensión e hibernación de NVIDIA..."
sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate

log_warn "Reinicia el sistema para cargar el nuevo módulo NVIDIA y activar los servicios."
read -r -p "¿Deseas reiniciar ahora mismo? [s/N]: " respuesta
case "${respuesta,,}" in
  s|si|sí|y|yes)
    log_info "Reiniciando el equipo..."
    sudo reboot
    ;;
  *)
    log_info "Reinicio pospuesto. Tras reiniciar, verifica con 'nvidia-smi' y 'vainfo'."
    ;;
esac