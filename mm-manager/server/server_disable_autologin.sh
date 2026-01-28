#!/bin/bash
set -e

# =========================================================
# SERVER DISABLE AUTOLOGIN – MagicMirror
# Safe, idempotent
# v1.4.0
# =========================================================

INSTALLER_MODE="${INSTALLER_MODE:-0}"

SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
SERVICE_FILE="$SERVICE_DIR/autologin.conf"

CHANGED=0

# ---------------------------------------------------------
# Disable autologin if present
# ---------------------------------------------------------
if [ -f "$SERVICE_FILE" ]; then
  sudo rm -f "$SERVICE_FILE"
  sudo systemctl daemon-reload
  CHANGED=1
fi

# ---------------------------------------------------------
# Feedback (installer-aware)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  if [ "$CHANGED" -eq 1 ]; then
    whiptail --msgbox \
"🛑 Autologin kikapcsolva (Szerver mód).

A következő reboot után
normál bejelentkezés lesz aktív." \
10 60
  else
    whiptail --msgbox \
"ℹ️ Autologin már nem volt aktív.

Nincs további teendő." \
8 50
  fi
fi
