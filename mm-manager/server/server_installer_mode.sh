#!/bin/bash
set -e

# =========================================================
# SERVER INSTALLER MODE – MagicMirror
# CLI ONLY – UI DISABLED
# v1.4.2
# =========================================================

BASE_DIR="$HOME/mm-manager"
LOGFILE="/tmp/mm-server-installer.log"

source "$BASE_DIR/mm-state.sh"

# ---------------------------------------------------------
# SERVER INSTALL = ALWAYS CLI
# ---------------------------------------------------------
export INSTALL_TARGET="server"
export INSTALLER_MODE=1
INSTALL_DISPLAY_MODE="CLI"

# ---------------------------------------------------------
# PREP LOG
# ---------------------------------------------------------
: > "$LOGFILE"

run_cli_install() {
  clear
  echo "=== MagicMirror SZERVER telepítés (CLI mód) ==="
  echo

  bash "$BASE_DIR/server/server_preflight_check.sh" hard
  bash "$BASE_DIR/server/server_install_dependencies.sh"
  bash "$BASE_DIR/server/server_install.sh"
  bash "$BASE_DIR/server/server_enable_autologin.sh"
  bash "$BASE_DIR/force_xorg.sh"

  echo
  echo "✔ Szerver telepítés befejezve"
  read -rp "Nyomj Entert a folytatáshoz..."
}

# ---------------------------------------------------------
# RUN INSTALLER (CLI ONLY)
# ---------------------------------------------------------
run_cli_install

# ---------------------------------------------------------
# POST-INSTALL
# ---------------------------------------------------------
set_reboot_required

if whiptail --yesno \
"✅ MagicMirror Szerver telepítés sikeres.\n\n\
🔁 A módosítások teljes érvényesítéséhez\n\
rendszer újraindítás AJÁNLOTT.\n\n\
Szeretnéd MOST újraindítani?" \
14 70; then
  clear_reboot_required
  sudo reboot
fi

whiptail --msgbox \
"ℹ️ A szerver készen áll.\n\n\
Az új beállítások a következő újraindításkor\nlépnek életbe." \
10 60

# mark system as MagicMirror SERVER installed
sudo mkdir -p /var/lib/mm-manager
echo "server" | sudo tee /var/lib/mm-manager/system_mode >/dev/null
