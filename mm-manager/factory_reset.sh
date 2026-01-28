#!/bin/bash
set -e

# =========================================================
# FACTORY RESET – MagicMirror Kiosk
# =========================================================

MM_DIR="$HOME/MagicMirror"
WATCHDOG_SERVICE="mm-watchdog.service"
REBOOT_TIMER="mm-scheduled-reboot.timer"

# ---------------------------------------------------------
# WHIPTAIL
# ---------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

whiptail --yesno \
"⚠ FACTORY RESET\n\n\
Ez a művelet:\n
- TELJESEN eltávolítja a MagicMirror-t\n
- törli a watchdogot és időzített rebootot\n
- visszaállítja a kijelzőt és hálózatot\n
- kikapcsolja az autologint\n
- mm-manager MEGMARAD\n\n
Folytatod?" \
15 70 || exit 0

whiptail --yesno \
"⚠ UTOLSÓ MEGERŐSÍTÉS\n\n\
Ez NEM vonható vissza.\n\n\
Biztos vagy benne?" \
12 60 || exit 0

# ---------------------------------------------------------
# WATCHDOG REMOVE
# ---------------------------------------------------------
sudo systemctl disable --now "$WATCHDOG_SERVICE" 2>/dev/null || true
sudo rm -f "/etc/systemd/system/$WATCHDOG_SERVICE"
sudo rm -f /usr/local/bin/mm-watchdog.sh

# ---------------------------------------------------------
# SCHEDULED REBOOT REMOVE
# ---------------------------------------------------------
sudo systemctl disable --now "$REBOOT_TIMER" 2>/dev/null || true
sudo rm -f /etc/systemd/system/mm-scheduled-reboot.*
sudo systemctl daemon-reload

# ---------------------------------------------------------
# MAGICMIRROR REMOVE
# ---------------------------------------------------------
rm -rf "$MM_DIR"

# ---------------------------------------------------------
# AUTOSTART REMOVE
# ---------------------------------------------------------
sed -i '/startx/d' "$HOME/.bash_profile" 2>/dev/null || true
rm -f "$HOME/.xinitrc"

# ---------------------------------------------------------
# AUTOLOGIN DISABLE
# ---------------------------------------------------------
SERVICE_DIR="/etc/systemd/system/getty@tty1.service.d"
sudo rm -f "$SERVICE_DIR/autologin.conf" 2>/dev/null || true

# ---------------------------------------------------------
# WAYLAND / XORG RESET
# ---------------------------------------------------------
sudo rm -f /etc/X11/xorg.conf.d/10-force-xorg.conf 2>/dev/null || true

if [ -f /etc/lightdm/lightdm.conf ]; then
  sudo sed -i '/WaylandEnable=false/d' /etc/lightdm/lightdm.conf || true
fi

# ---------------------------------------------------------
# DISPLAY RESET
# ---------------------------------------------------------
if [ -f /boot/firmware/config.txt ]; then
  BOOT_CONFIG="/boot/firmware/config.txt"
  CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f /boot/config.txt ]; then
  BOOT_CONFIG="/boot/config.txt"
  CMDLINE_FILE="/boot/cmdline.txt"
fi

if [ -n "$BOOT_CONFIG" ]; then
  sudo sed -i '/hdmi_/d' "$BOOT_CONFIG"
  sudo sed -i '/hdmi_cvt/d' "$BOOT_CONFIG"
fi

if [ -n "$CMDLINE_FILE" ]; then
  sudo sed -i 's/ video=HDMI-A-1:[^ ]*//g' "$CMDLINE_FILE"
fi

# ---------------------------------------------------------
# NETWORK RESET → DHCP
# ---------------------------------------------------------
ACTIVE_CONNS=$(nmcli -t -f NAME connection show --active | cut -d: -f1)

for CON in $ACTIVE_CONNS; do
  sudo nmcli connection modify "$CON" ipv4.method auto
  sudo nmcli connection up "$CON" >/dev/null 2>&1 || true
done

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
whiptail --msgbox \
"✅ FACTORY RESET KÉSZ\n\n\
A rendszer gyári állapotban van.\n\n\
Újraindítás ajánlott." \
12 60

if whiptail --yesno "Újraindítod most?" 8 50; then
  sudo reboot
fi
