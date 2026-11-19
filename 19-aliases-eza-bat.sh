#!/usr/bin/env bash
# ==============================================================================
# Script: 19-aliases-eza-bat.sh
# Objetivo: Instalar eza y bat en Fedora, crear ~/.bash_aliases con los
#           alias definidos (DNF, eza, bat, cls, update-grub y clima) y
#           configurar su carga automática en Bash (~/.bashrc) y Zsh (~/.zshrc).
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

ALIASES_FILE="$HOME/.bash_aliases"
SOURCE_SNIPPET='if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi'

log_info "1/3 Instalando eza y bat desde los repositorios de Fedora..."
sudo dnf install -y --skip-unavailable eza bat

log_info "2/3 Creando/actualizando $ALIASES_FILE..."
cat <<'EOF' > "$ALIASES_FILE"
# Alias para gestión de paquetes (DNF)
alias update='sudo dnf update --refresh'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='sudo dnf search'

# Alias para visualización de archivos y directorios
alias lha='eza -lha --icons'
alias ver='bat'

# Limpieza
alias cls='clear'

# Actualizar GRUB
alias update-grub='sudo grub2-mkconfig -o /boot/grub2/grub.cfg'

# Clima
alias clima='curl wttr.in/machala'
EOF

log_info "3/3 Configurando carga de ~/.bash_aliases en ~/.bashrc y ~/.zshrc..."
touch "$HOME/.bashrc" "$HOME/.zshrc"

if ! grep -Fq ".bash_aliases" "$HOME/.bashrc"; then
  printf '\n# Cargar alias personalizados\n%s\n' "$SOURCE_SNIPPET" >> "$HOME/.bashrc"
else
  log_warn "~/.bash_aliases ya está referenciado en ~/.bashrc; se omite duplicado."
fi

if ! grep -Fq ".bash_aliases" "$HOME/.zshrc"; then
  printf '\n# Cargar alias personalizados\n%s\n' "$SOURCE_SNIPPET" >> "$HOME/.zshrc"
else
  log_warn "~/.bash_aliases ya está referenciado en ~/.zshrc; se omite duplicado."
fi

log_info "Verificando binarios eza y bat..."
command -v eza >/dev/null 2>&1 && eza --version | head -n 2 || log_warn "No se encontró 'eza' en el PATH."
command -v bat >/dev/null 2>&1 && bat --version || log_warn "No se encontró 'bat' en el PATH."

log_info "Configuración de ~/.bash_aliases, eza y bat completada. Abre una nueva terminal o ejecuta '. ~/.bash_aliases'."