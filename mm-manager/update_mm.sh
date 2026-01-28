#!/bin/bash
set -e

# =========================================================
# MAGICMIRROR UPDATE – STABIL, NVM-BIZTOS
# =========================================================

MM_DIR="$HOME/MagicMirror"
NVM_DIR="$HOME/.nvm"

### ===== WHIPTAIL =====
if ! command -v whiptail >/dev/null 2>&1; then
  sudo apt update
  sudo apt install -y whiptail
fi

### =========================================================
### MAGICMIRROR ELLENŐRZÉS
### =========================================================

if [ ! -d "$MM_DIR" ]; then
  whiptail --msgbox "❌ MagicMirror nincs telepítve:\n$MM_DIR" 8 55
  exit 1
fi

### =========================================================
### NVM + NODE ELLENŐRZÉS
### =========================================================

if [ ! -f "$NVM_DIR/nvm.sh" ]; then
  whiptail --msgbox "❌ NVM nem található.\n\nA frissítés nem folytatható." 10 55
  exit 1
fi

# NVM betöltése
export NVM_DIR="$NVM_DIR"
. "$NVM_DIR/nvm.sh"

# Node ellenőrzés
if ! command -v node >/dev/null 2>&1; then
  whiptail --msgbox "❌ Node.js nem érhető el.\n\nEllenőrizd az NVM-et!" 10 55
  exit 1
fi

### =========================================================
### FRISSÍTÉS
### =========================================================

whiptail --infobox "MagicMirror frissítése folyamatban..." 8 50

cd "$MM_DIR"

git pull --rebase

rm -rf node_modules package-lock.json

NODE_OPTIONS="--max_old_space_size=512" npm install --omit=dev

### =========================================================
### KÉSZ
### =========================================================

whiptail --msgbox "✅ MagicMirror frissítve.\n\n⚠ Újraindítás ajánlott!" 10 55
