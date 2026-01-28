#!/bin/bash
# =========================================================
# view_logs.sh
# MagicMirror Manager – View system logs
# Version: v1.4.4
# =========================================================

set -e

echo "=== Journald log állapot ==="
echo

# storage mode
STORAGE=$(grep '^Storage=' /etc/systemd/journald.conf | cut -d= -f2)
[ -z "$STORAGE" ] && STORAGE="volatile (default)"

echo "Log tárolás módja: $STORAGE"
echo

echo "=== Elérhető boot logok ==="
journalctl --list-boots
echo

echo "=== Előző boot (gyakran OOM / crash itt van) ==="
journalctl -b -1 --no-pager | tail -200
