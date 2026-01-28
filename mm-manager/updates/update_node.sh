#!/bin/bash
# =========================================================
# update_node.sh
# MagicMirror Manager – Node.js updater (NVM)
# Version: v1.4.3
# =========================================================

set -e

STATE_DIR="/var/lib/mm-manager"
ROLE=$(cat "$STATE_DIR/system_mode" 2>/dev/null || echo "unknown")

# ---------------------------------------------------------
# LOAD NVM
# ---------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
else
  echo "❌ NVM nem található ($NVM_DIR/nvm.sh)"
  exit 1
fi

# ---------------------------------------------------------
# CURRENT & LATEST LTS
# ---------------------------------------------------------
CURRENT_NODE="not installed"
LATEST_LTS="unknown"

if command -v node >/dev/null 2>&1; then
  CURRENT_NODE=$(node -v | sed 's/^v//')
fi

LATEST_LTS=$(nvm ls-remote --lts | tail -1 | awk '{print $1}' | sed 's/^v//')

echo "=== Node.js frissítés ==="
echo "Rendszer mód: $ROLE"
echo
echo "Jelenlegi Node verzió : $CURRENT_NODE"
echo "Legfrissebb LTS       : $LATEST_LTS"
echo

if [ "$LATEST_LTS" = "unknown" ]; then
  echo "❌ Nem sikerült lekérdezni az LTS verziót."
  exit 1
fi

if [ "$CURRENT_NODE" = "$LATEST_LTS" ]; then
  echo "✅ A Node.js már naprakész (LTS)."
  exit 0
fi

# ---------------------------------------------------------
# CONFIRMATION
# ---------------------------------------------------------
read -p "Szeretnéd frissíteni a Node.js-t erre az LTS verzióra: $LATEST_LTS ? (y/N): " ANSWER

if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
  echo "⏭ Node.js frissítés kihagyva."
  exit 0
fi

# ---------------------------------------------------------
# INSTALL & USE
# ---------------------------------------------------------
echo
echo "➡ Node.js $LATEST_LTS telepítése NVM-mel..."
nvm install "$LATEST_LTS"

echo
echo "➡ Node.js $LATEST_LTS aktiválása..."
nvm use "$LATEST_LTS"

echo
echo "✅ Node.js frissítés kész."
echo "Aktív verzió: $(node -v)"

# ---------------------------------------------------------
# POST INFO
# ---------------------------------------------------------
echo
echo "⚠️ FONTOS:"
echo "- MagicMirror újraépítése AJÁNLOTT (npm install)"
echo "- Rendszer újraindítás AJÁNLOTT"
