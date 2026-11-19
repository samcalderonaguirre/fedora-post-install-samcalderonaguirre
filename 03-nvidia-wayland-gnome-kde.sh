#!/usr/bin/env bash
# ==============================================================================
# Script: 03-nvidia-wayland-gnome-kde.sh
# Objetivo: Configurar módulos del kernel (modprobe.d), variables globales
#           (/etc/environment), administración de energía y persistencia de
#           NVIDIA para sesiones Wayland en GNOME y KDE en Fedora.
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

if ! command -v dracut >/dev/null 2>&1; then
  log_error "No se encontró 'dracut'. Este script está pensado para Fedora."
  exit 1
fi

sudo -v

log_info "1/4 Configurando /etc/modprobe.d/nvidia.conf (modeset y PowerMizer)..."
# Se consolida en /etc/modprobe.d/nvidia.conf para evitar duplicar opciones
# 'options nvidia NVreg_RegistryDwords=...' entre varios archivos .conf.
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
# Habilita DRM KMS (necesario para Wayland en GNOME y KDE)
options nvidia-drm modeset=1
options nvidia-drm fbdev=1

# Perfil de rendimiento y PowerMizer en corriente AC
options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1"

# Preserva asignaciones de memoria de vídeo en suspensión/hibernación
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

# Si existía un archivo separado previo de power management de este bloque,
# lo removemos para evitar conflictos de parámetros duplicados en modprobe.
if [[ -f /etc/modprobe.d/nvidia-power-management.conf ]]; then
  log_warn "Eliminando /etc/modprobe.d/nvidia-power-management.conf para consolidar en nvidia.conf"
  sudo rm -f /etc/modprobe.d/nvidia-power-management.conf
fi

log_info "2/4 Agregando variables de entorno para Wayland (GNOME / KDE) en /etc/environment..."
# En /etc/environment las líneas deben ser KEY=VALUE sin 'export' ni comentarios
# pegados al final de la línea; se añaden solo si no existen previamente.
ENV_VARS=(
  "__GLX_VENDOR_LIBRARY_NAME=nvidia"
  "NV_PRIME_RENDER_OFFLOAD=1"
  "COGL_RENDERER=nvidia"
  "WLR_NO_HARDWARE_CURSORS=1"
  "GBM_BACKEND=nvidia-drm"
  "ENABLE_VULKAN_RENDERDOC_CAPTURE=1"
  "KWIN_TRIPLE_BUFFER=1"
  "KWIN_DRM_DISABLE_TRIPLE_BUFFERING=0"
)

sudo touch /etc/environment
for var in "${ENV_VARS[@]}"; do
  key="${var%%=*}"
  if grep -qE "^${key}=" /etc/environment; then
    log_warn "Variable '${key}' ya existe en /etc/environment; se omite duplicado."
  else
    echo "$var" | sudo tee -a /etc/environment >/dev/null
  fi
done

log_info "3/4 Habilitando e iniciando nvidia-persistenced..."
sudo systemctl enable nvidia-persistenced
sudo systemctl start nvidia-persistenced

log_info "4/4 Regenerando initramfs con dracut para aplicar cambios del kernel..."
sudo dracut --force

log_warn "Es necesario reiniciar el sistema para cargar el nuevo initramfs y las variables de entorno."
read -r -p "¿Deseas reiniciar ahora mismo? [s/N]: " respuesta
case "${respuesta,,}" in
  s|si|sí|y|yes)
    log_info "Reiniciando el equipo..."
    sudo reboot
    ;;
  *)
    log_info "Reinicio pospuesto. Tras reiniciar, verifica 'nvidia-drm.modeset' y 'nvidia-persistenced'."
    ;;
esac