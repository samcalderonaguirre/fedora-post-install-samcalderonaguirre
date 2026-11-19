#!/usr/bin/env bash
# ==============================================================================
# Script: 11-virtualizacion-kvm-libvirt.sh
# Objetivo: Verificar soporte de virtualización en CPU (VMX/SVM), instalar
#           @virtualization (QEMU/KVM/Libvirt/virt-manager) y GNOME Boxes,
#           habilitar servicios libvirtd y agregar al usuario a libvirt/kvm.
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

for cmd in dnf grep systemctl usermod; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

log_info "1/5 Verificando soporte de virtualización por hardware en la CPU (VMX Intel / SVM AMD)..."
if grep -E --color=auto '(vmx|svm)' /proc/cpuinfo >/dev/null 2>&1; then
  log_info "Soporte de virtualización detectado en /proc/cpuinfo:"
  grep -E --color=auto '(vmx|svm)' /proc/cpuinfo | head -n 5
else
  log_warn "No se detectaron flags 'vmx' o 'svm' en /proc/cpuinfo."
  log_warn "Revisa si Intel VT-x / AMD-V está habilitado en la BIOS/UEFI o si corres dentro de otra VM sin nested virtualization."
fi

log_info "2/5 Instalando grupo @virtualization (QEMU, KVM, Libvirt, virt-manager) y GNOME Boxes..."
sudo dnf install -y @virtualization gnome-boxes

log_info "3/5 Habilitando e iniciando servicios y sockets de Libvirt..."
# En Fedora moderno, libvirtd puede operar con activación por socket (modular daemons)
# o servicio tradicional según configuración; habilitamos ambos de forma segura.
sudo systemctl enable --now libvirtd.socket 2>/dev/null || true
sudo systemctl enable --now libvirtd 2>/dev/null || true

log_info "4/5 Agregando al usuario '$USER' a los grupos 'libvirt' y 'kvm'..."
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"

log_info "5/5 Comprobando estado del servicio y membresía de grupos..."
id -nG "$USER" | grep -E --color=auto "libvirt|kvm" || true

log_warn "Los cambios de grupo en la sesión activa requieren cerrar sesión/reiniciar o usar 'newgrp libvirt' en una nueva terminal."
read -r -p "¿Deseas abrir 'virt-manager' ahora mismo? [s/N]: " respuesta
case "${respuesta,,}" in
  s|si|sí|y|yes)
    if command -v virt-manager >/dev/null 2>&1; then
      log_info "Iniciando virt-manager..."
      # Se lanza desacoplado para no bloquear la salida del script
      nohup virt-manager >/dev/null 2>&1 &
    else
      log_warn "No se encontró 'virt-manager' en el PATH."
    fi
    ;;
  *)
    log_info "Configuración de virtualización completada. Puedes lanzar 'virt-manager' o 'gnome-boxes' cuando gustes."
    ;;
esac