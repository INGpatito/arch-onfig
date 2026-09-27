#!/usr/bin/env bash
# omen-blackarch-setup-noctalia.sh
# Instala y configura Noctalia Shell dentro del contenedor BlackArch
set -euo pipefail

machine_name="blackarch-omen-lab"
rootfs="/var/lib/machines/${machine_name}"
default_user="blackarch"
target_config_dir="${rootfs}/home/${default_user}/.config/noctalia"
state_marker="${HOME}/.local/state/omen-blackarch-noctalia-ready"

echo "=========================================================="
echo "    Instalando Noctalia Shell en BlackArch Container      "
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
  echo "[-] Este instalador requiere permisos de administrador."
  echo "[+] Solicitando sudo..."
  exec sudo "$0" "$@"
fi

if [[ ! -d "${rootfs}/etc" ]]; then
  echo "[-] Error: El contenedor BlackArch no existe en ${rootfs}." >&2
  exit 1
fi

echo "[1/4] Actualizando repositorios e instalando noctalia en el contenedor..."
systemd-nspawn \
  --directory="$rootfs" \
  --machine="$machine_name" \
  --hostname=blackarch-lab \
  --capability=all \
  --bind-ro=/etc/resolv.conf:/etc/resolv.conf \
  pacman -Sy --needed --noconfirm noctalia

echo "[2/4] Creando configuración de Noctalia para usuario ${default_user}..."
mkdir -p "${target_config_dir}"

cat > "${target_config_dir}/config.toml" << 'NOCT_CONF'
[accessibility]
ui_scale = 1.10

[bar.default]
center = [ "workspaces", "spacer_1", "active_window" ]
concave_edge_corners = true
end = [ "media", "spacer_1", "tray", "notifications", "network", "volume", "session" ]
margin_edge = 0
margin_ends = 0
radius_bottom_left = 12
radius_bottom_right = 12
radius_top_left = 0
radius_top_right = 0
scale = 1.05
start = [ "launcher", "clock", "spacer_1", "group:g1" ]
thickness = 34

    [[bar.default.capsule_group]]
    border = ""
    fill = "on_secondary"
    id = "g1"
    members = [ "temp", "sysmon_2", "sysmon_3" ]
    opacity = 1.0
    padding = 6.0

[shell]
launch_apps_as_systemd_services = false
polkit_agent = false
settings_show_advanced = true

    [shell.greeter_sync]
    auto_sync = false

    [shell.panel]
    open_near_click_control_center = true
    session_placement = "floating"
    session_position = "center"

    [shell.screenshot]
    copy_to_clipboard = true
    pipe_to_command = false
    save_to_file = true

    [[shell.session.actions]]
    action = "lock"
    countdown_seconds = 0.0
    enabled = true
    shortcut = "1"
    variant = "default"

    [[shell.session.actions]]
    action = "logout"
    countdown_seconds = 0.0
    enabled = true
    shortcut = "2"
    variant = "default"

    [[shell.session.actions]]
    action = "lock_and_suspend"
    countdown_seconds = 3.0
    enabled = true
    shortcut = "3"
    variant = "default"

    [[shell.session.actions]]
    action = "reboot"
    countdown_seconds = 3.0
    enabled = true
    shortcut = "4"
    variant = "default"

    [[shell.session.actions]]
    action = "shutdown"
    countdown_seconds = 3.0
    enabled = true
    shortcut = "5"
    variant = "destructive"

[system.monitor]
gpu_poll_seconds = 2

[theme]
mode = "dark"
source = "wallpaper"
wallpaper_scheme = "m3-tonal-spot"

    [theme.templates]
    builtin_ids = [ "btop", "gtk3", "gtk4", "kcolorscheme", "kitty", "qt", "alacritty" ]

[widget.clock]
color = "secondary"
format = "{:%H:%M %A %m/%d/%y}"

[widget.launcher]
color = "primary"

[widget.media]
hide_when_no_media = true
title_scroll = "on_hover"

[widget.network]
color = "secondary"

[widget.notifications]
color = "secondary"

[widget.session]
color = "error"

[widget.spacer_1]
type = "spacer"

[widget.temp]
show_value = false

[widget.sysmon_2]
glyph = "gpu-usage"
show_value = false
stat = "gpu_temp"
type = "sysmon"

[widget.sysmon_3]
glyph = "cpu-2"
stat = "ram_used"
type = "sysmon"

[widget.tray]
capsule = true
capsule_fill = "on_secondary"

[widget.volume]
color = "secondary"

[widget.workspaces]
active_pill_size = 2.5
capsule = true
capsule_fill = "on_primary"
inactive_pill_size = 1.0
pill_scale = 0.80
show_labels = false
NOCT_CONF

echo "[3/4] Ajustando permisos de usuario..."
# Obtener UID/GID del usuario blackarch dentro del contenedor
BA_UID=$(systemd-nspawn --directory="$rootfs" id -u "$default_user" 2>/dev/null || echo "1000")
BA_GID=$(systemd-nspawn --directory="$rootfs" id -g "$default_user" 2>/dev/null || echo "1000")
chown -R "${BA_UID}:${BA_GID}" "${target_config_dir}"
chmod 755 /var/lib/machines

echo "[4/4] Creando marcador de estado..."
mkdir -p "${HOME}/.local/state"
touch "${state_marker}"

echo "=========================================================="
echo "    ✓ Noctalia instalado y configurado en BlackArch       "
echo "=========================================================="
