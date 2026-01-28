#!/bin/bash
set -e

# =========================================================
# MagicMirror config export (v1.2.2)
# =========================================================

RUN_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$RUN_USER")

BASE_DIR="$USER_HOME/mm-manager"
BACKUP_DIR="$BASE_DIR/backups"
TS=$(date +%Y%m%d-%H%M)
OUT="$BACKUP_DIR/mm-backup-$TS.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📤 Konfiguráció export indul..."

# ---------------------------------------------------------
# USER FILES
# ---------------------------------------------------------
USER_FILES=(
  "$USER_HOME/.xinitrc"
  "$USER_HOME/MagicMirror/config/config.js"
  "$BASE_DIR/profiles"
)

# ---------------------------------------------------------
# SYSTEM FILES (root required)
# ---------------------------------------------------------
SYSTEM_FILES=(
  "/etc/systemd/system/mm-watchdog.service"
  "/etc/NetworkManager/system-connections"
)

TMP_TAR_USER=$(mktemp)
TMP_TAR_SYS=$(mktemp)

# ---------------------------------------------------------
# CREATE USER PART
# ---------------------------------------------------------
tar czf "$TMP_TAR_USER" \
  --ignore-failed-read \
  "${USER_FILES[@]}" 2>/dev/null || true

# ---------------------------------------------------------
# CREATE SYSTEM PART (sudo)
# ---------------------------------------------------------
sudo tar czf "$TMP_TAR_SYS" \
  --ignore-failed-read \
  "${SYSTEM_FILES[@]}" 2>/dev/null || true

# ---------------------------------------------------------
# MERGE ARCHIVES
# ---------------------------------------------------------
tar czf "$OUT" \
  --ignore-failed-read \
  -C / -T <(tar tzf "$TMP_TAR_USER") \
  -C / -T <(tar tzf "$TMP_TAR_SYS")

rm -f "$TMP_TAR_USER" "$TMP_TAR_SYS"

echo
echo "✅ Export kész"
echo "📦 Backup fájl:"
echo "   $OUT"
echo
read -p "Nyomj Entert a folytatáshoz..."
