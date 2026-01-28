#!/bin/bash
set -e

# =========================================================
# MagicMirror Manager
# Version: v1.4.4
# =========================================================

MM_MANAGER_VERSION="v1.4.4"
BASE_DIR="$HOME/mm-manager"
STATE_DIR="/var/lib/mm-manager"

SYSTEM_MODE_FILE="$STATE_DIR/system_mode"
SYSTEM_MODE=$(cat "$SYSTEM_MODE_FILE" 2>/dev/null || echo "empty")

# ---------------------------------------------------------
# SYSTEM STATE (REBOOT FLAG)
# ---------------------------------------------------------
source "$BASE_DIR/mm-state.sh"
init_state

# ---------------------------------------------------------
# WHIPTAIL CHECK
# ---------------------------------------------------------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

# ---------------------------------------------------------
# COMMON SCRIPT PATHS (UNCHANGED)
# ---------------------------------------------------------
INSTALLER_SCRIPT="$BASE_DIR/installer_mode.sh"
INSTALL_CLIENT_SCRIPT="$BASE_DIR/install_client.sh"
NETWORK_SCRIPT="$BASE_DIR/network_config.sh"
DISPLAY_SCRIPT="$BASE_DIR/display_config.sh"
UPDATE_SCRIPT="$BASE_DIR/update_mm.sh"

WATCHDOG_INSTALL_SCRIPT="$BASE_DIR/watchdog_install.sh"
WATCHDOG_STATUS_SCRIPT="$BASE_DIR/watchdog_status.sh"
WATCHDOG_LOG_SCRIPT="$BASE_DIR/watchdog_log.sh"

STATUS_OVERVIEW_SCRIPT="$BASE_DIR/status_overview.sh"

CONFIG_EXPORT_SCRIPT="$BASE_DIR/config_export.sh"
CONFIG_IMPORT_SCRIPT="$BASE_DIR/config_import.sh"

SCHEDULE_REBOOT_INSTALL="$BASE_DIR/scheduled_reboot_install.sh"
SCHEDULE_REBOOT_REMOVE="$BASE_DIR/scheduled_reboot_remove.sh"

UNINSTALL_SCRIPT="$BASE_DIR/uninstall_reset.sh"
FACTORY_RESET_SCRIPT="$BASE_DIR/factory_reset.sh"

PREFLIGHT_SCRIPT="$BASE_DIR/preflight_check.sh"
CLIENT_CONNECTION_SCRIPT="$BASE_DIR/client_connection.sh"

CHECK_UPDATES_SCRIPT="$BASE_DIR/updates/check_updates.sh"
UPDATE_NPM_SCRIPT="$BASE_DIR/updates/update_npm.sh"
UPDATE_NODE_SCRIPT="$BASE_DIR/updates/update_node.sh"
UPDATE_MM_SCRIPT="$BASE_DIR/updates/update_magicmirror.sh"

ENABLE_PERSISTENT_LOGS_SCRIPT="$BASE_DIR/logs/enable_persistent_logs.sh"
VIEW_LOGS_SCRIPT="$BASE_DIR/logs/view_logs.sh"

INCREASE_SWAP_SCRIPT="$BASE_DIR/memory/increase_swap_1024.sh"
SWAP_INFO_SCRIPT="$BASE_DIR/memory/swap_info.sh"

# ---------------------------------------------------------
# SERVER SCRIPT PATHS
# ---------------------------------------------------------
SERVER_DIR="$BASE_DIR/server"

SERVER_INSTALLER_SCRIPT="$SERVER_DIR/server_installer_mode.sh"
SERVER_DISPLAY_SCRIPT="$SERVER_DIR/server_display_config.sh"
SERVER_NETWORK_SCRIPT="$SERVER_DIR/server_network_config.sh"

SERVER_WATCHDOG_INSTALL="$SERVER_DIR/server_watchdog_install.sh"
SERVER_WATCHDOG_SERVICE="server_watchdog.service"

SERVER_AUTOLOGIN_ON="$SERVER_DIR/server_enable_autologin.sh"
SERVER_AUTOLOGIN_OFF="$SERVER_DIR/server_disable_autologin.sh"

