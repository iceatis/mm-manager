#!/bin/bash
set -e

# =========================================================
# CLIENT DISPLAY CONFIG - v1.4.4
# (HDMI-1 + HDMI-2 + ROTATION)
# Firmware + X (xrandr) coordinated handling
# (xinitrc first-line + per-HDMI handling)
# =========================================================

BASE_DIR="$HOME/mm-manager"
PROFILE_DIR="$BASE_DIR/profiles/display"
STATE_DIR="/var/lib/mm-manager"
XINITRC="$HOME/.xinitrc"

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
# WHIPTAIL
# ---------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

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
# RESOLUTION SELECTION (UNCHANGED OPTIONS)
# ---------------------------------------------------------
CHOICE=$(whiptail --menu "HDMI felbontás kiválasztása (Client)" 18 70 5 \
"kedei_800x480" "800x480 5' (Kedei)" \
"1024x600" "1024×600 (HDMI)" \
"1280x720" "1280×720 (HDMI – kényszerített)" \
"1920x1080" "1920×1080 (HDMI – kényszerített)" \
"auto" "Automatikus / EDID" \
3>&1 1>&2 2>&3) || exit 0

case "$CHOICE" in
  kedei_800x480) PROFILE="kedei_800x480.conf" ;;
  1024x600) PROFILE="1024x600.conf" ;;
  1280x720) PROFILE="1280x720.conf" ;;
  1920x1080) PROFILE="1920x1080.conf" ;;
  auto) PROFILE="auto.conf" ;;
esac

if [ -z "$PROFILE" ]; then
  whiptail --msgbox "❌ Hiba: nem sikerült kijelző profilt kiválasztani." 10 60
  exit 1
fi

# ---------------------------------------------------------
# ROTATION SELECTION (NEW – CLIENT)
# ---------------------------------------------------------
ROT1=$(whiptail --menu "HDMI-1 forgatás (Client)" 15 60 4 \
  "normal" "Landscape" \
  "right" "Portrait jobbra" \
  "left" "Portrait balra" \
  "inverted" "Fejjel lefelé" \
  3>&1 1>&2 2>&3) || { echo "Megszakítva"; exit 0; }

ROT2=$(whiptail --menu "HDMI-2 forgatás (Client)" 15 60 4 \
  "normal" "Landscape" \
  "right" "Portrait jobbra" \
  "left" "Portrait balra" \
  "inverted" "Fejjel lefelé" \
  3>&1 1>&2 2>&3) ||  { echo "Megszakítva"; exit 0; }

echo "$ROT1" | sudo tee "$ROT_HDMI1" >/dev/null
echo "$ROT2" | sudo tee "$ROT_HDMI2" >/dev/null

# ---------------------------------------------------------
# CLEAN HDMI SETTINGS (UNCHANGED)
# ---------------------------------------------------------
sudo sed -i '/hdmi_/d' "$BOOT_CONFIG"
sudo sed -i '/hdmi_cvt/d' "$BOOT_CONFIG"

if [ "$PROFILE" != "auto.conf" ]; then
  sudo tee -a "$BOOT_CONFIG" < "$PROFILE_DIR/$PROFILE" >/dev/null
fi

# ---------------------------------------------------------
# HANDLE disable_fw_kms_setup (CLIENT – REQUIRED FOR 720/1080)
# ---------------------------------------------------------
HDMI_PROFILE="${PROFILE/.conf/}"

if [ "$HDMI_PROFILE" = "1280x720" ] || [ "$HDMI_PROFILE" = "1920x1080" ]; then
  if grep -q '^disable_fw_kms_setup=1' "$BOOT_CONFIG"; then
    sudo sed -i 's/^disable_fw_kms_setup=1/#disable_fw_kms_setup=1/' "$BOOT_CONFIG"
  fi
fi

# ---------------------------------------------------------
# XINITRC – FIRST LINE INSERT (CLIENT, SAME AS SERVER)
# ---------------------------------------------------------
touch "$XINITRC"
chmod +x "$XINITRC"

if [[ "$PROFILE" == "1280x720.conf" || "$PROFILE" == "1920x1080.conf" ]]; then
  MODE="${PROFILE/.conf/}"

  XRANDR1="xrandr --output HDMI-1 --mode $MODE --rate 60 --rotate $ROT1"
  XRANDR2="xrandr --output HDMI-2 --mode $MODE --rate 60 --rotate $ROT2"

  sed -i '/^xrandr --output HDMI-1/d' "$XINITRC"
  sed -i '/^xrandr --output HDMI-2/d' "$XINITRC"

  sed -i "1i$XRANDR2" "$XINITRC"
  sed -i "1i$XRANDR1" "$XINITRC"
else
  sed -i '/^xrandr --output HDMI-1/d' "$XINITRC"
  sed -i '/^xrandr --output HDMI-2/d' "$XINITRC"
fi

# ---------------------------------------------------------
# SAVE STATE (UNCHANGED)
# ---------------------------------------------------------
echo "${PROFILE/.conf/}" | sudo tee "$STATE_DIR/display_profile" >/dev/null

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
whiptail --msgbox \
"✅ Kijelző beállítva (Client)

Profil: ${PROFILE/.conf/}
HDMI-1 forgatás: $ROT1
HDMI-2 forgatás: $ROT2

⚠ Újraindítás szükséges!" \
14 60

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
