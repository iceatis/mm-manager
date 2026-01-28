#!/bin/bash
set -e

# =========================================================
# UNINSTALL / RESET – MagicMirror Client
# =========================================================

MM_DIR="$HOME/MagicMirror"
WATCHDOG_SERVICE="mm-watchdog.service"

# ---------------------------------------------------------
# WHIPTAIL
# ---------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

whiptail --yesno \
"⚠ MagicMirror UNINSTALL\n\n\
Ez a művelet:\n
- eltávolítja a MagicMirror klienst\n
- leállítja és törli a watchdogot\n
- kikapcsolja az automatikus indulást\n
- visszaállítja a normál login módot\n\n
Folytatod?" \
15 70 || exit 0

# ---------------------------------------------------------
# WATCHDOG STOP + REMOVE
# ---------------------------------------------------------
sudo systemctl disable --now "$WATCHDOG_SERVICE" 2>/dev/null || true
sudo rm -f "/etc/systemd/system/$WATCHDOG_SERVICE"
sudo rm -f /usr/local/bin/mm-watchdog.sh
sudo systemctl daemon-reload

# ---------------------------------------------------------
# MAGICMIRROR REMOVE
# ---------------------------------------------------------
rm -rf "$MM_DIR"

# ---------------------------------------------------------
# AUTOSTART REMOVE (.bash_profile)
# ---------------------------------------------------------
if [ -f "$HOME/.bash_profile" ]; then
  sed -i '/startx/d' "$HOME/.bash_profile"
fi

rm -f "$HOME/.xinitrc"

# ---------------------------------------------------------
# AUTOLOGIN DISABLE
# ---------------------------------------------------------
SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
AUTOLOGIN_FILE="$SERVICE_DIR/autologin.conf"

if [ -f "$AUTOLOGIN_FILE" ]; then
  sudo rm -f "$AUTOLOGIN_FILE"
  sudo systemctl daemon-reload
fi

# ---------------------------------------------------------
# WAYLAND / XORG RESET (SAFE)
# ---------------------------------------------------------
sudo rm -f /etc/X11/xorg.conf.d/10-force-xorg.conf 2>/dev/null || true

if [ -f /etc/lightdm/lightdm.conf ]; then
  sudo sed -i '/WaylandEnable=false/d' /etc/lightdm/lightdm.conf || true
fi

# ---------------------------------------------------------
# MARK SYSTEM AS EMPTY
# ---------------------------------------------------------
sudo mkdir -p /var/lib/mm-manager
echo "empty" | sudo tee /var/lib/mm-manager/system_mode >/dev/null

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
whiptail --msgbox \
"✅ MagicMirror eltávolítva.\n\n\
A rendszer visszatért normál módba.\n\n\
Újraindítás ajánlott." \
12 60

if whiptail --yesno "Újraindítod most?" 8 50; then
  sudo reboot
fi