#!/bin/bash
set -e

# =========================================================
# WATCHDOG LOG – ÉLŐ JOURNAL LOG
# =========================================================

SERVICE="mm-watchdog.service"

### ===== WHIPTAIL =====
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

### =========================================================
### SERVICE LÉTEZÉS ELLENŐRZÉS
### =========================================================

if ! systemctl list-unit-files | grep -q "^$SERVICE"; then
  whiptail --msgbox \
"❌ A watchdog szolgáltatás nem található.\n\nService:\n$SERVICE" \
10 60
  exit 0
fi

### =========================================================
### TÁJÉKOZTATÁS
### =========================================================

whiptail --title "Watchdog log" --yesno \
"A MagicMirror Watchdog élő logja fog megnyílni.\n\n
Kilépés: Ctrl+C\n\n
Folytatod?" \
12 60

if [ $? -ne 0 ]; then
  exit 0
fi

### =========================================================
### LOG MEGJELENÍTÉS
### =========================================================

clear
echo "=== Watchdog élő log: $SERVICE ==="
echo "Kilépés: Ctrl+C"
echo "--------------------------------"

sudo journalctl -u "$SERVICE" -f
