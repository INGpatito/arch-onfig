#!/usr/bin/env bash
# omen-blackarch-toggle.sh — v3.2 (Noctalia Shell + Full Container Isolation)
# Super+XF86Launch2 → Activa/Desactiva modo BlackArch con Noctalia Shell y aislamiento total

# ─── Config ────────────────────────────────────────────────────────────────────
PASSWORD="1838271939371"
MACHINE="blackarch-omen-lab"
ROOTFS="/var/lib/machines/${MACHINE}"
BA_USER="blackarch"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="${STATE_DIR}/omen-blackarch-mode"
NOCT_PID_FILE="${STATE_DIR}/omen-noctalia-shell.pid"
BUILD_MARKER="${STATE_DIR}/omen-blackarch-built"
WP_BA="${HOME}/.local/share/omen-wallpapers/blackarch-glow.png"

# Env Wayland del host
HOST_RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WAYLAND_DISP="${WAYLAND_DISPLAY:-wayland-1}"
HYPR_SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
DBUS_ADDR="${DBUS_SESSION_BUS_ADDRESS:-}"

# ─── Helpers ───────────────────────────────────────────────────────────────────
notif() { notify-send -u normal  "BlackArch Mode" "$1" 2>/dev/null; return 0; }
notif_err() { notify-send -u critical "BlackArch Mode" "$1" 2>/dev/null; return 0; }

hypr_kw() { hyprctl keyword "$1" "$2" >/dev/null 2>&1; return 0; }
hypr_lua_config() { hyprctl eval "$1" >/dev/null 2>&1; return 0; }
hypr_msg() { hyprctl notify 1 3000 "rgb($1)" "  $2" >/dev/null 2>&1; return 0; }

# ─── Animación activación ──────────────────────────────────────────────────────
anim_on() {
  clear
  printf '\033[1;31m'
  cat << 'BANNER'

  ██████╗ ██╗      █████╗  ██████╗██╗  ██╗ █████╗ ██████╗  ██████╗██╗  ██╗
  ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║
  ██████╔╝██║     ███████║██║     █████╔╝ ███████║██████╔╝██║     ███████║
  ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██║██╔══██╗██║     ██╔══██║
  ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║██║  ██║╚██████╗██║  ██║
  ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

BANNER
  printf '\033[1;32m  [ OMEN BLACKARCH SYSTEM v3.2 — AISLAMIENTO TOTAL ]\n\n\033[0;32m'

  local steps=(
    "Iniciando máquina aislada BlackArch"
    "Deteniendo Caelestia Shell"
    "Iniciando Noctalia Shell"
    "Cargando atajos de teclado BlackArch"
    "Aplicando tema y fondo oficial 1080p"
  )
  for s in "${steps[@]}"; do
    printf '  \033[1;32m[+]\033[0m %s' "$s"
    sleep 0.12; printf '.'; sleep 0.12; printf '.'; sleep 0.12; printf '.'
    printf ' \033[1;32m✓\033[0m\n'
  done
  printf '\n  \033[1;31m▶ SISTEMA BLACKARCH ACTIVO (AISLADO) ◀\033[0m\n\n'
  sleep 0.4
}

anim_off() {
  clear
  printf '\033[1;34m'
  cat << 'BANNER'

   █████╗ ██████╗  ██████╗██╗  ██╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║
  ███████║██████╔╝██║     ███████║
  ██╔══██║██╔══██╗██║     ██╔══██║
  ██║  ██║██║  ██║╚██████╗██║  ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

BANNER
  printf '\033[0;34m  [ Regresando a Arch Linux ]\n\n'
  local steps=(
    "Cerrando aplicaciones de BlackArch"
    "Apagando contenedor aislado"
    "Cerrando Noctalia Shell"
    "Restaurando Caelestia"
    "Restaurando escritorio y atajos de Arch"
  )
  for s in "${steps[@]}"; do
    printf '  \033[1;34m[-]\033[0m %s'; sleep 0.1; printf '..'; sleep 0.1
    printf ' \033[1;34m✓\033[0m\n'
  done
  printf '\n  \033[1;34m▶ ARCH LINUX RESTAURADO ◀\033[0m\n\n'
  sleep 0.4
}

