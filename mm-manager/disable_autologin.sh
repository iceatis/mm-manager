#!/bin/bash
set -e

SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
SERVICE_FILE="$SERVICE_DIR/autologin.conf"

if [ -f "$SERVICE_FILE" ]; then
  sudo rm -f "$SERVICE_FILE"
  sudo systemctl daemon-reload
  echo "Autologin kikapcsolva"
else
  echo "Autologin nem volt aktív"
fi
