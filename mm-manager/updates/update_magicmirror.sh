#!/bin/bash
# =========================================================
# update_magicmirror.sh
# MagicMirror Manager – MagicMirror updater
# Version: v1.4.3
# =========================================================

set -e

MM_DIR="$HOME/MagicMirror"
STATE_DIR="/var/lib/mm-manager"
ROLE=$(cat "$STATE_DIR/system_mode" 2>/dev/null || echo "unknown")

echo "=== MagicMirror frissítés ==="
echo "Rendszer mód: $ROLE"
echo

if [ ! -d "$MM_DIR/.git" ]; then
  echo "❌ MagicMirror nem található a következő helyen:"
  echo "   $MM_DIR"
  exit 1
fi

cd "$MM_DIR"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
CURRENT_COMMIT=$(git rev-parse --short HEAD)

echo "Aktuális branch : $CURRENT_BRANCH"
echo "Aktuális commit : $CURRENT_COMMIT"
echo

echo "➡ Frissítések lekérdezése (git fetch)..."
git fetch origin

LOCAL_HASH=$(git rev-parse HEAD)
REMOTE_HASH=$(git rev-parse @{u} 2>/dev/null || echo "")

if [ -n "$REMOTE_HASH" ] && [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
  echo "✅ A MagicMirror már naprakész."
  exit 0
fi

read -p "Elérhető frissítés. Szeretnéd frissíteni a MagicMirror-t? (y/N): " ANSWER

if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
  echo "⏭ MagicMirror frissítés kihagyva."
  exit 0
fi

echo
echo "➡ MagicMirror frissítése (git pull)..."
git pull --ff-only

echo
echo "➡ Node csomagok frissítése (npm install --omit=dev)..."
npm install --omit=dev

echo
echo "✅ MagicMirror frissítés kész."
echo "Új commit: $(git rev-parse --short HEAD)"

echo
echo "⚠️ AJÁNLOTT LÉPÉSEK:"
echo "- MagicMirror újraindítása"
echo "- Rendszer újraindítása"
