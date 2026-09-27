#!/usr/bin/env bash

HOTSPOT_SSID="Omen-Hotspot"
HOTSPOT_PASS="12345678"

if nmcli connection show --active | grep -q "$HOTSPOT_SSID"; then
    # Está activo, lo apagamos
    nmcli connection down "$HOTSPOT_SSID"
    notify-send -t 3000 "Hotspot" "Punto de acceso Desactivado"
    exit 0
fi
# Buscar una interfaz WiFi libre (para no desconectar el internet actual)
UNUSED_WIFI=""
for dev in $(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi" {print $1}'); do
    if ! nmcli -t -f DEVICE,STATE device | grep -q "^$dev:connected$"; then
        UNUSED_WIFI=$dev
        break
    fi
done

# Si todas están conectadas, usamos la primera por defecto
if [ -z "$UNUSED_WIFI" ]; then
    UNUSED_WIFI=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi" {print $1}' | head -n1)
fi

# No está activo, lo encendemos
if nmcli connection show | grep -q "$HOTSPOT_SSID"; then
    nmcli connection modify "$HOTSPOT_SSID" connection.interface-name "$UNUSED_WIFI"
    nmcli connection up "$HOTSPOT_SSID" ifname "$UNUSED_WIFI"
    notify-send -t 3000 "Hotspot" "Punto de acceso Activado"
else
    # Si no existe, lo creamos
    nmcli device wifi hotspot ifname "$UNUSED_WIFI" ssid "$HOTSPOT_SSID" password "$HOTSPOT_PASS" con-name "$HOTSPOT_SSID"
    notify-send -t 4000 "Hotspot" "Punto de acceso Creado y Activado\nRed: $HOTSPOT_SSID\nPass: $HOTSPOT_PASS"
fi
