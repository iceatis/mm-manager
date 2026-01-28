#!/bin/bash
set -e

# =========================================================
# MagicMirror Installer Mode
# UI / CLI selectable (CLIENT ONLY)
# =========================================================

BASE_DIR="$HOME/mm-manager"
LOGFILE="/tmp/mm-installer.log"

source "$BASE_DIR/mm-state.sh"

# ---------------------------------------------------------
# DEFAULTS
# ---------------------------------------------------------
INSTALL_PROFILE="${INSTALL_PROFILE:-client}"
INSTALL_TARGET="${INSTALL_TARGET:-client}"

# ---------------------------------------------------------
# SERVER INSTALL → FORCE CLI, SKIP UI QUESTION
# ---------------------------------------------------------
if [ "$INSTALL_TARGET" = "server" ]; then
  export INSTALLER_MODE=1
  INSTALL_DISPLAY_MODE="CLI"
else
  export INSTALLER_MODE=1
fi

# ---------------------------------------------------------
# WHIPTAIL CHECK (CLIENT ONLY)
# ---------------------------------------------------------
if [ "$INSTALL_TARGET" != "server" ]; then
  if ! command -v whiptail >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y whiptail
  fi
fi

# ---------------------------------------------------------
# INSTALL DISPLAY MODE (CLIENT ONLY)
# ---------------------------------------------------------
if [ "$INSTALL_TARGET" != "server" ]; then
  INSTALL_DISPLAY_MODE=$(whiptail --title "Telepítési mód" --menu \
  "Hogyan szeretnéd futtatni a telepítést?" 12 70 2 \
  "UI"  "Grafikus (állapotsáv + élő napló)" \
  "CLI" "Parancssoros (teljes kimenet)" \
  3>&1 1>&2 2>&3) || exit 0
fi

# ---------------------------------------------------------
# INSTALL PROFILE (CLIENT LOGIC – UNCHANGED)
# ---------------------------------------------------------
if [ "$INSTALL_PROFILE" = "zero" ]; then
  DEPS_SCRIPT="$BASE_DIR/install_dependencies_zero.sh"
  PROFILE_LABEL="Pi Zero / Zero 2 W (optimalizált)"
else
  DEPS_SCRIPT="$BASE_DIR/install_dependencies.sh"
  PROFILE_LABEL="Pi Zero 2W / 3 / 4 / 5"
fi

# ---------------------------------------------------------
# PRE-INSTALL QUESTIONS (CLIENT ONLY)
# ---------------------------------------------------------
if [ "$INSTALL_TARGET" != "server" ]; then

  MM_SERVER_IP=$(whiptail --inputbox "MagicMirror SERVER IP:" 8 50 \
    3>&1 1>&2 2>&3) || exit 1

  MM_SERVER_PORT=$(whiptail --inputbox "MagicMirror PORT:" 8 50 "8080" \
    3>&1 1>&2 2>&3) || exit 1

  HDMI_PROFILE=$(whiptail --menu "Kijelző / felbontás kiválasztása" 18 70 6 \
    "kedei_800x480" "5\" Kedei 800×480 (HDMI)" \
    "1024x600" "1024×600 (HDMI)" \
    "1280x720" "1280×720 (HDMI)" \
    "1920x1080" "1920×1080 (HDMI)" \
    "auto" "Automatikus / DSI / DPI (szalagkábel)" \
    3>&1 1>&2 2>&3) || exit 1

  export MM_SERVER_IP MM_SERVER_PORT HDMI_PROFILE
fi

# ---------------------------------------------------------
# PREP LOG
# ---------------------------------------------------------
: > "$LOGFILE"

run_cli_install() {
  clear
  echo "=== MagicMirror telepítés (CLI mód) ==="
  echo "Profil: $PROFILE_LABEL"
  echo

  sudo apt update
  bash "$DEPS_SCRIPT"
  bash "$BASE_DIR/install_client.sh"
  bash "$BASE_DIR/enable_autologin.sh"
  bash "$BASE_DIR/force_xorg.sh"

  echo
  echo "✔ Telepítés befejezve"
  read -rp "Nyomj Entert a folytatáshoz..."
}

run_ui_install() {
  run_step() {
    local PERCENT="$1"
    local TITLE="$2"
    shift 2
    echo "$PERCENT"
    echo "XXX"
    echo "$TITLE"
    echo "XXX"
    "$@" >>"$LOGFILE" 2>&1
  }

  (
    run_step 5  "Rendszer frissítése..." \
      sudo apt update -y

    run_step 35 "Függőségek telepítése – $PROFILE_LABEL" \
      bash "$DEPS_SCRIPT"

    run_step 65 "MagicMirror kliens beállítása..." \
      bash "$BASE_DIR/install_client.sh"

    run_step 80 "Automatikus bejelentkezés engedélyezése..." \
      bash "$BASE_DIR/enable_autologin.sh"

    run_step 90 "Xorg kényszerítése (Wayland tiltása)..." \
      bash "$BASE_DIR/force_xorg.sh"

    echo "100"
    echo "XXX"
    echo "Telepítés kész"
    echo "XXX"
  ) | whiptail --title "MagicMirror Installer" \
      --gauge "Telepítés folyamatban...\nProfil: $PROFILE_LABEL\n\nÉlő napló alul frissül" \
      15 80 0 &
}

# ---------------------------------------------------------
# RUN INSTALLER
# ---------------------------------------------------------
if [ "$INSTALL_DISPLAY_MODE" = "CLI" ]; then
  run_cli_install
else
  run_ui_install
fi

# ---------------------------------------------------------
# POST-INSTALL
# ---------------------------------------------------------
set_reboot_required

if whiptail --yesno \
"✅ Telepítés sikeresen befejeződött.\n\n\
Profil: $PROFILE_LABEL\n\n\
🔁 A módosítások teljes érvényesítéséhez\n\
rendszer újraindítás AJÁNLOTT.\n\n\
Szeretnéd MOST újraindítani?" \
14 70; then
  clear_reboot_required
  sudo reboot
fi

whiptail --msgbox \
"ℹ️ A rendszer készen áll.\n\n\
Az új beállítások a következő újraindításkor\nlépnek életbe." \
10 60
