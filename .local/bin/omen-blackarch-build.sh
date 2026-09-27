#!/usr/bin/env bash
# omen-blackarch-build.sh
# Construye el sistema BlackArch independiente en /var/lib/machines/
# Solo necesita ejecutarse UNA VEZ (o cuando se quiere reconstruir)
set -euo pipefail

machine_name="blackarch-omen-lab"
rootfs="/var/lib/machines/${machine_name}"
default_user="blackarch"
ax_shell_repo="https://github.com/Axenide/Ax-Shell.git"
ax_shell_dir="/home/${default_user}/.config/Ax-Shell"
build_marker="${rootfs}/root/.omen_blackarch_built"
ax_shell_marker="${rootfs}/home/${default_user}/.local/state/omen-ax-shell-ready"
log_file="/var/log/omen-blackarch-build.log"

# ─── Helpers ───────────────────────────────────────────────────────────────────
log() { echo -e "\033[1;32m[BUILD]\033[0m $*" | tee -a "$log_file"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" | tee -a "$log_file" >&2; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root (sudo)." >&2
    exit 1
  fi
}

run_in_nspawn() {
  # Corre un comando dentro del nspawn sin iniciar servicios completos
  systemd-nspawn \
    --directory="$rootfs" \
    --machine="$machine_name" \
    --hostname=blackarch-lab \
    --capability=all \
    --bind-ro=/etc/resolv.conf:/etc/resolv.conf \
    /bin/bash -lc "$1"
}

run_as_user() {
  # Corre un comando como el usuario blackarch dentro del nspawn
  systemd-nspawn \
    --directory="$rootfs" \
    --machine="$machine_name" \
    --hostname=blackarch-lab \
    --capability=all \
    --bind-ro=/etc/resolv.conf:/etc/resolv.conf \
    --user="$default_user" \
    /bin/bash -lc "cd /home/${default_user} && $1"
}

# ─── Fase 1: Crear rootfs base con pacstrap ────────────────────────────────────
build_base() {
  if [[ -f "$build_marker" ]]; then
    log "Sistema base ya construido. Saltando pacstrap."
    return 0
  fi

  log "=== FASE 1: Construyendo sistema base con pacstrap ==="
  log "Destino: $rootfs"

  # Verificar que arch-install-scripts esté disponible
  if ! command -v pacstrap &>/dev/null; then
    log "Instalando arch-install-scripts en host..."
    pacman -Sy --needed --noconfirm arch-install-scripts
  fi

  mkdir -p "$rootfs"

  log "Ejecutando pacstrap (puede tomar unos minutos)..."
  pacstrap -K "$rootfs" \
    base base-devel linux-firmware \
    sudo git curl wget unzip \
    networkmanager \
    bash zsh fish \
    nano vim \
    python python-pip \
    wayland wayland-protocols \
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-user-dirs \
    wl-clipboard wl-copy \
    foot \
    pipewire pipewire-pulse wireplumber \
    2>&1 | tee -a "$log_file"

  log "Configurando sistema base..."

  # Locale y timezone
  run_in_nspawn "
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
    echo 'es_MX.UTF-8 UTF-8' >> /etc/locale.gen
    locale-gen
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf
    ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
    echo 'blackarch-lab' > /etc/hostname
  "

  # Crear usuario blackarch
  run_in_nspawn "
    if ! id -u '$default_user' &>/dev/null; then
      useradd -m -G wheel -s /bin/bash '$default_user'
      echo '${default_user}:blackarch' | chpasswd
    fi
    # sudo sin password para blackarch (solo dentro del nspawn)
    echo '${default_user} ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/99-blackarch
    chmod 0440 /etc/sudoers.d/99-blackarch
    # También root sin password
    echo 'root ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/99-blackarch
  "

  touch "$build_marker"
  log "Sistema base listo."
}

# ─── Fase 2: Instalar BlackArch repos ─────────────────────────────────────────
install_blackarch_repos() {
  if run_in_nspawn "grep -q '\[blackarch\]' /etc/pacman.conf 2>/dev/null"; then
    log "Repos BlackArch ya configurados."
    return 0
  fi

  log "=== FASE 2: Instalando repos BlackArch ==="

  # Instalar el strap de BlackArch dentro del nspawn
  run_in_nspawn "
    curl -fsSL https://blackarch.org/strap.sh -o /root/strap.sh
    chmod +x /root/strap.sh
    /root/strap.sh
    pacman -Syu --noconfirm
  "

  log "Repos BlackArch instalados."
}

# ─── Fase 3: Instalar Hyprland y herramientas visuales ────────────────────────
install_hyprland() {
  if run_in_nspawn "command -v Hyprland &>/dev/null"; then
    log "Hyprland ya instalado en el nspawn."
    return 0
  fi

  log "=== FASE 3: Instalando Hyprland y stack visual ==="

  run_in_nspawn "
    pacman -Sy --needed --noconfirm \
      hyprland \
      hyprpaper \
      hypridle \
      hyprlock \
      hyprpicker \
      waybar \
      dunst \
      rofi-wayland \
      swww \
      grim \
      slurp \
      swappy \
      cliphist \
      playerctl \
      brightnessctl \
      network-manager-applet \
      polkit-gnome \
      dbus \
      pipewire \
      wireplumber \
      noto-fonts \
      noto-fonts-emoji \
      ttf-jetbrains-mono-nerd \
      imagemagick
  "

  log "Hyprland instalado."
}

