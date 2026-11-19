#!/usr/bin/env bash
# ==============================================================================
# Script: 10-codecs-adicionales-y-utilidades.sh
# Objetivo: Instalar pila completa de desarrollo y plugins GStreamer,
#           utilidades y librerías avanzadas de audio/video (FFmpeg, frei0r,
#           Blu-ray, V4L2), soporte de dispositivos MTP / sistemas de archivos
#           exFAT y herramientas completas de compresión/descompresión en Fedora.
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

log_info "1/6 Instalando plugins GStreamer completos y cabeceras de desarrollo..."
# Nota: En Fedora el paquete libav se nombra gstreamer1-plugin-libav (o gstreamer1-libav según versión).
sudo dnf install -y --skip-unavailable \
  gstreamer1-devel \
  gstreamer1-plugins-base-devel \
  gstreamer1-plugins-bad-free-devel \
  gstreamer1-plugins-base \
  gstreamer1-plugins-good \
  gstreamer1-plugins-bad-free \
  gstreamer1-plugins-bad-freeworld \
  gstreamer1-plugins-ugly \
  gstreamer1-plugin-libav \
  gstreamer1-plugins-base-tools

log_info "2/6 Instalando FFmpeg, generador de miniaturas y librerías/herramientas de codificación..."
sudo dnf install -y --skip-unavailable \
  ffmpeg \
  ffmpegthumbnailer \
  libavcodec-freeworld \
  vorbis-tools \
  faac \
  twolame \
  twolame-libs \
  libquicktime \
  libquicktime-utils \
  mencoder \
  x264 \
  x265 \
  opus-tools \
  flac \
  svt-av1 \
  libaom \
  aom \
  eog-plugins \
  libopenraw \
  lame \
  opus \
  libopusenc \
  frei0r-plugins \
  xvidcore

log_info "3/6 Instalando backend multimedia Qt6 (Phonon) y soporte Blu-ray..."
sudo dnf install -y --skip-unavailable \
  phonon-qt6 \
  libbluray \
  libbluray-utils \
  libbluray-bdj

log_info "4/6 Instalando utilidades Video4Linux (cámaras/capturadoras)..."
sudo dnf install -y --skip-unavailable v4l-utils

log_info "5/6 Instalando soporte para dispositivos móviles MTP y sistemas de archivos exFAT..."
sudo dnf install -y --skip-unavailable \
  libmtp-examples \
  jmtpfs \
  gvfs-mtp \
  gvfs-fuse \
  exfatprogs

log_info "6/6 Instalando suite completa de compresores y archivadores..."
sudo dnf install -y --skip-unavailable \
  unrar \
  unar \
  p7zip \
  p7zip-plugins \
  sharutils \
  arj \
  zip \
  uudeview \
  cabextract \
  file-roller \
  lzip \
  xz \
  lzop \
  bzip2 \
  lbzip2 \
  cpio \
  unzip \
  gzip

log_info "Instalación de códecs adicionales, soporte de hardware/dispositivos y compresores finalizada."