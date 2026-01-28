#!/bin/bash
set -e

# =========================================================
# SERVER DISPLAY CONFIG – v1.4.4
# (HDMI-1 + HDMI-2 + ROTATION)
# Firmware + X (xrandr) coordinated handling
# (xinitrc first-line + per-HDMI handling)
# =========================================================

BASE_DIR="$HOME/mm-manager"
PROFILE_DIR="$BASE_DIR/profiles/display"
STATE_DIR="/var/lib/mm-manager"
XINITRC="$HOME/.xinitrc"

INSTALLER_MODE="${INSTALLER_MODE:-0}"
HDMI_PROFILE="${HDMI_PROFILE:-}"

ROT_HDMI1="$STATE_DIR/display_rotation_HDMI-1"
ROT_HDMI2="$STATE_DIR/display_rotation_HDMI-2"

mkdir -p "$PROFILE_DIR" 
sudo mkdir -p "$STATE_DIR"

# ---------------------------------------------------------
# INIT ROTATION STATE (DEFAULT = normal)
# ---------------------------------------------------------
[ -f "$ROT_HDMI1" ] || echo "normal" | sudo tee "$ROT_HDMI1" >/dev/null
[ -f "$ROT_HDMI2" ] || echo "normal" | sudo tee "$ROT_HDMI2" >/dev/null

# ---------------------------------------------------------
# BOOT CONFIG DETECTION
# ---------------------------------------------------------
if [ -f /boot/firmware/config.txt ]; then
  BOOT_CONFIG="/boot/firmware/config.txt"
  CMDLINE_FILE="/boot/firmware/cmdline.txt"
else
  BOOT_CONFIG="/boot/config.txt"
  CMDLINE_FILE="/boot/cmdline.txt"
fi

# ---------------------------------------------------------
# RUNTIME STATUS (UNCHANGED)
# ---------------------------------------------------------
CURRENT_RES="n/a"
EDID_MODES="n/a"

if command -v xrandr >/dev/null 2>&1; then
  CURRENT_RES=$(DISPLAY=:0 xrandr 2>/dev/null | awk '/\*/ {print $1 " @" $2}')
fi

DRM_NODE=$(ls /sys/class/drm/ | grep -E 'HDMI-A-[0-9]+' | head -n1)
if [ -n "$DRM_NODE" ] && [ -f "/sys/class/drm/$DRM_NODE/modes" ]; then
  EDID_MODES=$(tr '\n' ' ' < "/sys/class/drm/$DRM_NODE/modes")
fi

ACTIVE_PROFILE=$(cat "$STATE_DIR/display_profile" 2>/dev/null || echo "auto")

# ---------------------------------------------------------
# STATUS SCREEN (UNCHANGED)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  whiptail --msgbox \
"🖥 MEGJELENÍTÉS ÁLLAPOT (SERVER)

Aktív X felbontás:
  $CURRENT_RES

Monitor EDID módok:
  $EDID_MODES

Beállított firmware profil:
  $ACTIVE_PROFILE" \
18 80
fi

# ---------------------------------------------------------
# RESOLUTION SELECTION (UNCHANGED)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  HDMI_PROFILE=$(whiptail --title "Szerver kijelző beállítás" --menu \
"HDMI felbontás kiválasztása:" 20 72 7 \
"kedei_800x480" "800×480 5' (Kedei)" \
"1024x600"     "1024×600 (HDMI)" \
"1280x720"     "1280×720 (HDMI – kényszerített)" \
"1920x1080"    "1920×1080 (HDMI – kényszerített)" \
"auto"         "Automatikus / EDID" \
3>&1 1>&2 2>&3) || exit 0
else
  HDMI_PROFILE="${HDMI_PROFILE:-auto}"
fi

# ---------------------------------------------------------
# CLEAN OLD HDMI SETTINGS (UNCHANGED)
# ---------------------------------------------------------
sudo sed -i '/hdmi_/d' "$BOOT_CONFIG"
sudo sed -i '/hdmi_cvt/d' "$BOOT_CONFIG"
sudo sed -i '/config_hdmi_boost/d' "$BOOT_CONFIG"
sudo sed -i '/disable_overscan/d' "$BOOT_CONFIG"

