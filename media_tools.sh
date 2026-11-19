#!/bin/bash

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Master / Edit Codecs (Mantienen espacio de color master 10-bit)
cat << 'EOF' > "$BIN_DIR/to_dnxhr"
#!/bin/bash
ffmpeg -i "$1" -c:v dnxhd -profile:v dnxhr_444 -pix_fmt yuv444p10le -c:a pcm_s16le "${1%.*}_DNxHR444.mov"
EOF

cat << 'EOF' > "$BIN_DIR/to_prores"
#!/bin/bash
ffmpeg -i "$1" -c:v prores_ks -profile:v 3 -vendor apl0 -bits_per_mb 8000 -pix_fmt yuv422p10le -c:a pcm_s16le "${1%.*}_ProResHQ.mov"
EOF

# Codecs Web / Delivery (Fuerzan yuv420p para máxima compatibilidad)
cat << 'EOF' > "$BIN_DIR/to_h264"
#!/bin/bash
ffmpeg -i "$1" -c:v libx264 -pix_fmt yuv420p -preset slow -crf 18 -c:a aac -b:a 320k "${1%.*}_H264.mp4"
EOF

cat << 'EOF' > "$BIN_DIR/to_h265"
#!/bin/bash
ffmpeg -i "$1" -c:v libx265 -pix_fmt yuv420p -preset slow -crf 20 -c:a aac -b:a 320k "${1%.*}_H265.mp4"
EOF

cat << 'EOF' > "$BIN_DIR/to_vp9_yt"
#!/bin/bash
ffmpeg -i "$1" -c:v libvpx-vp9 -pix_fmt yuv420p -b:v 0 -crf 30 -row-mt 1 -c:a libopus "${1%.*}_VP9.webm"
EOF

cat << 'EOF' > "$BIN_DIR/to_av1_yt"
#!/bin/bash
ffmpeg -i "$1" -c:v libaom-av1 -pix_fmt yuv420p -cpu-used 4 -crf 30 -c:a libopus "${1%.*}_AV1.mkv"
EOF

cat << 'EOF' > "$BIN_DIR/to_whatsapp"
#!/bin/bash
ffmpeg -i "$1" -vf "scale=-2:720" -c:v libx264 -pix_fmt yuv420p -profile:v baseline -level 3.0 -preset fast -crf 26 -c:a aac -b:a 128k "${1%.*}_WhatsApp.mp4"
EOF

cat << 'EOF' > "$BIN_DIR/to_social"
#!/bin/bash
ffmpeg -i "$1" -vf "scale=-2:1080" -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -crf 20 -c:a aac -b:a 192k "${1%.*}_Social.mp4"
EOF

chmod +x "$BIN_DIR"/to_*

echo "¡Scripts actualizados con soporte de conversión 4:2:2 -> 4:2:0!"

# 5. Asegurar que ~/.local/bin esté en el PATH de ZSH, Bash y Fish
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
mkdir -p "$HOME/.config/fish"
grep -qxF 'set -gx PATH $HOME/.local/bin $PATH' "$HOME/.config/fish/config.fish" 2>/dev/null || echo 'set -gx PATH $HOME/.local/bin $PATH' >> "$HOME/.config/fish/config.fish"

echo "¡Instalación completada! Reinicia tu terminal o ejecuta 'source ~/.bashrc' (o ~/.zshrc). Uso: to_prores video.mp4"
