#!/usr/bin/env bash
# ==============================================================================
# Script de Instalación y Configuración Universal para Zsh y Bash
# Compatible con: Fedora / Red Hat Enterprise Linux (RHEL) 10
# ==============================================================================

# Asegurar que se ejecuta con privilegios de root o mediante sudo
if [ "$EUID" -ne 0 ]; then
  echo "[-] Por favor, ejecuta este script como root o usando sudo."
  exit 1
fi

# Detectar el usuario real que invocó sudo (para no configurar todo en HOME de root)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")

if [ "$TARGET_USER" = "root" ]; then
  echo "[!] Advertencia: Estás ejecutando como root directamente. Se recomienda ejecutar con un usuario normal usando sudo."
fi

echo "[+] Actualizando repositorios e instalando dependencias (zsh, git, curl, util-linux-user)..."
dnf install -y zsh git curl util-linux-user util-linux

# ==============================================================================
# 1. CONFIGURACIÓN DE ZSH + OH MY ZSH
# ==============================================================================
echo "[+] Configurando Zsh para el usuario: $TARGET_USER..."

# Directorio de Oh My Zsh para el usuario objetivo
ZSH_CUSTOM_DIR="$TARGET_HOME/.oh-my-zsh/custom"

# Instalar Oh My Zsh de forma no interactiva si no existe
if [ ! -d "$TARGET_HOME/.oh-my-zsh" ]; then
  echo "[+] Instalando Oh My Zsh..."
  su - "$TARGET_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
else
  echo "[*] Oh My Zsh ya está instalado."
fi

# Clonar plugins requeridos
echo "[+] Instalando plugins para Zsh..."
mkdir -p "$ZSH_CUSTOM_DIR/plugins"

declare -A ZSH_PLUGINS=(
  ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
  ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
  ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
  ["zsh-256color"]="https://github.com/chrissicool/zsh-256color"
)

for plugin in "${!ZSH_PLUGINS[@]}"; do
  plugin_path="$ZSH_CUSTOM_DIR/plugins/$plugin"
  if [ ! -d "$plugin_path" ]; then
    echo "    -> Clonando $plugin..."
    git clone "${ZSH_PLUGINS[$plugin]}" "$plugin_path"
  else
    echo "    -> $plugin ya existe. Actualizando..."
    git -C "$plugin_path" pull --quiet
  fi
done

# Configurar el archivo .zshrc
ZSHRC_FILE="$TARGET_HOME/.zshrc"
if [ -f "$ZSHRC_FILE" ]; then
  echo "[+] Configurando tema y plugins en $ZSHRC_FILE..."
  
  # Cambiar tema a obraun
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="obraun"/' "$ZSHRC_FILE"
  
  # Configurar plugins solicitados
  PLUGINS_STR="plugins=(dnf aliases genpass sudo git zsh-256color zsh-autosuggestions zsh-history-substring-search z zsh-syntax-highlighting)"
  if grep -q "^plugins=(" "$ZSHRC_FILE"; then
    sed -i 's/^plugins=(.*)/' "$PLUGINS_STR"'/' "$ZSHRC_FILE"
  else
    echo "$PLUGINS_STR" >> "$ZSHRC_FILE"
  fi
else
  echo "[!] No se encontró .zshrc, generando uno básico..."
  cat << 'EOF' > "$ZSHRC_FILE"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="obraun"
plugins=(dnf aliases genpass sudo git zsh-256color zsh-autosuggestions zsh-history-substring-search z zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
EOF
  chown "$TARGET_USER:$TARGET_USER" "$ZSHRC_FILE"
fi

# Cambiar la shell por defecto del usuario a Zsh
ZSH_PATH=$(which zsh)
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "[+] Cambiando la shell predeterminada a Zsh para $TARGET_USER..."
  chsh -s "$ZSH_PATH" "$TARGET_USER"
fi

# ==============================================================================
# 2. CONFIGURACIÓN DE BASH + OH MY BASH
# ==============================================================================
echo "[+] Configurando Bash con Oh My Bash..."

OMB_DIR="$TARGET_HOME/.oh-my-bash"
if [ ! -d "$OMB_DIR" ]; then
  echo "[+] Instalando Oh My Bash..."
  su - "$TARGET_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended'
else
  echo "[*] Oh My Bash ya está instalado."
fi

# Configurar el tema 'cupcake' en .bashrc
BASHRC_FILE="$TARGET_HOME/.bashrc"
if [ -f "$BASHRC_FILE" ]; then
  echo "[+] Aplicando el tema 'cupcake' en $BASHRC_FILE..."
  if grep -q "^OSH_THEME=" "$BASHRC_FILE"; then
    sed -i 's/^OSH_THEME=.*/OSH_THEME="cupcake"/' "$BASHRC_FILE"
  else
    echo 'OSH_THEME="cupcake"' >> "$BASHRC_FILE"
  fi
fi

# Ajustar permisos de los directorios creados para el usuario destino
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.oh-my-zsh" "$TARGET_HOME/.oh-my-bash" "$ZSHRC_FILE" "$BASHRC_FILE" 2>/dev/null

echo "===================================================================="
echo "[✔] ¡Configuración completada con éxito!"
echo "[*] Se han instalado y configurado Zsh (tema: obraun) y Bash (tema: cupcake)."
echo "[*] Por favor, cierra sesión e inicia de nuevo (o cambia a zsh ejecutando 'zsh') para ver los cambios."
echo "===================================================================="