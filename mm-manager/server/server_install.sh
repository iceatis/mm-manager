#!/bin/bash
set -e

# =========================================================
# SERVER INSTALLER – MagicMirror (local / standalone)
# v1.4.4
# =========================================================

export INSTALLER_MODE=1

BASE_DIR="$HOME/mm-manager"
PROFILE_DIR="$BASE_DIR/profiles/display"
MM_DIR="$HOME/MagicMirror"
USER_NAME="$(whoami)"

echo "======================================"
echo " MagicMirror SERVER telepítés (CLI)"
echo "======================================"

# ---------------------------------------------------------
# HDMI PROFILES (KERNEL LEVEL)
# ---------------------------------------------------------
mkdir -p "$PROFILE_DIR"

cat > "$PROFILE_DIR/kedei_800x480.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=2
EOF

cat > "$PROFILE_DIR/1024x600.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1024 600 60 6 0 0 0
hdmi_drive=2
EOF

cat > "$PROFILE_DIR/1280x720.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=4
hdmi_drive=2
config_hdmi_boost=7
EOF

cat > "$PROFILE_DIR/1920x1080.conf" <<EOF
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=16
hdmi_drive=2
config_hdmi_boost=7
EOF

touch "$PROFILE_DIR/auto.conf"

# ---------------------------------------------------------
# MARK SYSTEM MODE EARLY
# ---------------------------------------------------------
sudo mkdir -p /var/lib/mm-manager
echo "server" | sudo tee /var/lib/mm-manager/system_mode >/dev/null
echo "[OK] system_mode = server"

# ---------------------------------------------------------
# ENSURE NVM IN BASHRC (INTERACTIVE)
# ---------------------------------------------------------
echo "[STEP] NVM betöltés biztosítása (.bashrc)"

BASHRC="$HOME/.bashrc"
touch "$BASHRC"

if ! grep -q 'NVM_DIR=.*\.nvm' "$BASHRC"; then
cat >> "$BASHRC" <<'EOF'

# === NVM (MagicMirror SERVER) ===
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
EOF
fi

# ---------------------------------------------------------
# MAGICMIRROR CONFIG
# ---------------------------------------------------------
echo "[STEP] MagicMirror alap config ellenőrzése"

if [ ! -f "$MM_DIR/config/config.js" ]; then
  echo "[INFO] config.js hiányzott → létrehozás"
  cp "$MM_DIR/config/config.js.sample" "$MM_DIR/config/config.js"
fi

# ---------------------------------------------------------
# XINITRC – FULL ENV SETUP (CRITICAL FIX)
# ---------------------------------------------------------
echo "[STEP] .xinitrc létrehozása (NVM + MagicMirror)"

cat > "$HOME/.xinitrc" <<'EOF'
#!/bin/sh

# --- power saving OFF ---
xset -dpms
xset s off
xset s noblank
unclutter &

# --- load NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# ensure node available
nvm use default >/dev/null 2>&1 || nvm use 22 >/dev/null 2>&1

# --- start MagicMirror ---
cd "$HOME/MagicMirror" || exit 1
exec npm start
EOF

chmod +x "$HOME/.xinitrc"

# ---------------------------------------------------------
# BASH PROFILE – AUTO STARTX
# ---------------------------------------------------------
echo "[STEP] .bash_profile beállítása (startx)"

BASH_PROFILE="$HOME/.bash_profile"
touch "$BASH_PROFILE"

sed -i '/MagicMirror SERVER autostart/d' "$BASH_PROFILE" 2>/dev/null || true
sed -i '/startx/d' "$BASH_PROFILE" 2>/dev/null || true

cat >> "$BASH_PROFILE" <<'EOF'

# MagicMirror SERVER autostart
if [ "$(tty)" = "/dev/tty1" ]; then
  startx
fi
EOF

# ---------------------------------------------------------
# AUTOLOGIN
# ---------------------------------------------------------
echo "[STEP] autologin engedélyezése"

bash "$BASE_DIR/server/server_enable_autologin.sh" || true

# ---------------------------------------------------------
# MM-MANAGER COMMAND
# ---------------------------------------------------------
echo "[STEP] mm-manager parancs telepítése"

sudo ln -sf "$BASE_DIR/mm-manager.sh" /usr/local/bin/mm
sudo chmod +x "$BASE_DIR/mm-manager.sh"

# ---------------------------------------------------------
# DISPLAY CONFIG
# ---------------------------------------------------------
echo
echo "=== Kijelző konfiguráció (SERVER) ==="
bash "$BASE_DIR/server/server_display_config.sh" || true

# ---------------------------------------------------------
# FINISH
# ---------------------------------------------------------
echo
echo "======================================"
echo " A szerver telepítés BEFEJEZŐDÖTT"
echo " ÚJRAINDÍTÁS SZÜKSÉGES!"
echo "======================================"
echo
read -p "Újraindítod most? (y/N): " REBOOT

if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
  sudo reboot
else
  echo "[INFO] Kézi reboot szükséges"
fi
