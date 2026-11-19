#!/usr/bin/env bash
# ==============================================================================
# Script: 18-scripts-conversion-multimedia.sh
# Objetivo: Crear en ~/.local/bin un conjunto de scripts de conversión de
#           video con FFmpeg (DNxHR 444, ProRes HQ, H.264, H.265, VP9, AV1,
#           WhatsApp y Social) y asegurar ~/.local/bin en el PATH de Bash,
#           Zsh y Fish.
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
  log_error "Ejecuta este script como usuario normal (los scripts van en \$HOME/.local/bin)."
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  log_warn "No se encontró 'ffmpeg' en el PATH actual. Asegúrate de tener FFmpeg instalado antes de convertir archivos."
fi

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

log_info "1/3 Generando scripts de edición/master (DNxHR 444 y ProRes HQ) en $BIN_DIR..."

cat <<'EOF' > "$BIN_DIR/to_dnxhr"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -c:v dnxhd -profile:v dnxhr_444 -pix_fmt yuv444p10le -c:a pcm_s16le "${1%.*}_DNxHR444.mov"
EOF

cat <<'EOF' > "$BIN_DIR/to_prores"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -c:v prores_ks -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv422p10le -c:a pcm_s16le "${1%.*}_ProResHQ.mov"
EOF

log_info "2/3 Generando scripts de entrega/web/redes (H.264, H.265, VP9, AV1, WhatsApp y Social)..."

cat <<'EOF' > "$BIN_DIR/to_h264"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -c:v libx264 -pix_fmt yuv420p -preset slow -crf 18 -c:a aac -b:a 320k "${1%.*}_H264.mp4"
EOF

cat <<'EOF' > "$BIN_DIR/to_h265"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -c:v libx265 -pix_fmt yuv420p -preset slow -crf 20 -c:a aac -b:a 320k "${1%.*}_H265.mp4"
EOF

cat <<'EOF' > "$BIN_DIR/to_vp9_yt"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -c:v libvpx-vp9 -pix_fmt yuv420p -b:v 0 -crf 30 -row-mt 1 -c:a libopus "${1%.*}_VP9.webm"
EOF

cat <<'EOF' > "$BIN_DIR/to_av1_yt"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -c:v libaom-av1 -pix_fmt yuv420p -cpu-used 4 -crf 30 -c:a libopus "${1%.*}_AV1.mkv"
EOF

cat <<'EOF' > "$BIN_DIR/to_whatsapp"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -vf "scale=-2:720" -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 -preset fast -crf 26 -c:a aac -b:a 128k "${1%.*}_WhatsApp.mp4"
EOF

cat <<'EOF' > "$BIN_DIR/to_social"
#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 || ! -f "$1" ]]; then
  echo "Uso: $(basename "$0") <archivo_entrada>" >&2
  exit 1
fi
ffmpeg -i "$1" -vf "scale=-2:1080" -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -crf 20 -c:a aac -b:a 192k "${1%.*}_Social.mp4"
EOF

chmod +x "$BIN_DIR"/to_*

log_info "3/3 Configurando ~/.local/bin en el PATH de Bash, Zsh y Fish..."
touch "$HOME/.bashrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config/fish"
touch "$HOME/.config/fish/config.fish"

grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
grep -qxF 'set -gx PATH $HOME/.local/bin $PATH' "$HOME/.config/fish/config.fish" || echo 'set -gx PATH $HOME/.local/bin $PATH' >> "$HOME/.config/fish/config.fish"

export PATH="$HOME/.local/bin:$PATH"

log_info "Scripts creados y permisos aplicados en $BIN_DIR. Ejemplo de uso: to_prores video.mp4"