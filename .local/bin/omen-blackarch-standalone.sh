#!/usr/bin/env bash
set -euo pipefail

machine_name="blackarch-omen-lab"
rootfs="/var/lib/machines/${machine_name}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Falta comando requerido: $1" >&2
    exit 1
  }
}

require_cmd sudo
require_cmd systemd-nspawn
require_cmd machinectl
require_cmd pacman

if [[ ! -d "${rootfs}/etc" ]]; then
  echo "Inicializando BlackArch independiente (primera ejecución)..."
  sudo pacman -Sy --needed --noconfirm arch-install-scripts curl
  sudo mkdir -p "$rootfs"
  sudo pacstrap -K "$rootfs" \
    base base-devel sudo vim nano git curl \
    hyprland wayland xdg-desktop-portal-hyprland foot wl-clipboard

  sudo arch-chroot "$rootfs" /bin/bash -lc '
set -euo pipefail
curl -fsSL https://blackarch.org/strap.sh -o /root/strap.sh
chmod +x /root/strap.sh
/root/strap.sh
pacman -Syu --noconfirm
'
fi

exec sudo systemd-nspawn \
  --directory="$rootfs" \
  --machine="$machine_name" \
  --hostname=blackarch-lab \
  --bind=/:/host \
  /bin/bash -lc '
echo
echo "=== BlackArch independiente (nspawn) ==="
echo "Arch host montado en: /host"
echo "En Arch host no aparecen herramientas de BlackArch."
echo "Hyprland/Wayland instalados en BlackArch para personalización posterior."
echo "Ejecuta: dbus-run-session Hyprland"
echo
exec /bin/bash -l
'