SERVER_PREFLIGHT_SCRIPT="$SERVER_DIR/server_preflight_check.sh"

# ---------------------------------------------------------
# ENSURE EXECUTABLE (SAFE)
# ---------------------------------------------------------
for s in \
  "$STATUS_OVERVIEW_SCRIPT" \
  "$INSTALLER_SCRIPT" \
  "$INSTALL_CLIENT_SCRIPT" \
  "$NETWORK_SCRIPT" \
  "$DISPLAY_SCRIPT" \
  "$UPDATE_SCRIPT" \
  "$WATCHDOG_INSTALL_SCRIPT" \
  "$WATCHDOG_STATUS_SCRIPT" \
  "$WATCHDOG_LOG_SCRIPT" \
  "$CONFIG_EXPORT_SCRIPT" \
  "$CONFIG_IMPORT_SCRIPT" \
  "$SCHEDULE_REBOOT_INSTALL" \
  "$SCHEDULE_REBOOT_REMOVE" \
  "$UNINSTALL_SCRIPT" \
  "$FACTORY_RESET_SCRIPT" \
  "$PREFLIGHT_SCRIPT" \
  "$CLIENT_CONNECTION_SCRIPT" \
  "$SERVER_INSTALLER_SCRIPT" \
  "$SERVER_DISPLAY_SCRIPT" \
  "$SERVER_NETWORK_SCRIPT" \
  "$SERVER_WATCHDOG_INSTALL" \
  "$SERVER_AUTOLOGIN_ON" \
  "$SERVER_AUTOLOGIN_OFF" \
  "$SERVER_PREFLIGHT_SCRIPT" \
  "$CHECK_UPDATES_SCRIPT" \
  "$UPDATE_NPM_SCRIPT" \
  "$UPDATE_NODE_SCRIPT" \
  "$UPDATE_MM_SCRIPT" \
  "$ENABLE_PERSISTENT_LOGS_SCRIPT" \
  "$VIEW_LOGS_SCRIPT" \
  "$INCREASE_SWAP_SCRIPT" \
  "$SWAP_INFO_SCRIPT"

do
  [ -f "$s" ] && chmod +x "$s"
done

# ---------------------------------------------------------
# DISPLAY TEST (COMMON)
# ---------------------------------------------------------
display_test() {
  whiptail --msgbox \
"🖥 Kijelző teszt

Ha ezt az ablakot látod,
a kijelző működik." \
10 60
}

# ---------------------------------------------------------
# CLIENT DISPLAY STATUS (KIEGÉSZÍTÉS – ÚJ)
# ---------------------------------------------------------
client_display_status() {

  HDMI1_STATUS="n/a"
  HDMI2_STATUS="n/a"

  ROT1=$(cat "$STATE_DIR/display_rotation_HDMI-1" 2>/dev/null || echo "normal")
  ROT2=$(cat "$STATE_DIR/display_rotation_HDMI-2" 2>/dev/null || echo "normal")

  if command -v xrandr >/dev/null 2>&1; then
    XRANDR_OUT=$(DISPLAY=:0 xrandr 2>/dev/null)
    echo "$XRANDR_OUT" | grep -q "^HDMI-1 connected" && HDMI1_STATUS="connected"
    echo "$XRANDR_OUT" | grep -q "^HDMI-1 disconnected" && HDMI1_STATUS="disconnected"
    echo "$XRANDR_OUT" | grep -q "^HDMI-2 connected" && HDMI2_STATUS="connected"
    echo "$XRANDR_OUT" | grep -q "^HDMI-2 disconnected" && HDMI2_STATUS="disconnected"
  fi

  whiptail --msgbox \
"🖥 MEGJELENÍTÉS ÁLLAPOT (CLIENT)

HDMI állapot:
  HDMI-1: $HDMI1_STATUS
  HDMI-2: $HDMI2_STATUS

HDMI forgatás:
  HDMI-1: $ROT1
  HDMI-2: $ROT2

Megjegyzés:
A beállítás a
„Kijelző / felbontás”
menüpontban történik." \
18 70
}

