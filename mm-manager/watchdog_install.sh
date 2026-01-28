#!/bin/bash
set -e

# =========================================================
# MagicMirror Watchdog Installer (FINAL)
# =========================================================

SERVICE_NAME="mm-watchdog.service"

# ---------------------------------------------------------
# USER / HOME RESOLUTION (CRITICAL FIX)
# ---------------------------------------------------------
if [ -n "$SUDO_USER" ]; then
  RUN_USER="$SUDO_USER"
else
  RUN_USER="$(whoami)"
fi

USER_HOME="$(eval echo "~$RUN_USER")"
BASE_DIR="$USER_HOME/mm-manager"
WATCHDOG_SCRIPT="$BASE_DIR/mm-watchdog.sh"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# ---------------------------------------------------------
# WHIPTAIL
# ---------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

# ---------------------------------------------------------
# FILE CHECK
# ---------------------------------------------------------
if [ ! -f "$WATCHDOG_SCRIPT" ]; then
  whiptail --msgbox "❌ Hiányzó fájl:\n$WATCHDOG_SCRIPT" 10 60
  exit 1
fi

# ---------------------------------------------------------
# INSTALL WATCHDOG SCRIPT
# ---------------------------------------------------------
sudo cp "$WATCHDOG_SCRIPT" /usr/local/bin/mm-watchdog.sh
sudo chmod +x /usr/local/bin/mm-watchdog.sh

# ---------------------------------------------------------
# GENERATE SYSTEMD SERVICE (NO STATIC FILE!)
# ---------------------------------------------------------
sudo tee "$SERVICE_PATH" >/dev/null <<EOF
[Unit]
Description=MagicMirror Watchdog
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/mm-watchdog.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------
# SYSTEMD ENABLE & START
# ---------------------------------------------------------
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
whiptail --msgbox \
"✅ Watchdog sikeresen telepítve és engedélyezve.

Felhasználó: $RUN_USER
Script: /usr/local/bin/mm-watchdog.sh
Service: $SERVICE_NAME

A systemd mostantól felügyeli a watchdogot." \
14 70
