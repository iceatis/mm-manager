#!/bin/bash
set -u

# =========================================================
# SERVER PREFLIGHT CHECK – MagicMirror
# Role-aware, install-safe
# v1.4.0
# =========================================================

MODE="${1:-soft}"   # soft | hard
ERRORS=()
WARNS=()

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------
fail() { ERRORS+=("$1"); }
warn() { WARNS+=("$1"); }

# ---------------------------------------------------------
# Context (explicit)
# ---------------------------------------------------------
ROLE="${INSTALL_TARGET:-server}"

# ---------------------------------------------------------
# OS CHECK
# ---------------------------------------------------------
grep -qi bookworm /etc/os-release \
  || fail "Nem Bookworm alapú OS (kötelező)"

# ---------------------------------------------------------
# RAM CHECK (server higher minimum)
# ---------------------------------------------------------
MEM=$(free -m | awk '/Mem:/ {print $2}')
MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "unknown")

MIN_RAM=500

if echo "$MODEL" | grep -qi "Zero 2"; then
  MIN_RAM=384
fi

[ "$MEM" -lt "$MIN_RAM" ] && \
  fail "Kevés RAM (${MEM}MB, min. ${MIN_RAM}MB)"

# ---------------------------------------------------------
# DISK CHECK
# ---------------------------------------------------------
DISK=$(df / | awk 'NR==2 {print $4}')
[ "$DISK" -lt 1200000 ] && fail "Kevés szabad lemez (<1.2GB)"

# ---------------------------------------------------------
# NETWORK MANAGER
# ---------------------------------------------------------
systemctl is-active --quiet NetworkManager \
  || fail "NetworkManager nem fut"

# ---------------------------------------------------------
# INTERNET / DNS (WARN only)
# ---------------------------------------------------------
ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 \
  || warn "Nincs internet kapcsolat"

getent hosts github.com >/dev/null 2>&1 \
  || warn "DNS feloldás nem működik"

# ---------------------------------------------------------
# NODE / NPM
# ---------------------------------------------------------
command -v node >/dev/null 2>&1 || warn "Node.js még nincs telepítve"
command -v npm  >/dev/null 2>&1 || warn "npm még nincs telepítve"  || fail "Node.js nem érhető el"

# ---------------------------------------------------------
# MAGICMIRROR DIR
# ---------------------------------------------------------
[ -d "$HOME/MagicMirror" ] \
  || warn "MagicMirror könyvtár még nem létezik (telepítés hozza létre)"

# ---------------------------------------------------------
# DISPLAY / XORG
# ---------------------------------------------------------
if [ -z "${DISPLAY:-}" ]; then
  warn "DISPLAY nem aktív (első boot előtt normális lehet)"
fi

if ! command -v Xorg >/dev/null 2>&1; then
  warn "Xorg bináris nem található (Wayland tiltása ajánlott)"
fi

# ---------------------------------------------------------
# AUTOLOGIN (WARN)
# ---------------------------------------------------------
if [ ! -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
  warn "Autologin nincs engedélyezve (szerver kiosknál ajánlott)"
fi

# ---------------------------------------------------------
# WATCHDOG (WARN)
# ---------------------------------------------------------
if ! systemctl list-unit-files 2>/dev/null | grep -q '^mm-watchdog.service'; then
  warn "Watchdog még nincs telepítve"
fi

# ---------------------------------------------------------
# RESULT BUILD
# ---------------------------------------------------------
MSG=""

if [ "${#ERRORS[@]}" -gt 0 ]; then
  MSG+="❌ KRITIKUS HIBÁK (SERVER):\n\n"
  for e in "${ERRORS[@]}"; do
    MSG+="• $e\n"
  done
fi

if [ "${#WARNS[@]}" -gt 0 ]; then
  MSG+="\n⚠️ FIGYELMEZTETÉSEK:\n\n"
  for w in "${WARNS[@]}"; do
    MSG+="• $w\n"
  done
fi

# ---------------------------------------------------------
# OUTPUT
# ---------------------------------------------------------
export TERM="${TERM:-linux}"

if [ "${#ERRORS[@]}" -gt 0 ]; then
  whiptail --msgbox "$MSG" 20 78
  [ "$MODE" = "hard" ] && exit 1
  exit 0
fi

if [ "${#WARNS[@]}" -gt 0 ]; then
  whiptail --msgbox "$MSG\n\nA telepítés ennek ellenére folytatható." 20 78
  exit 0
fi

whiptail --msgbox \
"✅ Server preflight ellenőrzés sikeres.\n\nA rendszer alkalmas a MagicMirror Szerver telepítésére." \
10 60
