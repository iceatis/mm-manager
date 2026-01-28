#!/bin/bash
set -u

MODE="${1:-soft}"   # soft | hard
ERRORS=()

# RAM
MEM=$(free -m | awk '/Mem:/ {print $2}')
[ "$MEM" -lt 350 ] && ERRORS+=("Kevés RAM (${MEM}MB)")

# Disk
DISK=$(df / | awk 'NR==2 {print $4}')
[ "$DISK" -lt 800000 ] && ERRORS+=("Kevés szabad lemez (<800MB)")

# Internet
ping -c1 -W2 8.8.8.8 >/dev/null || ERRORS+=("Nincs internet kapcsolat")

# DNS
getent hosts github.com >/dev/null || ERRORS+=("DNS nem működik")

# OS
grep -qi bookworm /etc/os-release || ERRORS+=("Nem Bookworm OS")

if [ "${#ERRORS[@]}" -ne 0 ]; then
  MSG="⚠️ Preflight figyelmeztetes:\n\n"
  for e in "${ERRORS[@]}"; do
    MSG+="• $e\n"
  done

  MSG+="\nA telepites ennek ellenere folytathato."

  export TERM="${TERM:-linux}"
  whiptail --msgbox "$MSG" 18 75

  [ "$MODE" = "hard" ] && exit 1
  exit 0
fi

whiptail --msgbox "✅ Preflight ellenorzes rendben.\nA rendszer alkalmas a telepitesre." 10 60