# ---------------------------------------------------------
# APPLY FIRMWARE PROFILE (UNCHANGED)
# ---------------------------------------------------------
if [ "$HDMI_PROFILE" != "auto" ]; then
  sudo tee -a "$BOOT_CONFIG" < "$PROFILE_DIR/$HDMI_PROFILE.conf" >/dev/null
fi

# ---------------------------------------------------------
# HANDLE disable_fw_kms_setup (UNCHANGED)
# ---------------------------------------------------------
if [ "$HDMI_PROFILE" = "1280x720" ] || [ "$HDMI_PROFILE" = "1920x1080" ]; then
  if grep -q '^disable_fw_kms_setup=1' "$BOOT_CONFIG"; then
    sudo sed -i 's/^disable_fw_kms_setup=1/#disable_fw_kms_setup=1/' "$BOOT_CONFIG"
  fi
fi

# ---------------------------------------------------------
# ROTATION SELECTION (UNCHANGED)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  ROT1=$(whiptail --menu "HDMI-1 forgatás" 15 60 4 \
    "normal" "Landscape (normal)" \
    "right" "Portrait jobbra" \
    "left" "Portrait balra" \
    "inverted" "Fejjel lefelé" \
    3>&1 1>&2 2>&3) || exit 0

  ROT2=$(whiptail --menu "HDMI-2 forgatás" 15 60 4 \
    "normal" "Landscape (normal)" \
    "right" "Portrait jobbra" \
    "left" "Portrait balra" \
    "inverted" "Fejjel lefelé" \
    3>&1 1>&2 2>&3) || exit 0

  echo "$ROT1" | sudo tee "$ROT_HDMI1" >/dev/null
  echo "$ROT2" | sudo tee "$ROT_HDMI2" >/dev/null
fi

ROT1=$(cat "$ROT_HDMI1")
ROT2=$(cat "$ROT_HDMI2")

# ---------------------------------------------------------
# XINITRC – FIRST-LINE INSERT / PER-HDMI REMOVE (MODIFIED)
# ---------------------------------------------------------
touch "$XINITRC"
chmod +x "$XINITRC"

if [ "$HDMI_PROFILE" = "1280x720" ] || [ "$HDMI_PROFILE" = "1920x1080" ]; then

  XRANDR_LINE_HDMI1="xrandr --output HDMI-1 --mode $HDMI_PROFILE --rate 60 --rotate $ROT1"
  XRANDR_LINE_HDMI2="xrandr --output HDMI-2 --mode $HDMI_PROFILE --rate 60 --rotate $ROT2"

  sed -i '/^xrandr --output HDMI-1/d' "$XINITRC"
  sed -i '/^xrandr --output HDMI-2/d' "$XINITRC"

  sed -i "1i$XRANDR_LINE_HDMI2" "$XINITRC"
  sed -i "1i$XRANDR_LINE_HDMI1" "$XINITRC"

else
  if [ -f "$XINITRC" ]; then
    sed -i '/^xrandr --output HDMI-1/d' "$XINITRC"
    sed -i '/^xrandr --output HDMI-2/d' "$XINITRC"
  fi
fi

# ---------------------------------------------------------
# SAVE STATE (UNCHANGED)
# ---------------------------------------------------------
echo "$HDMI_PROFILE" | sudo tee "$STATE_DIR/display_profile" >/dev/null

# ---------------------------------------------------------
# FINAL NOTICE (UNCHANGED)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  whiptail --msgbox \
"✅ Kijelzőprofil mentve: $HDMI_PROFILE

HDMI-1 forgatás: $ROT1
HDMI-2 forgatás: $ROT2

A módosítás a következő
ÚJRAINDÍTÁS után lép életbe." \
14 70
fi

exit 0


# =========================================================
# IMPORTANT:
# display_config.sh and server_display_config.sh
# MUST stay functionally identical in:
# - firmware profile handling
# - disable_fw_kms_setup logic
# - xinitrc xrandr injection
# Any change must be mirrored in both scripts.
# =========================================================
