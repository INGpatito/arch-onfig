#!/bin/bash
STATE_FILE="/tmp/omen_low_resource_state"

if [ -f "$STATE_FILE" ]; then
    # -- RESTORE NORMAL MODE --
    rm -f "$STATE_FILE"
    
    # Kill the lightweight environment
    killall waybar
    killall swaybg
    
    # Restore wallpaper through caelestia/swww (handled by Caelestia start usually, but let's be safe)
    
    # Start Caelestia shell
    caelestia shell -d &
    
    notify-send -u low "Normal Mode" "Modo normal restaurado. Caelestia iniciado."
else
    # -- GO INTO LOW RESOURCE MODE --
    touch "$STATE_FILE"
    
    notify-send -u critical "Low Resource Mode" "Apagando Caelestia y procesos pesados..."
    sleep 1
    
    # Kill caelestia and its widgets
    qs -c caelestia kill || killall quickshell
    killall eww
    killall ags
    
    # Kill unnecessary heavy background processes (chat, games, launchers)
    killall -9 vesktop discord equicord legcord 2>/dev/null
    killall -9 steam spotify equibop heroic 2>/dev/null
    killall -9 baloo_file baloo_file_extractor 2>/dev/null # KDE indexers if running
    killall -9 obsidian 2>/dev/null
    
    # Also stop system-level heavy services (AI, Docker, etc.) if requested (will ask for password)
    pkexec sh -c "systemctl stop ollama docker tailscaled 2>/dev/null; killall -9 uvicorn dockerd ollama 2>/dev/null" &
    
    # Start a minimal graphical environment (Waybar and black background)
    systemd-run --user swaybg -c "#000000" >/dev/null 2>&1
    systemd-run --user waybar >/dev/null 2>&1
    
    notify-send -u critical "Low Resource Mode" "Entorno minimalista (Waybar) cargado."
fi
