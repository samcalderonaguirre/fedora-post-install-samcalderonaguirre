#!/usr/bin/env bash
# ==============================================================================
# Script: 04-multimedia-codecs-flatpak.sh
# Objetivo: Configurar multimedia y códecs en Fedora (FFmpeg completo,
#           @multimedia, drivers Intel/NVIDIA VA-API, repos tainted, Flathub,
#           compresores, reproductores de audio y codificadores de video).
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

for cmd in dnf flatpak; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

log_info "1/7 Cambiando ffmpeg-free por ffmpeg completo desde RPM Fusion..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

log_info "2/7 Instalando grupo @multimedia (sin dependencias débiles ni PackageKit-gstreamer-plugin)..."
sudo dnf install -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

log_info "3/7 Instalando drivers multimedia Intel (VA-API / iHD / i965) y puente NVIDIA..."
# intel-media-driver: GPUs Intel modernas (Broadwell en adelante, iHD)
# libva-intel-driver: GPUs Intel más antiguas (i965 legacy)
sudo dnf install -y intel-media-driver libva-intel-driver
# Mantiene libva-nvidia-driver presente si este script corre de forma independiente
sudo dnf install -y libva-nvidia-driver

log_info "4/7 Habilitando repositorios RPM Fusion tainted (DVD y firmwares adicionales)..."
sudo dnf install -y rpmfusion-free-release-tainted
sudo dnf install -y libdvdcss

sudo dnf install -y rpmfusion-nonfree-release-tainted
sudo dnf install -y --repo=rpmfusion-nonfree-tainted "*-firmware"

log_info "5/7 Agregando repositorio Flathub para el usuario si no existe..."
# --if-not-exists garantiza idempotencia si ya fue agregado previamente
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

log_info "6/7 Instalando códecs GStreamer, OpenH264, cargadores de imagen, compresores y reproductores..."
sudo dnf install -y \
  gstreamer1-libav \
  gstreamer1-plugins-bad-free-extras \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-good-extras \
  gstreamer1-plugins-ugly \
  unrar \
  p7zip \
  p7zip-plugins \
  gstreamer1-plugin-openh264 \
  mozilla-openh264 \
  openh264 \
  webp-pixbuf-loader \
  gstreamer1-plugins-bad-free-fluidsynth \
  gstreamer1-plugins-bad-free-wildmidi \
  libopenraw-pixbuf-loader \
  dav1d \
  file-roller \
  audacious \
  deadbeef

log_info "7/7 Instalando soporte GStreamer VA-API y herramientas/librerías de renderizado de video..."
sudo dnf install -y \
  gstreamer1-vaapi \
  libva \
  libva-utils \
  x264 \
  h264enc \
  x265 \
  svt-av1 \
  rav1e

log_info "Configuración multimedia y de códecs completada."