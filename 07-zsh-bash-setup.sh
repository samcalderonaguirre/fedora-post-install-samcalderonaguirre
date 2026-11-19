#!/usr/bin/env bash
# ==============================================================================
# Script: 07-zsh-bash-setup.sh
# Objetivo: Instalar y personalizar Zsh (Oh My Zsh, tema obraun y plugins)
#           y Bash (Oh My Bash y tema cupcake) para el usuario en Fedora.
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

for cmd in dnf sudo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "No se encontró '$cmd'. Este script está pensado para Fedora."
    exit 1
  fi
done

sudo -v

TARGET_USER="$USER"
TARGET_HOME="$HOME"

log_info "1/3 Instalando paquetes base (zsh, git, curl, util-linux-user, util-linux)..."
sudo dnf install -y zsh git curl util-linux-user util-linux

log_info "2/3 Configurando Zsh + Oh My Zsh para '$TARGET_USER'..."
OMZ_DIR="$TARGET_HOME/.oh-my-zsh"
ZSH_CUSTOM_DIR="$OMZ_DIR/custom"
ZSHRC_FILE="$TARGET_HOME/.zshrc"

if [[ ! -d "$OMZ_DIR" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  log_warn "Oh My Zsh ya existe en $OMZ_DIR; se omite reinstalación."
fi

mkdir -p "$ZSH_CUSTOM_DIR/plugins"

declare -A ZSH_PLUGINS=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
  ["zsh-256color"]="https://github.com/chrissicool/zsh-256color"
)

for plugin in "${!ZSH_PLUGINS[@]}"; do
  plugin_path="$ZSH_CUSTOM_DIR/plugins/$plugin"
  if [[ ! -d "$plugin_path" ]]; then
    log_info "Clonando plugin $plugin..."
    git clone --depth=1 "${ZSH_PLUGINS[$plugin]}" "$plugin_path"
  else
    log_warn "Plugin $plugin ya existe; actualizando..."
    git -C "$plugin_path" pull --ff-only --quiet || true
  fi
done

PLUGINS_LINE='plugins=(dnf aliases genpass sudo git zsh-256color zsh-autosuggestions zsh-history-substring-search z zsh-syntax-highlighting)'

if [[ -f "$ZSHRC_FILE" ]]; then
  if grep -qE '^ZSH_THEME=' "$ZSHRC_FILE"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="obraun"/' "$ZSHRC_FILE"
  else
    echo 'ZSH_THEME="obraun"' >> "$ZSHRC_FILE"
  fi

  if grep -qE '^plugins=\(' "$ZSHRC_FILE"; then
    sed -i "s/^plugins=(.*)/${PLUGINS_LINE}/" "$ZSHRC_FILE"
  else
    echo "$PLUGINS_LINE" >> "$ZSHRC_FILE"
  fi
else
  cat > "$ZSHRC_FILE" <<EOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="obraun"
${PLUGINS_LINE}
source \$ZSH/oh-my-zsh.sh
EOF
fi

ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  log_info "Cambiando shell predeterminada de '$TARGET_USER' a $ZSH_PATH..."
  sudo chsh -s "$ZSH_PATH" "$TARGET_USER"
fi

log_info "3/3 Configurando Bash + Oh My Bash (tema cupcake) para '$TARGET_USER'..."
OMB_DIR="$TARGET_HOME/.oh-my-bash"
BASHRC_FILE="$TARGET_HOME/.bashrc"

if [[ ! -d "$OMB_DIR" ]]; then
  OSH_CUSTOM="" RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
else
  log_warn "Oh My Bash ya existe en $OMB_DIR; se omite reinstalación."
fi

if [[ -f "$BASHRC_FILE" ]]; then
  if grep -qE '^OSH_THEME=' "$BASHRC_FILE"; then
    sed -i 's/^OSH_THEME=.*/OSH_THEME="cupcake"/' "$BASHRC_FILE"
  else
    echo 'OSH_THEME="cupcake"' >> "$BASHRC_FILE"
  fi
fi

sudo chown -R "$TARGET_USER:$TARGET_USER" "$OMZ_DIR" "$OMB_DIR" "$ZSHRC_FILE" "$BASHRC_FILE" 2>/dev/null || true

log_info "Configuración de Zsh y Bash finalizada. Cierra sesión o ejecuta 'zsh' para probar."