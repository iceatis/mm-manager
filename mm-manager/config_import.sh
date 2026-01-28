#!/bin/bash
set -e

# =========================================================
# MagicMirror config import (v1.2.2)
# =========================================================

BASE_DIR="$HOME/mm-manager"
BACKUP_DIR="$BASE_DIR/backups"

# ---------------------------------------------------------
# PICK ARCHIVE
# ---------------------------------------------------------
ARCHIVE=$(ls -1 "$BACKUP_DIR"/mm-backup-*.tar.gz 2>/dev/null | tail -n1)

if [ -z "$ARCHIVE" ]; then
  echo "❌ Nem található backup fájl a következő helyen:"
  echo "   $BACKUP_DIR"
  exit 1
fi

# ---------------------------------------------------------
# CONFIRMATION
# ---------------------------------------------------------
if ! whiptail --yesno \
"⚠️ Konfiguráció import\n\nEz felülírhat meglévő beállításokat.\n\nForrás:\n$ARCHIVE\n\nFolytatod?" \
14 70; then
  exit 0
fi

echo "📥 Import indul..."

# ---------------------------------------------------------
# EXTRACT
# ---------------------------------------------------------
sudo tar xzf "$ARCHIVE" -C /

# ---------------------------------------------------------
# POST ACTIONS
# ---------------------------------------------------------
sudo systemctl daemon-reload

if systemctl list-unit-files | grep -q '^mm-watchdog.service'; then
  sudo systemctl restart mm-watchdog || true
fi

sudo systemctl restart NetworkManager || true

echo
echo "✅ Import befejezve"
echo
echo "ℹ️ Javasolt lépések:"
echo " - ellenőrizd a hálózatot"
echo " - MagicMirror újraindítása (ha fut)"
echo " - reboot külön menüpontból"
echo
read -p "Nyomj Entert a kilépéshez..."
