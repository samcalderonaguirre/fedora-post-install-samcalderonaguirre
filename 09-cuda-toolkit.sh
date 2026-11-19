#!/usr/bin/env bash
# ==============================================================================
# Script: 09-cuda-toolkit.sh
# Objetivo: Configurar el repositorio oficial de NVIDIA CUDA (Fedora 44+),
#           excluir explícitamente los paquetes de drivers del repo de NVIDIA
#           para proteger akmod-nvidia (RPM Fusion), e instalar cuda-toolkit.
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

ARCH="$(uname -m)"
REPO_ID="cuda-fedora44-${ARCH}"
REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/fedora44/${ARCH}/cuda-fedora44.repo"

log_info "1/5 Añadiendo repositorio oficial de NVIDIA CUDA (${REPO_ID})..."
# --overwrite asegura idempotencia si el archivo .repo ya existía previamente en /etc/yum.repos.d/
sudo dnf config-manager addrepo --overwrite --from-repofile="$REPO_URL"

log_info "2/5 Limpiando caché de DNF..."
sudo dnf clean all

log_info "3/5 Aplicando exclusiones de drivers en ${REPO_ID} para evitar conflictos con RPM Fusion..."
# Bloquea todos los módulos de kernel y drivers gráficos del repo oficial de NVIDIA
# para que DNF utilice exclusivamente el CUDA Toolkit y conserve el driver akmod-nvidia.
EXCLUDE_PKGS="nvidia-driver*,cuda-drivers*,nvidia-modprobe,nvidia-persistenced,nvidia-settings,nvidia-libXNVCtrl*,nvidia-xconfig,nvidia-open,nvidia-imex,nvidia-kmod-common,libnvidia-fbc,kmod-nvidia-*-dkms,nvidia-fs*,nvidia-gds*,xorg-x11-nvidia*"

sudo dnf config-manager setopt "${REPO_ID}.exclude=${EXCLUDE_PKGS}"

log_info "4/5 Instalando cuda-toolkit y runtime xorg-x11-drv-nvidia-cuda..."
sudo dnf install -y cuda-toolkit xorg-x11-drv-nvidia-cuda

log_info "5/5 Configurando variables de entorno globales (/etc/profile.d/cuda.sh)..."
# Expone el compilador nvcc y las librerías compartidas de CUDA en todas las sesiones
sudo tee /etc/profile.d/cuda.sh >/dev/null <<'EOF'
# Rutas del compilador y librerías de NVIDIA CUDA Toolkit
if [ -d "/usr/local/cuda/bin" ]; then
    export PATH="/usr/local/cuda/bin${PATH:+:${PATH}}"
fi

if [ -d "/usr/local/cuda/lib64" ]; then
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi
EOF
sudo chmod +x /etc/profile.d/cuda.sh

log_warn "Se recomienda reiniciar el sistema para cargar las rutas de CUDA y validar el entorno."
read -r -p "¿Deseas reiniciar ahora mismo? [s/N]: " respuesta
case "${respuesta,,}" in
  s|si|sí|y|yes)
    log_info "Reiniciando el equipo..."
    sudo reboot
    ;;
  *)
    log_info "Reinicio pospuesto. Tras reiniciar, verifica con 'nvcc --version' y 'nvidia-smi'."
    ;;
esac