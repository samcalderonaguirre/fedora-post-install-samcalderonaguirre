#!/usr/bin/env bash
# ==============================================================================
# Script: 08-navegadores-apps-y-herramientas.sh
# Objetivo: Optimizar DNF, habilitar SSH y desplegar utilidades CLI,
#           navegadores (Chrome, Edge, Brave, Chromium, LibreWolf, Zen),
#           mensajería (Thunderbird, Discord, Telegram, Signal, Tor) y
#           herramientas de desarrollo/productividad (KeePassXC, VS Code,
#           VSCodium, GitHub Desktop y Podman) en Fedora.
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

# Función auxiliar para añadir parámetros en /etc/dnf/dnf.conf sin duplicarlos
set_dnf_option() {
  local key="$1"
  local value="$2"
  local conf="/etc/dnf/dnf.conf"

  if grep -qE "^${key}=" "$conf"; then
    sudo sed -i "s/^${key}=.*/${key}=${value}/" "$conf"
  else
    echo "${key}=${value}" | sudo tee -a "$conf" >/dev/null
  fi
}

log_info "1/6 Optimizando /etc/dnf/dnf.conf y habilitando servicio SSH..."
if [[ ! -f /etc/dnf/dnf.conf.bak ]]; then
  sudo cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
fi
set_dnf_option "max_parallel_downloads" "10"
set_dnf_option "fastestmirror" "True"
set_dnf_option "defaultyes" "True"

sudo dnf install -y dnf-plugins-core openssh-server
sudo systemctl enable --now sshd

log_info "2/6 Instalando utilidades CLI y de sistema..."
sudo dnf install -y \
  mc btop htop rsync inxi ncdu tilix tmux fastfetch \
  unzip unrar git wget curl

log_info "3/6 Instalando navegadores web (Chrome, Chromium, Brave, Edge, LibreWolf y Zen)..."
# Google Chrome (habilita repo de terceros incluido en Fedora Workstation o lo crea)
if dnf repolist --all | grep -q "google-chrome"; then
  sudo dnf config-manager setopt google-chrome.enabled=1
else
  sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
fi
sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub
sudo dnf install -y google-chrome-stable

# Chromium
sudo dnf install -y chromium

# Brave Browser
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo tee /etc/yum.repos.d/brave-browser.repo >/dev/null <<'EOF'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/$basearch
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF
sudo dnf install -y brave-browser

# Microsoft Edge (usando archivo .repo explícito para evitar fallos en DNF5)
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/microsoft-edge.repo >/dev/null <<'EOF'
[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf install -y microsoft-edge-stable

# LibreWolf y Zen Browser vía Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive flathub io.gitlab.librewolf-community app.zen_browser.zen

log_info "4/6 Instalando correo, mensajería y red Tor..."
sudo dnf install -y thunderbird discord telegram-desktop tor
sudo systemctl enable --now tor
flatpak install -y --noninteractive flathub org.signal.Signal org.torproject.torbrowser-launcher

log_info "5/6 Instalando herramientas de productividad, desarrollo y contenedores..."
# KeePassXC y Podman
sudo dnf install -y keepassxc podman

# Visual Studio Code
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sudo dnf install -y code

# VSCodium (sobrescribe el .repo limpiamente en vez de duplicarlo con tee -a)
sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
sudo tee /etc/yum.repos.d/vscodium.repo >/dev/null <<'EOF'
[gitlab.com_paulcarroty_vscodium_repo]
name=download.vscodium.com
baseurl=https://download.vscodium.com/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
metadata_expire=1h
EOF
sudo dnf install -y codium

# GitHub Desktop (Flatpak)
flatpak install -y --noninteractive flathub io.github.shiftey.Desktop

log_info "6/6 Verificando estado general de instalación..."
rpm -q google-chrome-stable microsoft-edge-stable brave-browser chromium code codium podman keepassxc || true

log_info "Instalación de navegadores, aplicaciones y complementos completada."