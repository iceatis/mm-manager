#!/bin/bash
set -e

# =========================================================
# WATCHDOG STATUS – MM WATCHDOG ÁLLAPOT
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
### ÁLLAPOT LEKÉRÉS
### =========================================================

ACTIVE_STATE=$(systemctl is-active "$SERVICE" || echo "unknown")
ENABLED_STATE=$(systemctl is-enabled "$SERVICE" 2>/dev/null || echo "unknown")

### =========================================================
### MEGJELENÍTÉS
### =========================================================

whiptail --title "Watchdog státusz" --msgbox \
"MagicMirror Watchdog állapota:\n
Service:   $SERVICE
Aktív:     $ACTIVE_STATE
Indításkor: $ENABLED_STATE
" \
14 60