# ---------------------------------------------------------
# SERVER DISPLAY STATUS (EREDTI – VÁLTOZATLAN)
# ---------------------------------------------------------
server_display_status() {

  CURRENT_RES="n/a"
  ACTIVE_PROFILE=$(cat "$STATE_DIR/display_profile" 2>/dev/null || echo "auto")
  CONFIGURED_OUTPUT=$(cat "$STATE_DIR/display_output" 2>/dev/null || echo "auto")

  HDMI1_STATUS="n/a"
  HDMI2_STATUS="n/a"
  ACTIVE_OUTPUT="n/a"

  if command -v xrandr >/dev/null 2>&1; then
    XRANDR_OUT=$(DISPLAY=:0 xrandr 2>/dev/null)

    echo "$XRANDR_OUT" | grep -q "^HDMI-1 connected" && HDMI1_STATUS="connected"
    echo "$XRANDR_OUT" | grep -q "^HDMI-1 disconnected" && HDMI1_STATUS="disconnected"

    echo "$XRANDR_OUT" | grep -q "^HDMI-2 connected" && HDMI2_STATUS="connected"
    echo "$XRANDR_OUT" | grep -q "^HDMI-2 disconnected" && HDMI2_STATUS="disconnected"

    ACTIVE_OUTPUT=$(echo "$XRANDR_OUT" | awk '/ connected primary/ {print $1}')
    CURRENT_RES=$(echo "$XRANDR_OUT" | awk '/\*/ {print $1}')
  fi

  DRIVER="ismeretlen"
  grep -q 'vc4-kms-v3d' /boot/firmware/config.txt 2>/dev/null && DRIVER="KMS"
  grep -q 'vc4-fkms-v3d' /boot/firmware/config.txt 2>/dev/null && DRIVER="FKMS"

  XRANDR_ACTIVE="nem"
  grep -q '^xrandr --output HDMI-' "$HOME/.xinitrc" 2>/dev/null && XRANDR_ACTIVE="igen"

  X_FORCE_STATUS="ℹ️ X kényszerítés nem szükséges"
  if [[ "$ACTIVE_PROFILE" == "1280x720" || "$ACTIVE_PROFILE" == "1920x1080" ]]; then
    if [[ "$DRIVER" == "KMS" || "$DRIVER" == "FKMS" ]]; then
      if [ "$XRANDR_ACTIVE" = "igen" ]; then
        X_FORCE_STATUS="⚠️ KMS aktív – X kényszerítés aktív"
      else
        X_FORCE_STATUS="❌ KMS aktív – X kényszerítés HIÁNYZIK"
      fi
    fi
  fi

  ROT_HDMI1=$(cat "$STATE_DIR/display_rotation_HDMI-1" 2>/dev/null || echo "normal")
  ROT_HDMI2=$(cat "$STATE_DIR/display_rotation_HDMI-2" 2>/dev/null || echo "normal")

  whiptail --msgbox \
"🖥 MEGJELENÍTÉS ÁLLAPOT (SERVER)

Aktív X felbontás:
  $CURRENT_RES

HDMI állapot:
  HDMI-1: $HDMI1_STATUS
  HDMI-2: $HDMI2_STATUS

HDMI forgatás:
  HDMI-1: $ROT_HDMI1
  HDMI-2: $ROT_HDMI2

Grafikus driver:
  $DRIVER

X kényszerítés állapot:
  $X_FORCE_STATUS" \
26 80
}