# ─── Detener Caelestia ─────────────────────────────────────────────────────────
stop_caelestia() {
  caelestia shell -k >/dev/null 2>&1 || true
  pkill -f "qs -c caelestia" 2>/dev/null || true
  pkill -9 -f "qs -c caelestia" 2>/dev/null || true
  pkill -f "caelestia resizer" 2>/dev/null || true
  pkill -f "caelestia shell" 2>/dev/null || true
  sleep 0.5
  return 0
}

# ─── Iniciar Caelestia ─────────────────────────────────────────────────────────
start_caelestia() {
  pkill -9 noctalia 2>/dev/null || true
  sleep 0.3
  nohup caelestia shell -d >/dev/null 2>&1 &
  return 0
}

# ─── Lanzar Noctalia Shell ────────────────────────────────────────────────────
launch_noctalia_shell() {
  mkdir -p "${STATE_DIR}"

  pkill -9 noctalia 2>/dev/null || true

  # Iniciar Noctalia daemon
  noctalia -d >"${STATE_DIR}/noctalia.log" 2>&1 &
  echo $! > "${NOCT_PID_FILE}"

  # Esperar a que el IPC de Noctalia responda
  for _ in {1..25}; do
    if noctalia msg status >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
  return 0
}

# ─── Matar Noctalia Shell ──────────────────────────────────────────────────────
kill_noctalia_shell() {
  if [[ -f "${NOCT_PID_FILE}" ]]; then
    local pid
    pid=$(cat "${NOCT_PID_FILE}" 2>/dev/null || echo "")
    [[ -n "$pid" ]] && kill -9 "$pid" 2>/dev/null
    rm -f "${NOCT_PID_FILE}"
  fi
  pkill -9 noctalia 2>/dev/null || true
  return 0
}

# ─── Control Máquina Aislada BlackArch ──────────────────────────────────────────
start_blackarch_container() {
  # Si ya está corriendo, no hacer nada
  if sudo machinectl list 2>/dev/null | grep -q "${MACHINE}"; then
    return 0
  fi

  # Iniciar en modo booteado en segundo plano con aislamiento estricto
  local wayland_args=()
  if [[ -S "${HOST_RUNTIME}/${WAYLAND_DISP}" ]]; then
    wayland_args=("--bind=${HOST_RUNTIME}/${WAYLAND_DISP}:/tmp/${WAYLAND_DISP}")
  fi

  sudo systemd-nspawn -b \
    -D "${ROOTFS}" \
    -M "${MACHINE}" \
    "${wayland_args[@]}" \
    --capability=all >"${STATE_DIR}/omen-nspawn.log" 2>&1 &

  for _ in {1..30}; do
    if sudo machinectl list 2>/dev/null | grep -q "${MACHINE}"; then
      break
    fi
    sleep 0.1
  done
  return 0
}

stop_blackarch_container() {
  # Apagar máquina BlackArch (esto cierra todas las apps de BlackArch inmediatamente)
  sudo machinectl poweroff "${MACHINE}" >/dev/null 2>&1 || true
  return 0
}

# ─── Tema visual BlackArch ────────────────────────────────────────────────────
theme_on() {
  hypr_kw "general:col.active_border"   "rgba(00ff41ff) rgba(ff0040ff) 45deg"
  hypr_kw "general:col.inactive_border" "rgba(0d0d0dff)"
  hypr_kw "decoration:shadow:color"     "rgba(00ff4166)"
  hypr_kw "decoration:blur:size"        "14"
  hypr_kw "general:gaps_out"            "18"

  # Wallpaper oficial 1080p
  if [[ -f "$WP_BA" ]]; then
    noctalia msg wallpaper-set "$WP_BA" >/dev/null 2>&1 || true
    echo "$WP_BA" > "${STATE_DIR}/omen-blackarch-current-wp"
  fi

  # Recargar Hyprland para activar blackarch-keybinds.lua
  hyprctl reload >/dev/null 2>&1 || true

  # Cambiar al espacio de trabajo dedicado de BlackArch (workspace 9)
  hyprctl dispatch workspace 9 >/dev/null 2>&1 || true

  hypr_msg "00ff41" "BlackArch — Sistema Aislado Activo"
}

