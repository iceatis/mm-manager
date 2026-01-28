#!/bin/bash
set -e

if [ -n "$SUDO_USER" ]; then
  RUN_USER="$SUDO_USER"
else
  RUN_USER="$(whoami)"
fi

if whiptail --yesno \
"Időzített reboot KIKAPCSOLÁSA?\n\nEz törli az automatikus újraindítást." \
10 60; then

  sudo crontab -u "$RUN_USER" -l 2>/dev/null \
    | grep -v -E "/sbin/reboot|/usr/sbin/reboot" \
    | sudo crontab -u "$RUN_USER" -

  whiptail --msgbox "🛑 Időzített reboot kikapcsolva." 8 50
fi
