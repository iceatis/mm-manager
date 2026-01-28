#!/bin/bash
# =========================================================
# enable_persistent_logs.sh
# MagicMirror Manager – Enable persistent journald logs
# Version: v1.4.4
# =========================================================

set -e

echo "=== Persistent journald log bekapcsolása ==="
echo

JOURNALD_CONF="/etc/systemd/journald.conf"

# ---------------------------------------------------------
# 1. Ensure persistent journal directory exists
# ---------------------------------------------------------
if [ ! -d /var/log/journal ]; then
  echo "→ /var/log/journal létrehozása"
  sudo mkdir -p /var/log/journal
else
  echo "→ /var/log/journal már létezik"
fi

# ---------------------------------------------------------
# 2. Ensure Storage=persistent is set correctly
# ---------------------------------------------------------
if grep -q '^Storage=persistent' "$JOURNALD_CONF"; then
  echo "→ journald már persistent módban van"
else
  echo "→ journald átállítása persistent módra"

  if grep -q '^Storage=' "$JOURNALD_CONF"; then
    # Storage sor létezik, de nem persistent
    sudo sed -i 's/^Storage=.*/Storage=persistent/' "$JOURNALD_CONF"
  elif grep -q '^#Storage=' "$JOURNALD_CONF"; then
    # Kommentelt Storage sor létezik
    sudo sed -i 's/^#Storage=.*/Storage=persistent/' "$JOURNALD_CONF"
  else
    # Storage sor egyáltalán nem létezik
    echo "Storage=persistent" | sudo tee -a "$JOURNALD_CONF" >/dev/null
  fi
fi

# ---------------------------------------------------------
# 3. Restart journald
# ---------------------------------------------------------
echo "→ systemd-journald újraindítása"
sudo systemctl restart systemd-journald

echo
echo "✅ Perzisztens logolás AKTÍV"
echo

# ---------------------------------------------------------
# 4. Verification info
# ---------------------------------------------------------
echo "Aktuális journald Storage beállítás:"
grep '^Storage=' "$JOURNALD_CONF" || echo "⚠️ Storage beállítás nem található"

echo
echo "Megjegyzés:"
echo "A perzisztens logok teljes működéséhez egy REBOOT szükséges."
