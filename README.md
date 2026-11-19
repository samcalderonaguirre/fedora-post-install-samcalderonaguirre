# fedora-post-install-samcalderonaguirre

Scripts de post-instalación para **Fedora 45 o superior**, diseñados para automatizar, estandarizar y mantener de forma modular la configuración de mi estación de trabajo: repositorios, drivers propietarios de NVIDIA y ajuste en Wayland, códecs multimedia, virtualización con KVM/Libvirt, contenedores con Podman/Distrobox y NVIDIA Container Toolkit, Homebrew, Cargo/Rust, utilidades CLI, aplicaciones nativas/Flatpak, suites de desarrollo/ofimática y flujos de conversión de video con FFmpeg.

## Características de la arquitectura

- **Diseño modular por etapas:** Cada componente o flujo de trabajo está encapsulado en un script independiente para poder ejecutar toda la estación de trabajo o únicamente un bloque específico cuando lo necesites.
- **Idempotencia y control de errores:** Los scripts están concebidos para ejecutarse desde un usuario normal (solicitando `sudo` cuando corresponde) con `set -euo pipefail`, evitando duplicar líneas en archivos de shell o romper configuraciones preexistentes.
- **Protección de drivers gráficos:** Al configurar el repositorio oficial de CUDA, se excluyen explícitamente los paquetes de drivers del repositorio de NVIDIA para proteger la instalación del driver propietario de RPM Fusion y evitar conflictos con la sesión Wayland o los módulos del kernel.
- **Consistencia multi-shell:** Los directorios de binarios personales (`~/.local/bin`), herramientas como Homebrew y Cargo, y los alias de terminal se contemplan en **Bash** (`~/.bashrc`), **Zsh** (`~/.zshrc`) y **Fish** (`~/.config/fish/config.fish`) según corresponda.

## Requisitos previos

1. Una instalación operativa de **Fedora Workstation (F45+)** con conexión a Internet.
2. Una cuenta de usuario estándar con permisos de `sudo`.
3. `git` disponible en el sistema para clonar el repositorio (si no lo tienes instalado aún, puedes obtenerlo con `sudo dnf install -y git`).

## Instalación y uso

### 1. Clonar el repositorio

```bash
git clone https://github.com/samcalderonaguirre/fedora-post-install-samcalderonaguirre.git
cd fedora-post-install-samcalderonaguirre
```

### 2. Dar permisos de ejecución a los scripts

```bash
chmod +x *.sh
```

### 3. Ejecutar scripts de forma individual o secuencial

Para ejecutar un script concreto y aplicar o revisar un ajuste específico:

```bash
./09-cuda-toolkit.sh
```

Para ejecutar los scripts en orden secuencial según las etapas de tu estación de trabajo:

```bash
for script in 01-*.sh 02-*.sh ...; do
  if [[ -f "$script" ]]; then
    echo "=== Ejecutando $script ==="
    "$script"
  fi
done
```

> **Reinicios y reapertura de sesión:** Algunos cambios —como la instalación de drivers gráficos/CUDA o la incorporación a los grupos `libvirt` y `kvm`— requieren reiniciar el equipo o abrir una nueva sesión/terminal para que los módulos, variables de entorno o membresías de grupo entren en vigor plenamente.

## Áreas cubiertas por los scripts

| Área | Qué configura o instala | Comprobación rápida |
| :--- | :--- | :--- |
| **Repositorios y base del sistema** | Repositorios adicionales (RPM Fusion, COPR y Terra con prioridad `110`), actualizaciones vía DNF y paquetes base. | `dnf repolist --enabled` |
| **NVIDIA y Wayland** | Driver propietario NVIDIA, ajustes para sesiones Wayland y componentes de espacio de usuario para aceleración/CUDA. | `nvidia-smi` |
| **Códecs y utilidades** | Plugins y desarrollo de GStreamer, `ffmpeg`, `ffmpegthumbnailer`, `frei0r`, soporte Blu-ray, `v4l-utils`, MTP/exFAT y compresores. | `ffmpeg -version` |
| **Virtualización (KVM/Libvirt)** | Comprobación de `vmx`/`svm`, grupo `@virtualization`, `gnome-boxes`, servicios `libvirtd` y grupos `libvirt` y `kvm`. | `virsh list --all` / `id -nG` |
| **Contenedores y GPU CDI** | `podman`, `distrobox`, `nvidia-container-toolkit` con soporte SELinux y generación de `/etc/cdi/nvidia.yaml`. | `podman run --device nvidia.com/gpu=all --rm fedora:latest nvidia-smi` |
| **Homebrew y herramientas CLI** | Dependencias de compilación, instalación de Homebrew, configuración en Bash/Zsh y herramientas como `broot`, `joshuto`, `lf` y `tty-clock`. | `brew --version` |
| **Cargo y Rust** | Paquetes `cargo` y `rust`, además de añadir `$HOME/.cargo/bin` al `PATH` en `~/.bashrc` y `~/.zshrc`. | `cargo --version` |
| **Aplicaciones DNF y Flatpak** | Aplicaciones de diseño, audio, video, ofimática, terminales y monitoreo vía DNF, junto con aplicaciones desde Flathub. | `flatpak list --app` |
| **Conversión de video (`~/.local/bin`)** | Scripts `to_dnxhr`, `to_prores`, `to_h264`, `to_h265`, `to_vp9_yt`, `to_av1_yt`, `to_whatsapp` y `to_social`, asegurando `~/.local/bin` en el `PATH`. | `ls -la ~/.local/bin/to_*` |
| **Alias y utilidades de terminal** | Instalación de `eza` y `bat`, creación de `~/.bash_aliases` y carga automática en `~/.bashrc` y `~/.zshrc`. | `eza --version` / `bat --version` |
| **Herramientas y suites adicionales** | Paquetes y entornos complementarios como `lgl-vm-curator`, `onlyoffice-desktopeditors` y `pycharm-community`. | `rpm -q onlyoffice-desktopeditors pycharm-community` |

## Recomendaciones de uso y mantenimiento

- **Personalización propia:** Este repositorio refleja mi entorno de trabajo, preferencias y hardware en Fedora 45+; revisa cada script antes de ejecutarlo en otro equipo.
- **Orden y numeración:** Conserva la numeración correlativa y documenta cualquier dependencia previa al incorporar nuevos scripts o un script orquestador.
- **Recarga del entorno:** Después de modificar `~/.bashrc`, `~/.zshrc` o `~/.config/fish/config.fish`, abre una nueva terminal o recarga el archivo correspondiente para aplicar rutas y alias.

## Licencia

Uso personal y de referencia. Si reutilizas o adaptas estos scripts, valídalos según tu versión de Fedora y configuración de hardware.