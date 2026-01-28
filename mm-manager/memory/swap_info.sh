#!/bin/bash
# =========================================================
# swap_info.sh
# MagicMirror Manager – Swap status information
# Version: v1.4.4
# =========================================================

set -e

echo "=== Swap információ ==="
echo

echo "--- dphys-swapfile beállítás ---"
# grep exit 1 is NOT an error here
grep '^CONF_SWAPSIZE=' /etc/dphys-swapfile 2>/dev/null || true
if ! grep -q '^CONF_SWAPSIZE=' /etc/dphys-swapfile 2>/dev/null; then
  echo "CONF_SWAPSIZE nincs beállítva"
fi
echo

echo "--- Aktív swap eszközök ---"
# swapon --show may exit 1 → allowed
if ! swapon --show 2>/dev/null; then
  echo "Nincs aktív swap"
fi
echo

echo "--- Memória állapot ---"
free -h || true