# ---------------------------------------------------------
# UPDATE STATUS VIEW (CLIENT + SERVER)
# ---------------------------------------------------------
update_status_menu() {

  if [ ! -x "$CHECK_UPDATES_SCRIPT" ]; then
    whiptail --msgbox \
"❌ check_updates.sh nem található vagy nem futtatható!

Elvárt hely:
$CHECK_UPDATES_SCRIPT" \
10 70
    return
  fi

  UPDATE_OUTPUT=$("$CHECK_UPDATES_SCRIPT")

  whiptail --title "🔄 Frissítések állapota" \
    --scrolltext \
    --msgbox "$UPDATE_OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# UPDATE NPM (CLIENT + SERVER)
# ---------------------------------------------------------
update_npm_menu() {

  if [ ! -x "$UPDATE_NPM_SCRIPT" ]; then
    whiptail --msgbox \
"❌ update_npm.sh nem található vagy nem futtatható!

Elvárt hely:
$UPDATE_NPM_SCRIPT" \
10 70
    return
  fi

  whiptail --yesno \
"⚠️ npm frissítés

Ez a művelet:
• frissíti a globális npm-et
• nem módosítja a Node verziót
• client és server módban is érvényes

Folytatod?" \
15 70

  if [ $? -ne 0 ]; then
    return
  fi

  OUTPUT=$("$UPDATE_NPM_SCRIPT" 2>&1)

  whiptail --title "npm frissítés eredménye" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# UPDATE NODE.JS (CLIENT + SERVER)
# ---------------------------------------------------------
update_node_menu() {

  if [ ! -x "$UPDATE_NODE_SCRIPT" ]; then
    whiptail --msgbox \
"❌ update_node.sh nem található vagy nem futtatható!

Elvárt hely:
$UPDATE_NODE_SCRIPT" \
10 70
    return
  fi

  whiptail --yesno \
"⚠️ Node.js frissítés

Ez a művelet:
• LTS verzióra frissíti a Node.js-t
• NVM-et használ (rollback biztonságos)
• NEM törli a régi Node verziót
• MagicMirror újraépítés AJÁNLOTT utána

Folytatod?" \
16 70

  if [ $? -ne 0 ]; then
    return
  fi

  OUTPUT=$("$UPDATE_NODE_SCRIPT" 2>&1)

  whiptail --title "Node.js frissítés eredménye" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# UPDATE MAGICMIRROR (CLIENT + SERVER)
# ---------------------------------------------------------
update_magicmirror_menu() {

  if [ ! -x "$UPDATE_MM_SCRIPT" ]; then
    whiptail --msgbox \
"❌ update_magicmirror.sh nem található vagy nem futtatható!

Elvárt hely:
$UPDATE_MM_SCRIPT" \
10 70
    return
  fi

  whiptail --yesno \
"⚠️ MagicMirror frissítés

Ez a művelet:
• frissíti a MagicMirror forráskódot
• frissíti a Node csomagokat
• NEM módosít Node / npm verziót
• konfiguráció érintetlen marad

Folytatod?" \
16 70

  if [ $? -ne 0 ]; then
    return
  fi

  OUTPUT=$("$UPDATE_MM_SCRIPT" 2>&1)

  whiptail --title "MagicMirror frissítés eredménye" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# SERVER SYSTEM STATUS (UNCHANGED)
# ---------------------------------------------------------
server_system_status() {

  IP_ADDR=$(hostname -I | awk '{print $1}')
  MM_STATUS="NEM FUT"

  if pgrep -f "node .*server.js" >/dev/null; then
    MM_STATUS="FUT"
  fi

  whiptail --msgbox \
"📋 RENDSZER ÁLLAPOT (SERVER)

Telepítési mód:
  SERVER (Standalone)

IP cím:
  $IP_ADDR

MagicMirror:
  $MM_STATUS

Web UI:
  http://$IP_ADDR:8080" \
18 70
}

# ---------------------------------------------------------
# SERVER WATCHDOG MENU
# ---------------------------------------------------------
server_watchdog_menu() {
  CHOICE=$(whiptail --title "Szerver Watchdog" --menu \
"Válassz műveletet:" 15 70 6 \
"1" "Telepítés / Engedélyezés" \
"2" "Státusz" \
"3" "Log (élő)" \
"4" "Letiltás" \
"0" "Vissza" \
3>&1 1>&2 2>&3)

  case "$CHOICE" in
    1) bash "$SERVER_WATCHDOG_INSTALL" ;;
    2) systemctl status "$SERVER_WATCHDOG_SERVICE" ;;
    3) journalctl -u "$SERVER_WATCHDOG_SERVICE" -f ;;
    4) sudo systemctl disable --now "$SERVER_WATCHDOG_SERVICE" ;;
  esac
}

# ---------------------------------------------------------
# SERVER AUTOLOGIN MENU
# ---------------------------------------------------------
server_autologin_menu() {
  CHOICE=$(whiptail --title "Szerver Autologin" --menu \
"Autologin kezelés:" 12 60 4 \
"1" "Engedélyezés" \
"2" "Kikapcsolás" \
"0" "Vissza" \
3>&1 1>&2 2>&3)

  case "$CHOICE" in
    1) bash "$SERVER_AUTOLOGIN_ON" ;;
    2) bash "$SERVER_AUTOLOGIN_OFF" ;;
  esac
}

