#!/bin/bash
set -e

# =========================================================
# Scheduled Reboot Installer (USER CRON, HH:MM)
# =========================================================

# --- determine real user ---
if [ -n "$SUDO_USER" ]; then
  RUN_USER="$SUDO_USER"
else
  RUN_USER="$(whoami)"
fi

TIME=$(whiptail --inputbox \
"Add meg az automatikus újraindítás időpontját (HH:MM)\n\nPélda: 04:00" \
10 60 "04:00" 3>&1 1>&2 2>&3) || exit 0

# ---- Validate format ----
if ! [[ "$TIME" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
  whiptail --msgbox "❌ Hibás időformátum!\nHasználd: HH:MM (pl. 04:00)" 10 60
  exit 1
fi

HOUR="${TIME%:*}"
MIN="${TIME#*:}"

# ---- Update USER crontab explicitly ----
sudo crontab -u "$RUN_USER" -l 2>/dev/null \
  | grep -v -E "/sbin/reboot|/usr/sbin/reboot" \
  | sudo crontab -u "$RUN_USER" -

echo "$MIN $HOUR * * * /sbin/reboot" \
  | sudo crontab -u "$RUN_USER" -

whiptail --msgbox \
"✔ Automatikus újraindítás beállítva:\n\n⏰ Minden nap $TIME\n\n⚠️ A módosítások újraindítás után lépnek életbe." \
12 70
