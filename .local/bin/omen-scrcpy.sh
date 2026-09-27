#!/bin/bash

# Script para conectar scrcpy de manera inteligente (USB > WiFi Local > Tailscale)

CACHE_DIR="$HOME/.cache/caelestia"
mkdir -p "$CACHE_DIR"

# IPs de tus teléfonos en Tailscale
IP_REALME="100.69.205.1"
IP_AXOLOTL="100.86.63.76"

# 1. Si hay dispositivos conectados por USB, obtenemos su IP local y la guardamos en caché
USB_DEVICES=$(adb devices -l | grep "usb:" | awk '{print $1}')

if [[ -n "$USB_DEVICES" ]]; then
    # Habilitamos el modo inalámbrico
    adb tcpip 5555 >/dev/null 2>&1
    sleep 1
    
    for dev in $USB_DEVICES; do
        # Obtener el modelo para nombrar la caché
        model=$(adb -s "$dev" shell getprop ro.product.model | tr -d '\r' | tr ' ' '_')
        # Obtener la IP de la interfaz wlan0
        ip=$(adb -s "$dev" shell "ip -o -4 addr show wlan0" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
        if [[ -n "$ip" ]]; then
            echo "$ip" > "$CACHE_DIR/scrcpy-${model}.ip"
        fi
    done
fi

# 2. Intentamos conectar usando las IPs en caché y las de Tailscale
# Buscamos todas las IPs guardadas en caché
cached_ips=""
if [ -d "$CACHE_DIR" ]; then
    for f in "$CACHE_DIR"/scrcpy-*.ip; do
        if [ -f "$f" ]; then
            cached_ips="$cached_ips $(cat "$f")"
        fi
    done
fi

# Lista de IPs a intentar conectar en paralelo
IP_LIST="$IP_REALME $IP_AXOLOTL $cached_ips"

# Eliminar duplicados y vacíos
IP_LIST=$(echo "$IP_LIST" | tr ' ' '\n' | sort -u | grep -v '^$')

# Intentar conectar a todas las IPs en paralelo (timeout 2 segundos)
for ip in $IP_LIST; do
    timeout 2 adb connect "$ip:5555" >/dev/null 2>&1 &
done

# Esperamos a que terminen los intentos de conexión
wait

# Pausa para estabilizar conexiones
sleep 1

# 3. Determinar cómo lanzar scrcpy
# Prioridad 1: Dispositivo USB
usb_dev=$(adb devices -l | grep "usb:" | awk '{print $1}' | head -n 1)

if [[ -n "$usb_dev" ]]; then
    scrcpy -s "$usb_dev"
else
    # Prioridad 2: Conexión inalámbrica (WiFi o Tailscale)
    # Buscamos algún dispositivo inalámbrico conectado
    wifi_dev=$(adb devices | grep -E "192\.168\.|100\." | grep "device$" | awk '{print $1}' | head -n 1)
    
    if [[ -n "$wifi_dev" ]]; then
        # Opciones de baja latencia para red inalámbrica
        scrcpy -s "$wifi_dev" -m 1024 -b 4M --max-fps 60
    else
        echo "No se encontró ningún dispositivo conectado." >&2
        exit 1
    fi
fi