theme_off() {
  hypr_kw "general:col.active_border"   "rgba(cba6f7ff) rgba(89b4faff) 45deg"
  hypr_kw "general:col.inactive_border" "rgba(45475aff)"
  hypr_kw "decoration:shadow:color"     "rgba(1e1e2ecc)"
  hypr_kw "decoration:blur:size"        "8"
  hypr_kw "general:gaps_out"            "10"

  # Recargar Hyprland para restaurar hyprland.keybinds.lua
  hyprctl reload >/dev/null 2>&1 || true

  # Restaurar espacio de trabajo previo de Arch
  local prev_ws="1"
  if [[ -f "${STATE_DIR}/omen-arch-workspace" ]]; then
    prev_ws=$(cat "${STATE_DIR}/omen-arch-workspace" 2>/dev/null || echo "1")
    rm -f "${STATE_DIR}/omen-arch-workspace"
  fi
  hyprctl dispatch workspace "$prev_ws" >/dev/null 2>&1 || true

  hypr_msg "89b4fa" "Arch Linux restaurado"
}

# ─── Activar ───────────────────────────────────────────────────────────────────
activate() {
  mkdir -p "${STATE_DIR}"

  # Pedir contraseña
  printf '\033[1;33m  Contraseña OMEN BlackArch: \033[0m'
  stty -echo 2>/dev/null
  IFS= read -r typed_pw
  stty echo 2>/dev/null
  printf '\n'

  if [[ "$typed_pw" != "$PASSWORD" ]]; then
    printf '\033[1;31m  ✗ Contraseña incorrecta.\033[0m\n'
    notif_err "Contraseña incorrecta."
    sleep 1
    exit 1
  fi

  anim_on

  # Guardar espacio de trabajo actual de Arch
  local cur_ws
  cur_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null || echo "1")
  echo "${cur_ws:-1}" > "${STATE_DIR}/omen-arch-workspace"

  # Verificar build de BlackArch
  if [[ ! -f "${BUILD_MARKER}" ]] && [[ ! -d "${ROOTFS}/etc" ]]; then
    notif_err "Sistema BlackArch no construido. Ejecuta: sudo ~/.local/bin/omen-blackarch-build.sh"
    printf '\033[1;31m  ✗ Sistema no construido. Revisa el build.\033[0m\n'
    sleep 3
    exit 1
  fi

  # Guardar estado BlackArch
  echo "enabled" > "${STATE_FILE}"

  # Perfil rendimiento
  powerprofilesctl set performance 2>/dev/null || true

  # Detener Caelestia
  stop_caelestia

  # Iniciar contenedor aislado BlackArch
  start_blackarch_container

  # Lanzar Noctalia Shell
  launch_noctalia_shell

  # Tema hacker, fondo y atajos
  theme_on

  notif "Modo BlackArch (Aislado) Activo"
}

# ─── Desactivar ────────────────────────────────────────────────────────────────
deactivate() {
  anim_off

  # Detener Noctalia
  kill_noctalia_shell
  sleep 0.2

  # Apagar contenedor BlackArch (cierra todas las ventanas de BlackArch)
  stop_blackarch_container

  # Eliminar estado ANTES de recargar Hyprland
  rm -f "${STATE_FILE}"

  # Perfil equilibrado
  powerprofilesctl set balanced 2>/dev/null || true

  # Restaurar tema, atajos y espacio de trabajo de Caelestia
  theme_off

  # Iniciar Caelestia
  start_caelestia

  notif "Arch Linux restaurado"
}

# ─── Main ──────────────────────────────────────────────────────────────────────
if [[ -f "${STATE_FILE}" ]]; then
  deactivate
else
  activate
fi
