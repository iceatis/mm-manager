#!/bin/bash
set -e

# =========================================================
# SERVER ENABLE AUTOLOGIN – MagicMirror
# FIXED: installer-safe, set -e compatible
# v1.4.0
# =========================================================

INSTALLER_MODE="${INSTALLER_MODE:-0}"

# ---------------------------------------------------------
# Resolve real user (important under sudo)
# ---------------------------------------------------------
if [ -n "${SUDO_USER:-}" ]; then
  RUN_USER="$SUDO_USER"
else
  RUN_USER="$(logname 2>/dev/null || whoami)"
fi

SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
SERVICE_FILE="$SERVICE_DIR/autologin.conf"

# ---------------------------------------------------------
# Ensure directory exists
# ---------------------------------------------------------
sudo mkdir -p "$SERVICE_DIR"

# ---------------------------------------------------------
# Desired content (SAFE heredoc)
# ---------------------------------------------------------
AUTOLOGIN_CONF=$(cat <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $RUN_USER --noclear %I \$TERM
EOF
)

# ---------------------------------------------------------
# Write only if different (idempotent)
# ---------------------------------------------------------
NEED_WRITE=1
if [ -f "$SERVICE_FILE" ]; then
  if sudo cat "$SERVICE_FILE" | diff -q - <(echo "$AUTOLOGIN_CONF") >/dev/null 2>&1; then
    NEED_WRITE=0
  fi
fi

if [ "$NEED_WRITE" -eq 1 ]; then
  echo "$AUTOLOGIN_CONF" | sudo tee "$SERVICE_FILE" >/dev/null
  sudo systemctl daemon-reload
fi

# ---------------------------------------------------------
# Feedback (only outside installer)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  whiptail --msgbox \
"✅ Autologin engedélyezve (Szerver mód).

Felhasználó: $RUN_USER
TTY: tty1" \
10 60
fi

# ---------------------------------------------------------
# NEVER kill parent installer
# ---------------------------------------------------------
exit 0
