#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta este script con sudo: sudo bash $0"
  exit 1
fi

echo "==> Deshabilitando y deteniendo el servicio..."
systemctl disable --now victus-fan-profile.service 2>/dev/null || true

echo "==> Eliminando archivos del sistema..."
rm -f /etc/systemd/system/victus-fan-profile.service
rm -f /usr/local/bin/victus-fan-profile.py
systemctl daemon-reload

# Restaurar ventiladores a modo auto por seguridad
for p in /sys/devices/platform/hp-wmi/hwmon/hwmon*/pwm1_enable; do
  [ -f "$p" ] && echo 2 > "$p" || true
done

echo "==> Desinstalación completada. Ventiladores restaurados a modo AUTO."
