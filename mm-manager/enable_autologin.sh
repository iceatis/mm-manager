#!/bin/bash
set -e

USER_NAME="$(logname)"

SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
SERVICE_FILE="$SERVICE_DIR/autologin.conf"

sudo mkdir -p "$SERVICE_DIR"

sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

sudo systemctl daemon-reload

echo "Autologin engedélyezve felhasználónak: $USER_NAME"
