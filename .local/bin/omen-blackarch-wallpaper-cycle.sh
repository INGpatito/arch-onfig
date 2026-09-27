#!/usr/bin/env bash
# omen-blackarch-wallpaper-cycle.sh
# Rota fondos de pantalla oficiales de BlackArch en Noctalia

WP_DIR="${HOME}/.local/share/omen-wallpapers"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/omen-blackarch-current-wp"

WALLPAPERS=(
  "${WP_DIR}/blackarch-glow.png"
  "${WP_DIR}/blackarch-cyberpunk.png"
  "${WP_DIR}/blackarch-ninjarch-code.png"
  "${WP_DIR}/blackarch-black.png"
)

CURRENT=""
[[ -f "$STATE_FILE" ]] && CURRENT=$(cat "$STATE_FILE")

NEXT_IDX=0
for i in "${!WALLPAPERS[@]}"; do
  if [[ "${WALLPAPERS[$i]}" == "$CURRENT" ]]; then
    NEXT_IDX=$(( (i + 1) % ${#WALLPAPERS[@]} ))
    break
  fi
done

NEXT_WP="${WALLPAPERS[$NEXT_IDX]}"

if [[ -f "$NEXT_WP" ]]; then
  noctalia msg wallpaper-set "$NEXT_WP" >/dev/null 2>&1 || true
  echo "$NEXT_WP" > "$STATE_FILE"
  WP_NAME=$(basename "$NEXT_WP" .png)
  notify-send -u low "BlackArch Wallpaper" "Fondo cambiado a: ${WP_NAME}" 2>/dev/null || true
fi
