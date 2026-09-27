#!/usr/bin/env bash
# omen-blackarch-env.sh
# XF86Launch2 (sin Super) → Abre terminal interactiva dentro del entorno BlackArch
set -euo pipefail

machine_name="blackarch-omen-lab"
rootfs="/var/lib/machines/${machine_name}"
default_user="blackarch"
state_file="${XDG_STATE_HOME:-$HOME/.local/state}/omen-blackarch-mode"
build_marker="${XDG_STATE_HOME:-$HOME/.local/state}/omen-blackarch-built"
host_runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
wayland_disp="${WAYLAND_DISPLAY:-wayland-1}"
mode="${1:-user}"

# ─── Banner ────────────────────────────────────────────────────────────────────
show_banner() {
  printf '\033[1;31m'
  cat << 'EOF'

  ██████╗ ██╗      █████╗  ██████╗██╗  ██╗ █████╗ ██████╗  ██████╗██╗  ██╗
  ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║
  ██████╔╝██║     ███████║██║     █████╔╝ ███████║██████╔╝██║     ███████║
  ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██╗██║     ██╔══██║
  ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╗██║  ██║
  ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

EOF
  printf '\033[0;32m'
  printf "  Sistema: Independiente (Aislado)\n"
  printf "  Usuario: %s  |  Arch Host montado: NO\n" "$default_user"
  printf "  Herramientas BlackArch disponibles.\n\n"
  printf '\033[0m'
}

# Verificar que el sistema exista
if [[ ! -f "${build_marker}" ]] && [[ ! -d "${rootfs}/etc" ]]; then
  printf '\033[1;31m[!] Sistema BlackArch no construido.\033[0m\n'
  printf 'Activa con Super+XF86Launch2 para construirlo primero.\n'
  sleep 3
  exit 1
fi

# Mostrar banner
show_banner

# Determinar usuario de entrada
exec_user="$default_user"
if [[ "$mode" == "--root" || "$mode" == "root" ]]; then
  exec_user="root"
fi

wayland_bind=()
if [[ -S "${host_runtime}/${wayland_disp}" ]]; then
  wayland_bind=("--bind=${host_runtime}/${wayland_disp}:/tmp/${wayland_disp}")
fi

# Entrar al sistema como shell interactiva
if sudo machinectl list 2>/dev/null | grep -q "${machine_name}"; then
  exec sudo machinectl shell \
    -E WAYLAND_DISPLAY="${wayland_disp}" \
    -E XDG_RUNTIME_DIR="/tmp" \
    -E TERM="${TERM:-xterm-256color}" \
    -E HOME="/home/${exec_user}" \
    -E USER="${exec_user}" \
    "${exec_user}@${machine_name}" /bin/bash -l
else
  exec sudo systemd-nspawn \
    --directory="$rootfs" \
    --machine="${machine_name}" \
    --hostname=blackarch-lab \
    --capability=all \
    "${wayland_bind[@]}" \
    --setenv=WAYLAND_DISPLAY="${wayland_disp}" \
    --setenv=XDG_RUNTIME_DIR="/tmp" \
    --setenv=HOME="/home/${exec_user}" \
    --setenv=USER="${exec_user}" \
    --setenv=TERM="${TERM:-xterm-256color}" \
    /bin/bash -lc "
      cd /home/${exec_user} 2>/dev/null || cd /root
      exec /bin/bash -l
    "
fi
