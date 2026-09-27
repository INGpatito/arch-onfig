#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta este script con sudo: sudo bash $0"
  exit 1
fi

echo "==> 1. Instalando el script en /usr/local/bin/victus-fan-profile.py..."
install -m 755 /home/pato/.local/bin/victus-fan-profile.py /usr/local/bin/victus-fan-profile.py

echo "==> 2. Creando el servicio systemd en /etc/systemd/system/victus-fan-profile.service..."
cat <<'EOF' > /etc/systemd/system/victus-fan-profile.service
[Unit]
Description=HP Victus Fan Sync with Power Profiles (Caelestia)
After=power-profiles-daemon.service
Wants=power-profiles-daemon.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/victus-fan-profile.py
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "==> 3. Recargando systemd y habilitando el servicio..."
systemctl daemon-reload
systemctl enable --now victus-fan-profile.service

echo "==> 4. Verificando estado del servicio:"
systemctl status victus-fan-profile.service --no-pager
