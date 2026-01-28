#!/bin/bash
# =========================================================
# update_npm.sh
# MagicMirror Manager – npm updater
# Version: v1.4.3
# =========================================================

set -e

STATE_DIR="/var/lib/mm-manager"
ROLE=$(cat "$STATE_DIR/system_mode" 2>/dev/null || echo "unknown")

if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm nincs telepítve!"
  exit 1
fi

CURRENT_NPM=$(npm -v)
LATEST_NPM=$(npm view npm version 2>/dev/null || echo "unknown")

echo "=== npm frissítés ==="
echo "Rendszer mód: $ROLE"
echo
echo "Jelenlegi npm verzió : $CURRENT_NPM"
echo "Elérhető legfrissebb : $LATEST_NPM"
echo

if [ "$LATEST_NPM" = "unknown" ]; then
  echo "❌ Nem sikerült lekérdezni a legfrissebb npm verziót."
  exit 1
fi

if [ "$CURRENT_NPM" = "$LATEST_NPM" ]; then
  echo "✅ Az npm már naprakész."
  exit 0
fi

read -p "Szeretnéd frissíteni az npm-et erre a verzióra: $LATEST_NPM ? (y/N): " ANSWER

if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
  echo "⏭ npm frissítés kihagyva."
  exit 0
fi

echo
echo "➡ npm frissítése folyamatban..."
sudo npm install -g "npm@$LATEST_NPM"

echo
echo "✅ npm frissítés kész."
echo "Új verzió: $(npm -v)"
