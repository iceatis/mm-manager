#!/bin/bash
set -e

# =========================================================
# CLIENT INSTALLER – MagicMirror (client)
# v1.4.4
# =========================================================

BASE_DIR="$HOME/mm-manager"
PROFILE_DIR="$BASE_DIR/profiles/display"
MM_DIR="$HOME/MagicMirror"

INSTALLER_MODE="${INSTALLER_MODE:-0}"

mkdir -p "$PROFILE_DIR"

# ---------------------------------------------------------
# SYSTEM STATE (REBOOT FLAG)
# ---------------------------------------------------------
source "$BASE_DIR/mm-state.sh"

# ---------------------------------------------------------
# UI HELPERS (DISABLED IN INSTALLER MODE)
# ---------------------------------------------------------
ui_msgbox() {
  [ "$INSTALLER_MODE" = "1" ] && return 0
  whiptail --msgbox "$1" 12 60
}

ui_inputbox() {
  [ "$INSTALLER_MODE" = "1" ] && return 1
  whiptail --inputbox "$1" 8 50 "$2" 3>&1 1>&2 2>&3
}

ui_menu() {
  [ "$INSTALLER_MODE" = "1" ] && return 1
  whiptail --menu "$@"
}

# ---------------------------------------------------------
# HDMI PROFILES (KERNEL LEVEL)
# ---------------------------------------------------------
cat > "$PROFILE_DIR/kedei_800x480.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
EOF

cat > "$PROFILE_DIR/1024x600.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1024 600 60 6 0 0 0
EOF

cat > "$PROFILE_DIR/1280x720.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=4
EOF

cat > "$PROFILE_DIR/1920x1080.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=16
EOF

touch "$PROFILE_DIR/auto.conf"

# ---------------------------------------------------------
# SERVER CONFIG
# (installer_mode.sh already exported these)
# ---------------------------------------------------------
[ -z "$MM_SERVER_IP" ] && MM_SERVER_IP=$(ui_inputbox "MagicMirror SERVER IP:" "")
[ -z "$MM_SERVER_PORT" ] && MM_SERVER_PORT=$(ui_inputbox "MagicMirror PORT:" "8080")

[ -z "$MM_SERVER_IP" ] && exit 1
[ -z "$MM_SERVER_PORT" ] && exit 1

# ---------------------------------------------------------
# HDMI PROFILE
# ---------------------------------------------------------
if [ -z "$HDMI_PROFILE" ]; then
  HDMI_PROFILE=$(ui_menu "Kijelző / felbontás" 18 70 6 \
    "kedei_800x480" "5\" Kedei 800×480 (HDMI)" \
    "1024x600" "1024×600 (HDMI)" \
    "1280x720" "1280×720 (HDMI)" \
    "1920x1080" "1920×1080 (HDMI)" \
    "auto" "Automatikus / DSI / DPI (szalagkábel)" \
    3>&1 1>&2 2>&3)
fi

# ---------------------------------------------------------
# BOOT CONFIG
# ---------------------------------------------------------
if [ -f /boot/firmware/config.txt ]; then
  BOOT_CONFIG="/boot/firmware/config.txt"
  CMDLINE_FILE="/boot/firmware/cmdline.txt"
else
  BOOT_CONFIG="/boot/config.txt"
  CMDLINE_FILE="/boot/cmdline.txt"
fi

sudo sed -i '/hdmi_/d' "$BOOT_CONFIG"
sudo sed -i '/hdmi_cvt/d' "$BOOT_CONFIG"

[ "$HDMI_PROFILE" != "auto" ] &&
  sudo tee -a "$BOOT_CONFIG" < "$PROFILE_DIR/$HDMI_PROFILE.conf" >/dev/null

sudo sed -i 's/ video=HDMI-A-1:[^ ]*//g' "$CMDLINE_FILE"

[ "$HDMI_PROFILE" = "kedei_800x480" ] &&
  sudo sed -i 's/$/ video=HDMI-A-1:800x480@60D/' "$CMDLINE_FILE"

# ---------------------------------------------------------
# XINITRC
# ---------------------------------------------------------
cat > "$HOME/.xinitrc" <<EOF
#!/bin/sh

export NVM_DIR="\$HOME/.nvm"
[ -f "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

xset -dpms
xset s off
xset s noblank
unclutter &

EOF

# --- Kedei-specific Xorg resolution fix ---
if [ "$HDMI_PROFILE" = "kedei_800x480" ]; then
cat >> "$HOME/.xinitrc" <<'EOF'
OUTPUT=$(xrandr | awk '/ connected/{print $1; exit}')

xrandr --newmode "800x480_60.00" 29.58 \
  800 824 896 992 \
  480 483 493 500 \
  -hsync +vsync 2>/dev/null || true

xrandr --addmode "$OUTPUT" "800x480_60.00" 2>/dev/null || true
xrandr --output "$OUTPUT" --mode "800x480_60.00"
EOF
fi

cat >> "$HOME/.xinitrc" <<EOF

cd "\$HOME/MagicMirror"
node clientonly --address $MM_SERVER_IP --port $MM_SERVER_PORT
EOF

chmod +x "$HOME/.xinitrc"

# ---------------------------------------------------------
# AUTO X START (TTY1 – NO HEADLESS CHECK)
# ---------------------------------------------------------
BASH_PROFILE="$HOME/.bash_profile"

sed -i '/MagicMirror kiosk autostart/d' "$BASH_PROFILE" 2>/dev/null || true
sed -i '/startx/d' "$BASH_PROFILE" 2>/dev/null || true

cat >> "$BASH_PROFILE" <<'EOF'

# MagicMirror kiosk autostart
if [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF

# ---------------------------------------------------------
# MM MANAGER GLOBAL COMMAND (FINAL FIX)
# ---------------------------------------------------------
if [ -f "$BASE_DIR/mm-manager.sh" ]; then
  sudo ln -sf "$BASE_DIR/mm-manager.sh" /usr/local/bin/mm
  sudo chmod +x "$BASE_DIR/mm-manager.sh"
fi

# ---------------------------------------------------------
# UX INFO – DISPLAY ROTATION (CLIENT)
# ---------------------------------------------------------
ui_msgbox "ℹ️ Kijelző beállítás

A MagicMirror kliens telepítése elkészült.

FONTOS:
A kijelző orientáció (álló / fekvő mód),
valamint a HDMI-1 / HDMI-2 kimenetek
beállítása NEM a telepítés során történik.

👉 Ezeket itt tudod módosítani:
mm-manager → Kijelző / felbontás

A beállítások bármikor megváltoztathatók."

set_reboot_required

ui_msgbox "✅ MagicMirror kliens telepítve.

Parancs: mm
Felbontás: $HDMI_PROFILE

Reboot után automatikusan indul."

# mark system as MagicMirror CLIENT installed
sudo mkdir -p /var/lib/mm-manager
echo "client" | sudo tee /var/lib/mm-manager/system_mode >/dev/null
