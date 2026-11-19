#!/usr/bin/env bash
# ==============================================================================
# Script: 22-pipewire-wireplumber-ardour9.sh
# Objetivo: Configurar parámetros fijos de reloj y quantum en WirePlumber
#           (~/.config/wireplumber/wireplumber.conf.d/99-ardour-stability.conf)
#           para evitar cierres inesperados de Ardour 9 al usar JACK/PipeWire
#           en Fedora 45+, y reiniciar los servicios de audio de usuario.
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
  log_error "Ejecuta este script como usuario normal (modifica \$HOME/.config y servicios --user)."
  exit 1
fi

for cmd in systemctl pw-metadata; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_warn "No se encontró '$cmd' en el PATH; verifica que PipeWire esté instalado."
  fi
done

CONF_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
CONF_FILE="$CONF_DIR/99-ardour-stability.conf"

log_info "1/3 Creando directorio de configuración $CONF_DIR..."
mkdir -p "$CONF_DIR"

log_info "2/3 Escribiendo parámetros de estabilidad en $CONF_FILE..."
cat <<'EOF' > "$CONF_FILE"
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 512
    default.clock.min-quantum = 512
    default.clock.max-quantum = 512
}
EOF

log_info "3/3 Reiniciando servicios de audio de usuario (wireplumber, pipewire y pipewire-pulse)..."
if systemctl --user is-active --quiet pipewire-pulse.service 2>/dev/null; then
  systemctl --user restart wireplumber pipewire pipewire-pulse
else
  systemctl --user restart wireplumber pipewire
fi

log_info "Verificando estado de los servicios y metadatos activos de PipeWire..."
systemctl --user --no-pager --full status wireplumber pipewire | grep -E "●|Loaded:|Active:" || true

if command -v pw-metadata >/dev/null 2>&1; then
  pw-metadata -n settings 0 | grep -E "clock\.(rate|quantum|min-quantum|max-quantum)" || true
fi

log_info "Configuración de PipeWire/WirePlumber para Ardour 9 completada."