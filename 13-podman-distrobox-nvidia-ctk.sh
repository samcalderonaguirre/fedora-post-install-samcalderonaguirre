#!/usr/bin/env bash
# ==============================================================================
# Script: 13-podman-distrobox-nvidia-ctk.sh
# Objetivo: Instalar Podman y Distrobox en Fedora, habilitar el COPR
#           @ai-ml/nvidia-container-toolkit, instalar NVIDIA Container Toolkit
#           con soporte SELinux, generar la configuración CDI (/etc/cdi/nvidia.yaml)
#           y validar el acceso a la GPU con Podman.
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

for cmd in dnf podman sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ "$cmd" == "dnf" ]]; then
      log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
      exit 1
    fi
  fi
done

sudo -v

log_info "1/5 Instalando Podman y Distrobox..."
sudo dnf install -y podman distrobox xorg-x11-drv-nvidia-cuda

log_info "2/5 Habilitando repositorio COPR @ai-ml/nvidia-container-toolkit..."
sudo dnf copr enable -y @ai-ml/nvidia-container-toolkit

log_info "3/5 Instalando nvidia-container-toolkit y políticas SELinux..."
sudo dnf install -y nvidia-container-toolkit nvidia-container-toolkit-selinux

log_info "4/5 Generando configuración CDI en /etc/cdi/nvidia.yaml..."
sudo mkdir -p /etc/cdi
sudo nvidia-ctk cdi generate --output /etc/cdi/nvidia.yaml

log_info "5/5 Probando acceso a la GPU NVIDIA desde un contenedor Podman..."
if command -v nvidia-smi >/dev/null 2>&1; then
  podman run --device nvidia.com/gpu=all --rm fedora:latest nvidia-smi
else
  log_warn "No se encontró 'nvidia-smi' en el host todavía (¿reiniciaste tras instalar el driver NVIDIA?)."
  log_warn "Si ya tienes el driver activo, prueba luego: podman run --device nvidia.com/gpu=all --rm fedora:latest nvidia-smi"
fi

log_info "Configuración de Podman, Distrobox y NVIDIA Container Toolkit finalizada."