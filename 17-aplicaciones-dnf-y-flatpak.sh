#!/usr/bin/env bash
# ==============================================================================
# Script: 17-aplicaciones-dnf-y-flatpak.sh
# Objetivo: Instalar el conjunto de aplicaciones nativas (DNF) de diseño,
#           multimedia/audio, ofimática, terminales y sistema, así como las
#           aplicaciones de usuario vía Flatpak (Flathub) en Fedora.
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

for cmd in dnf flatpak sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

log_info "1/2 Instalando aplicaciones nativas vía DNF..."
sudo dnf install -y --skip-unavailable \
  kate geany darktable digikam simple-scan eog inkscape kolourpaint krita okular gimp scribus \
  evince loupe gnome-connections video-downloader qbittorrent remmina torbrowser-launcher thunderbird \
  ardour9 audacity snapshot carla hydrogen k3b kamoso kdenlive lmms mpv gnome-music \
  obs-studio gcdmaster qtractor decibels totem vlc yoshimi \
  gnome-calendar libreoffice libreoffice-langpack-es hunspell-es \
  alacritty thunar btop htop gnome-disk-utility cpu-x kdiskmark kitty \
  gnome-system-monitor nvtop ranger gnome-software ptyxis yakuake \
  ark gnome-calculator gnome-characters gnome-text-editor gnome-font-viewer kleopatra gnome-maps

log_info "2/2 Asegurando repositorio Flathub e instalando aplicaciones Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

FLATPAK_APPS=(
  app.drey.Warp
  app.zen_browser.zen
  be.alexandervanhee.gradia
  br.eng.silas.qpdftools
  chat.simplex.simplex
  com.belmoussaoui.Authenticator
  com.belmoussaoui.Decoder
  com.boxy_svg.BoxySVG
  com.github.Matoking.protontricks
  com.github.huluti.Curtail
  com.github.ryonakano.reco
  com.github.tchx84.Flatseal
  com.github.tenderowl.frog
  com.jeffser.Alpaca
  com.logseq.Logseq
  com.protonvpn.www
  com.rafaelmardojai.Blanket
  com.ranfdev.DistroShelf
  com.rustdesk.RustDesk
  com.sidevesh.Luminance
  com.spotify.Client
  com.stremio.Stremio
  com.usebottles.bottles
  com.warlordsoftwares.formatlab
  de.haeckerfelix.AudioSharing
  dev.geopjr.Collision
  eu.betterbird.Betterbird
  eu.fortysixandtwo.chessclock
  im.riot.Riot
  io.bassi.Amberol
  io.freetubeapp.FreeTube
  io.github.cudatext.CudaText-Qt
  io.github.fizzyizzy05.binary
  io.github.flattool.Warehouse
  io.github.giantpinkrobots.flatsweep
  io.github.kolunmi.Bazaar
  io.github.mrvladus.List
  io.github.peazip.PeaZip
  io.github.seadve.Kooha
  io.github.seadve.Mousai
  io.github.shiftey.Desktop
  io.github.vmkspv.lenspect
  io.github.zingytomato.netpeek
  io.gitlab.adhami3310.Converter
  io.gitlab.adhami3310.Impression
  io.gitlab.librewolf-community
  io.gitlab.liferooter.TextPieces
  io.gitlab.theevilskeleton.Upscaler
  io.missioncenter.MissionCenter
  io.podman_desktop.PodmanDesktop
  it.mijorus.gearlever
  md.obsidian.Obsidian
  net.cozic.joplin_desktop
  net.davidotek.pupgui2
  net.scribus.Scribus
  nl.hjdskes.gcolor3
  org.blender.Blender
  org.cutwire.Drift
  org.gnome.World.Citations
  org.gnome.World.PikaBackup
  org.gnome.World.Secrets
  org.gnome.design.Lorem
  org.gnome.gitlab.YaLTeR.VideoTrimmer
  org.gnome.gitlab.somas.Apostrophe
  org.onionshare.OnionShare
  org.signal.Signal
  org.torproject.torbrowser-launcher
  org.upscayl.Upscayl
  page.codeberg.JakobDev.jdPixelUpscaler
  page.kramo.Sly
)

flatpak install -y --noninteractive --or-update flathub "${FLATPAK_APPS[@]}"

log_info "Instalación de aplicaciones DNF y Flatpak completada."