# ---------------------------------------------------------
# SERVER AUTOMATIC REBOOT MENU
# ---------------------------------------------------------
server_autoreboot_menu() {
  CHOICE=$(whiptail --title "Automatikus reboot" --menu \
"Automatikus reboot kezelés:" 12 60 4 \
"1" "Engedélyezés" \
"2" "Kikapcsolás" \
"0" "Vissza" \
3>&1 1>&2 2>&3)

  case "$CHOICE" in
    1) bash "$SCHEDULE_REBOOT_INSTALL" ;;
    2) bash "$SCHEDULE_REBOOT_REMOVE" ;;
  esac
}

# ---------------------------------------------------------
# ENABLE PERSISTENT LOGS
# ---------------------------------------------------------
enable_persistent_logs_menu() {

  whiptail --yesno \
"⚠️ Perzisztens logolás bekapcsolása

Ez biztosítja, hogy a rendszerlogok
reboot után is megmaradjanak.

Ajánlott kioszk rendszeren.

Folytatod?" \
15 70 || return

  OUTPUT=$("$ENABLE_PERSISTENT_LOGS_SCRIPT" 2>&1)

  whiptail --title "Logolás beállítása" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    20 80
}

# ---------------------------------------------------------
# VIEW LOGS
# ---------------------------------------------------------
view_logs_menu() {

  OUTPUT=$("$VIEW_LOGS_SCRIPT" 2>&1)

  whiptail --title "Rendszer logok" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# INCREASE SWAP TO 1024MB
# ---------------------------------------------------------
increase_swap_menu() {

  whiptail --yesno \
"⚠️ Swap növelése 1024 MB-ra

Ez segít megelőzni:
• SSH eltűnését
• OOM killer futását
• MagicMirror összeomlását

Pi3 / Pi Zero 2W esetén ERŐSEN ajánlott.

Folytatod?" \
17 70 || return

  OUTPUT=$("$INCREASE_SWAP_SCRIPT" 2>&1)

  whiptail --title "Swap növelése" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# SWAP INFO
# ---------------------------------------------------------
swap_info_menu() {

  OUTPUT=$("$SWAP_INFO_SCRIPT" 2>&1)

  whiptail --title "Swap információ" \
    --scrolltext \
    --msgbox "$OUTPUT" \
    25 80
}

# ---------------------------------------------------------
# MAIN MENU LOOP (KIEGÉSZÍTVE CLIENT MENÜVEL)
# ---------------------------------------------------------
while true; do

  MENU_ITEMS=()

  if [ "$SYSTEM_MODE" = "empty" ]; then
    MENU_ITEMS+=(
      "2"  "📦 Kliens telepítés (Client)"
      "20" "🖥  Szerver telepítés (Standalone)"
      "15" "🔍 Preflight ellenőrzés"
      "99" "🚪 Kilépés"
    )
  fi

  if [ "$SYSTEM_MODE" = "client" ]; then
    MENU_ITEMS+=(
      "1"  "📋 Rendszer állapot (Client)"
      "3"  "🖥 Kijelző / felbontás beállítása"
      "4"  "🌐 Hálózat / Fix IP beállítása"
      "5"  "🌐 MagicMirror szerver IP / port"
      "6"  "🛠 Watchdog telepítés / frissítés"
      "7"  "📊 Watchdog státusz"
      "8"  "📜 Watchdog log"
      "9"  "⏰ Automatikus reboot beállítása"
      "10" "⛔ Automatikus reboot kikapcsolása"
      "11" "📤 Konfig export"
      "12" "📥 Konfig import"
      "13" "✖ Uninstall / Reset"
      "31" "🧪 Kijelző teszt"
      "32" "🖥 Megjelenítés info (Client)"
	  "40" "🔄 Frissítések állapota"
	  "41" "🔄 npm frissítés"
	  "42" "🔄 Node.js frissítés"
	  "43" "🔄 MagicMirror frissítés"
	  "60" "📜 Logolás bekapcsolása (persistent)"
	  "61" "🔍 Rendszer logok megtekintése"
	  "62" "💾 Swap növelése (1024 MB)"
	  "63" "ℹ️ Swap információ"
	  "98" "🔁 Újraindítás"
      "99" "🚪 Kilépés"
    )
  fi

  if [ "$SYSTEM_MODE" = "server" ]; then
    MENU_ITEMS+=(
      "1"  "📋 Rendszer állapot (Szerver)"
      "21" "🛠  Kijelző / felbontás beállítása"
      "22" "🌐 Hálózat / Fix IP beállítása"
      "25" "🔐 Autologin menü >>"
      "26" "👁  Watchdog menü >>"
      "27" "⏰ Autoreboot menü >>"
      "30" "🛠  Szerver telepítés / újratelepítés"
      "38" "🧪 Kijelző teszt"
      "39" "🖥  Megjelenítés info (Szerver)"
	  "40" "🔄 Frissítések állapota"
	  "41" "🔄 npm frissítés"
	  "42" "🔄 Node.js frissítés"
	  "43" "🔄 MagicMirror frissítés"	  
	  "60" "📜 Logolás bekapcsolása (persistent)"
	  "61" "🔍 Rendszer logok megtekintése"
	  "62" "💾 Swap növelése (1024 MB)"
	  "63" "ℹ️ Swap információ"
	  "98" "🔁 Újraindítás"
      "99" "🚪 Kilépés"
    )
  fi

  CHOICE=$(whiptail --title "MM Manager $MM_MANAGER_VERSION" \
    --menu "Válassz műveletet:" 30 78 22 \
    "${MENU_ITEMS[@]}" \
    3>&1 1>&2 2>&3)

  [ $? -ne 0 ] && exit 0

  case "$CHOICE" in
    1)
      if [ "$SYSTEM_MODE" = "server" ]; then
        server_system_status
      else
        bash "$STATUS_OVERVIEW_SCRIPT"
      fi
      ;;
    2)
      bash "$PREFLIGHT_SCRIPT" soft
      export INSTALL_PROFILE="client"
      bash "$INSTALLER_SCRIPT"
      ;;	
    3)  bash "$DISPLAY_SCRIPT" ;;
    4)  bash "$NETWORK_SCRIPT" ;;
    5)  bash "$CLIENT_CONNECTION_SCRIPT" ;;
    6)  bash "$WATCHDOG_INSTALL_SCRIPT" ;;
    7)  bash "$WATCHDOG_STATUS_SCRIPT" ;;
    8)  bash "$WATCHDOG_LOG_SCRIPT" ;;
    9)  bash "$SCHEDULE_REBOOT_INSTALL" ;;
    10) bash "$SCHEDULE_REBOOT_REMOVE" ;;
    11) bash "$CONFIG_EXPORT_SCRIPT" ;;
    12) bash "$CONFIG_IMPORT_SCRIPT" ;;
    13)
      bash "$UNINSTALL_SCRIPT"
      echo "empty" | sudo tee "$SYSTEM_MODE_FILE" >/dev/null
      ;;
    15) bash "$PREFLIGHT_SCRIPT" soft ;;
    20)
      export INSTALL_TARGET="server"
      export INSTALLER_MODE=1
      bash "$SERVER_INSTALLER_SCRIPT"
      ;;
    21) bash "$SERVER_DISPLAY_SCRIPT" ;;
    22) bash "$SERVER_NETWORK_SCRIPT" ;;
    25) server_autologin_menu ;;
    26) server_watchdog_menu ;;
    27) server_autoreboot_menu ;;
	31) display_test ;;
    32) client_display_status ;;
    38) display_test ;;
    39) server_display_status ;;	
	40) update_status_menu ;;
	41) update_npm_menu ;;
	42) update_node_menu ;;
	43) update_magicmirror_menu ;;
	60) enable_persistent_logs_menu ;;
	61) view_logs_menu ;;
	62) increase_swap_menu ;;
	63) swap_info_menu ;;
	98)
      if whiptail --yesno "Biztosan újraindítod a rendszert?" 10 60; then
        clear_reboot_required
        sudo reboot
      fi
      ;;
    99) exit 0 ;;
  esac
done