# ─── Fase 4: Instalar yay (AUR helper) ────────────────────────────────────────
install_yay() {
  if run_in_nspawn "sudo -u '$default_user' command -v yay &>/dev/null"; then
    log "yay ya instalado."
    return 0
  fi

  log "=== FASE 4: Instalando yay ==="

  run_in_nspawn "
    tmpdir='/tmp/omen-yay'
    rm -rf \"\$tmpdir\"
    mkdir -p \"\$tmpdir\"
    chown $default_user:\$default_user \"\$tmpdir\"
  "

  run_as_user "
    tmpdir='/tmp/omen-yay'
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git \"\$tmpdir/yay-bin\"
    cd \"\$tmpdir/yay-bin\" && makepkg -si --noconfirm
    rm -rf \"\$tmpdir\"
  "

  log "yay instalado."
}

# ─── Fase 5: Instalar Ax-Shell ────────────────────────────────────────────────
install_ax_shell() {
  if [[ -f "$ax_shell_marker" ]]; then
    log "Ax-Shell ya instalado."
    return 0
  fi

  log "=== FASE 5: Instalando Ax-Shell ==="

  # Dependencias AUR para Ax-Shell
  run_as_user "
    yay -Sy --needed --noconfirm \
      fabric-cli-git \
      python-fabric-git \
      matugen-bin \
      awww-git \
      gpu-screen-recorder \
      hyprshot \
      python-ijson \
      python-setproctitle \
      python-watchdog \
      cava \
      ddcutil \
      nvtop \
      uwsm \
      gnome-bluetooth-3.0 \
      vte3 \
      webp-pixbuf-loader \
      python-pywayland \
      2>/dev/null || true
  "

  # Clonar Ax-Shell
  run_as_user "
    mkdir -p /home/${default_user}/.config
    if [[ -d '${ax_shell_dir}' ]]; then
      git -C '${ax_shell_dir}' pull --ff-only
    else
      git clone --depth=1 '${ax_shell_repo}' '${ax_shell_dir}'
    fi
  "

  # Instalar fuentes Zed Sans
  run_as_user "
    mkdir -p /home/${default_user}/.fonts/zed-sans
    curl -L -o /tmp/zed-sans.zip \
      https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip \
      && unzip -o /tmp/zed-sans.zip -d /home/${default_user}/.fonts/zed-sans \
      && rm -f /tmp/zed-sans.zip || true
    # Copiar fuentes incluidas en Ax-Shell
    if [[ -d '${ax_shell_dir}/assets/fonts' ]]; then
      cp -r '${ax_shell_dir}/assets/fonts/'* /home/${default_user}/.fonts/ || true
    fi
    fc-cache -fv &>/dev/null || true
  "

  # Configurar Ax-Shell
  run_as_user "
    if [[ -f '${ax_shell_dir}/config/config.py' ]]; then
      python '${ax_shell_dir}/config/config.py' || true
    fi
    mkdir -p /home/${default_user}/.local/state
    touch '${ax_shell_dir#/var/lib/machines/${machine_name}}' 2>/dev/null || true
  "

  # Marcar como instalado
  mkdir -p "$(dirname "$ax_shell_marker")"
  touch "$ax_shell_marker"
  chown -R "${default_user}:${default_user}" "${rootfs}/home/${default_user}/.local" 2>/dev/null || true

  log "Ax-Shell instalado."
}

# ─── Fase 6: Configurar Hyprland dentro del nspawn ───────────────────────────
configure_hyprland_in_nspawn() {
  local hypr_conf="${rootfs}/home/${default_user}/.config/hypr/hyprland.conf"

  if [[ -f "$hypr_conf" ]]; then
    log "Hyprland ya configurado en nspawn."
    return 0
  fi

  log "=== FASE 6: Configurando Hyprland en nspawn ==="

  mkdir -p "${rootfs}/home/${default_user}/.config/hypr"

  cat > "$hypr_conf" << 'HYPRCONF'
# BlackArch Hyprland config (modo nspawn)
# Solo se usa la instancia del HOST – este archivo está aquí para referencia

monitor = , preferred, auto, 1

exec-once = /home/blackarch/.config/Ax-Shell/main.py &

general {
  border_size = 2
  col.active_border = rgba(00ff41ff) rgba(ff0040ff) 45deg
  col.inactive_border = rgba(1a1a2eff)
  gaps_in = 5
  gaps_out = 10
}

decoration {
  rounding = 10
  blur {
    enabled = true
    size = 10
    passes = 3
  }
  shadow {
    enabled = true
    range = 25
    color = rgba(00ff4133)
  }
}

animations {
  enabled = true
}
HYPRCONF

  chown -R "${default_user}:${default_user}" "${rootfs}/home/${default_user}/.config/hypr"
  log "Hyprland configurado en nspawn."
}

# ─── Main ─────────────────────────────────────────────────────────────────────
require_root
mkdir -p "$(dirname "$log_file")"
touch "$log_file"

log "============================================"
log " OMEN BlackArch Build – $(date)"
log "============================================"

build_base
install_blackarch_repos
install_hyprland
install_yay
install_ax_shell
configure_hyprland_in_nspawn

log ""
log "============================================"
log " ✓ BUILD COMPLETO"
log " Sistema en: $rootfs"
log " Activa con: Super+XF86Launch2"
log "============================================"
