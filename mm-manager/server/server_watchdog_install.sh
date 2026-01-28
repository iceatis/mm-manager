#!/bin/bash
set -e

# =========================================================
# SERVER WATCHDOG INSTALLER – MagicMirror
# Server-specific, standalone
# v1.4.4
# =========================================================

SERVICE_NAME="server_watchdog.service"

# ---------------------------------------------------------
# Resolve real user (informational only)
# ---------------------------------------------------------
if [ -n "${SUDO_USER:-}" ]; then
  RUN_USER="$SUDO_USER"
else
  RUN_USER="$(whoami)"
fi

USER_HOME="$(eval echo "~$RUN_USER")"
BASE_DIR="$USER_HOME/mm-manager"

SRC_SCRIPT="$BASE_DIR/server/server_watchdog.sh"
DST_SCRIPT="/usr/local/bin/server_watchdog.sh"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"

# ---------------------------------------------------------
# WHIPTAIL (optional UI)
# ---------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

# ---------------------------------------------------------
# Preconditions
# ---------------------------------------------------------
if [ ! -f "$SRC_SCRIPT" ]; then
  whiptail --msgbox \
"❌ Hiányzó server watchdog script:

$SRC_SCRIPT

A telepítés nem folytatható." \
10 70
  exit 1
fi

# ---------------------------------------------------------
# Install / UPDATE watchdog script (ALWAYS OVERWRITE)
# ---------------------------------------------------------
echo "→ server_watchdog.sh frissítése"
sudo cp "$SRC_SCRIPT" "$DST_SCRIPT"
sudo chmod +x "$DST_SCRIPT"

# ---------------------------------------------------------
# Generate / UPDATE systemd service (SERVER ONLY)
# ---------------------------------------------------------
sudo tee "$SERVICE_PATH" >/dev/null <<EOF
[Unit]
Description=MagicMirror Server Watchdog
After=network.target graphical.target

[Service]
Type=simple
User=root
ExecStart=$DST_SCRIPT
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# ---------------------------------------------------------
# Enable & RESTART service (FORCE RELOAD)
# ---------------------------------------------------------
echo "→ systemd daemon-reload"
sudo systemctl daemon-reload

echo "→ server_watchdog.service engedélyezése"
sudo systemctl enable "$SERVICE_NAME"

echo "→ server_watchdog.service újraindítása"
sudo systemctl restart "$SERVICE_NAME"

# ---------------------------------------------------------
# Feedback
# ---------------------------------------------------------
whiptail --msgbox \
"✅ Server Watchdog TELEPÍTVE / FRISSÍTVE.

Service:  $SERVICE_NAME
Script:   $DST_SCRIPT

⚠️ Fontos:
A watchdog MINDIG a legfrissebb
server_watchdog.sh scriptet futtatja.

A MagicMirror SZERVER mostantól
felügyelet alatt áll." \
16 70
