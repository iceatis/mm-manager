#!/bin/bash
# =========================================================
# increase_swap_1024.sh
# MagicMirror Manager – Increase swap to 1024MB
# Version: v1.4.4
# =========================================================

set -e

echo "=== Swap méret növelése 1024 MB-ra ==="
echo

CURRENT_SWAP=$(grep '^CONF_SWAPSIZE=' /etc/dphys-swapfile | cut -d= -f2)

echo "Jelenlegi swap méret: ${CURRENT_SWAP:-ismeretlen} MB"
echo

if [ "$CURRENT_SWAP" = "1024" ]; then
  echo "✅ A swap már 1024 MB-ra van állítva."
  exit 0
fi

echo "→ Swap kikapcsolása"
sudo dphys-swapfile swapoff || true

echo "→ Swap méret beállítása 1024 MB-ra"
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile

echo "→ Swap fájl újragenerálása"
sudo dphys-swapfile setup

echo "→ Swap bekapcsolása"
sudo dphys-swapfile swapon

echo
echo "✅ Swap sikeresen 1024 MB-ra növelve."
echo
free -h
