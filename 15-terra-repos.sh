#!/usr/bin/env bash
# ==============================================================================
# Script: 15-terra-repos.sh
# Objetivo: Añadir el repositorio Terra en Fedora, establecer su prioridad en
#           110 (por debajo de Fedora y RPM Fusion), instalar terra-release y
#           refrescar/actualizar paquetes con DNF.
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

TERRA_REPO_URL="https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo"

log_info "1/3 Añadiendo repositorio Terra..."
# --overwrite permite reejecutar el script sin error si terra.repo ya existe
sudo dnf config-manager addrepo --overwrite --from-repofile="$TERRA_REPO_URL"

log_info "2/3 Configurando prioridad terra.priority=110 (menor prioridad que Fedora/RPM Fusion)..."
# En DNF, un número de prioridad mayor (ej. 110 frente al valor por defecto 99)
# significa menor preferencia frente a repositorios base como Fedora o RPM Fusion.
sudo dnf config-manager setopt "terra*.priority=110"

log_info "3/3 Instalando terra-release y refrescando/actualizando el sistema..."
sudo dnf install -y --nogpgcheck terra-release
sudo dnf --refresh upgrade -y

log_info "Configuración del repositorio Terra completada."