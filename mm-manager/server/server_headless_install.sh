#!/bin/bash
set -e

# =========================================================
# HEADLESS MAGICMIRROR INSTALL
# =========================================================

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE_DIR="$BASE_DIR/profiles/display"

# -------------------------------
# DEFAULTS
# -------------------------------
MM_PORT="8080"
DISPLAY_PROFILE="auto"
AUTOSTART="yes"

# -------------------------------
# ARGUMENT PARSING
# -------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --server-ip)
      MM_SERVER_IP="$2"
      shift 2
      ;;
    --port)
      MM_PORT="$2"
      shift 2
      ;;
    --display)
      DISPLAY_PROFILE="$2"
      shift 2
      ;;
    --autostart)
      AUTOSTART="$2"
      shift 2
      ;;
    *)
      echo "❌ Ismeretlen paraméter: $1"
      exit 1
      ;;
  esac
done

if [ -z "$MM_SERVER_IP" ]; then
  echo "❌ Hiányzó kötelező paraméter: --server-ip"
  exit 1
fi

# -------------------------------
# DISPLAY PROFILE MAP
# -------------------------------
case "$DISPLAY_PROFILE" in
  kedei_800x480) PROFILE_FILE="kedei_800x480.conf" ;;
  1024x600)     PROFILE_FILE="1024x600.conf" ;;
  1280x720)     PROFILE_FILE="1280x720.conf" ;;
  1920x1080)    PROFILE_FILE="1920x1080.conf" ;;
  auto)         PROFILE_FILE="auto.conf" ;;
  *)
    echo "❌ Ismeretlen display profil: $DISPLAY_PROFILE"
    exit 1
    ;;
esac

# -------------------------------
# 1️⃣ DEPENDENCIES
# -------------------------------
echo "▶ Függőségek telepítése..."
bash "$BASE_DIR/install_dependencies.sh"

# -------------------------------
# 2️⃣ DISPLAY CONFIG (HEADLESS)
# -------------------------------
echo "▶ HDMI konfiguráció..."

BOOT_CONFIG="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/firmware/cmdline.txt"

sudo sed -i '/hdmi_/d' "$BOOT_CONFIG"
sudo sed -i '/hdmi_cvt/d' "$BOOT_CONFIG"
sudo tee -a "$BOOT_CONFIG" < "$PROFILE_DIR/$PROFILE_FILE" >/dev/null

sudo sed -i 's/ video=HDMI-A-1:[^ ]*//g' "$CMDLINE_FILE"

if [ "$PROFILE_FILE" = "kedei_800x480.conf" ]; then
  sudo sed -i 's/$/ video=HDMI-A-1:800x480@60D/' "$CMDLINE_FILE"
fi

# -------------------------------
# 3️⃣ XINITRC + CLIENT
# -------------------------------
echo "▶ Client konfiguráció..."

cat > "$HOME/.xinitrc" <<EOF
#!/bin/sh
export NVM_DIR="\$HOME/.nvm"
[ -f "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"

xset -dpms
xset s off
xset s noblank
unclutter &

cd "\$HOME/MagicMirror"
node clientonly --address $MM_SERVER_IP --port $MM_PORT
EOF

chmod +x "$HOME/.xinitrc"

# -------------------------------
# 4️⃣ AUTOSTART
# -------------------------------
if [ "$AUTOSTART" = "yes" ]; then
  echo 'if [ "$(tty)" = "/dev/tty1" ]; then startx; fi' \
    >> "$HOME/.bash_profile"
fi

# -------------------------------
# KÉSZ
# -------------------------------
echo "✅ Headless telepítés kész."
echo "⚠ Reboot szükséges."
