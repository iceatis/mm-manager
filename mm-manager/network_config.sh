#!/bin/bash
set -e

# =========================================================
# Network configuration – Fix IP (WiFi + Ethernet)
# Menu-safe, reboot-aware, rollback támogatással
# =========================================================

INSTALLER_MODE="${INSTALLER_MODE:-0}"

# ---------------------------------------------------------
# SYSTEM STATE (REBOOT FLAG)
# ---------------------------------------------------------
source "$HOME/mm-manager/mm-state.sh"

ui_msgbox() {
  [ "$INSTALLER_MODE" = "1" ] && return 0
  whiptail --msgbox "$1" 12 60
}

# -------- WHIPTAIL CHECK --------
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

# -------- NMCLI CHECK --------
if ! command -v nmcli >/dev/null 2>&1; then
  ui_msgbox "❌ NetworkManager (nmcli) nem található!"
  exit 1
fi

# -------- AKTÍV KAPCSOLATOK --------
ACTIVE_CONNS=$(nmcli -t -f NAME,DEVICE,TYPE connection show --active)

if [ -z "$ACTIVE_CONNS" ]; then
  ui_msgbox "❌ Nincs aktív hálózati kapcsolat."
  exit 1
fi

# -------- INTERFÉSZ VÁLASZTÁS --------
MENU_ITEMS=()
while IFS=: read -r NAME DEVICE TYPE; do
  MENU_ITEMS+=("$DEVICE" "$NAME ($TYPE)")
done <<< "$ACTIVE_CONNS"

IFACE=$(whiptail --title "Hálózati interfész" \
  --menu "Válaszd ki az interfészt:" 18 70 8 \
  "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3) || exit 1

# -------- AKTÍV CONNECTION NÉV --------
CON_NAME=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":$IFACE" | cut -d: -f1)

if [ -z "$CON_NAME" ]; then
  ui_msgbox "❌ Nem található aktív kapcsolat az interfészen: $IFACE"
  exit 1
fi

# -------- ADATBEKÉRÉS --------
STATIC_IP=$(whiptail --inputbox "Fix IP (pl. 192.168.1.50/24):" 9 60 \
  3>&1 1>&2 2>&3) || exit 1

GATEWAY_IP=$(whiptail --inputbox "Gateway IP:" 9 60 \
  3>&1 1>&2 2>&3) || exit 1

DNS_IP=$(whiptail --inputbox "DNS szerver(ek)\n(pl. 8.8.8.8,1.1.1.1):" \
  10 60 "8.8.8.8" 3>&1 1>&2 2>&3) || exit 1

# -------- ROLLBACK MENTÉS --------
ROLLBACK_FILE="$HOME/.nmcli_${CON_NAME}_backup.txt"
nmcli connection show "$CON_NAME" > "$ROLLBACK_FILE"

# -------- MEGERŐSÍTÉS --------
whiptail --yesno \
"Fix IP beállítása az alábbiakkal?\n\n\
Interfész: $IFACE\n\
Kapcsolat: $CON_NAME\n\
IP: $STATIC_IP\n\
Gateway: $GATEWAY_IP\n\
DNS: $DNS_IP\n\n\
Rollback fájl:\n$ROLLBACK_FILE\n\n\
⚠️ A módosítások reboot után lépnek életbe." \
18 70 || exit 0

# -------- KONFIGURÁLÁS (NO RESTART!) --------
sudo nmcli connection modify "$CON_NAME" \
  ipv4.method manual \
  ipv4.addresses "$STATIC_IP" \
  ipv4.gateway "$GATEWAY_IP" \
  ipv4.dns "$DNS_IP" \
  ipv4.ignore-auto-dns yes

# -------- REBOOT JELZÉS --------
set_reboot_required

# -------- KÉSZ --------
ui_msgbox \
"✅ Fix IP beállítva.\n\n\
A módosítások mentve lettek.\n\n\
🔁 ÚJRAINDÍTÁS SZÜKSÉGES az érvényesítéshez.\n\n\
A menü most visszatér."
