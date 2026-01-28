#!/bin/bash
set -u

# =========================================================
# MagicMirror CLIENT connection configuration
# Change server address / port without reinstall
# =========================================================

XINITRC="$HOME/.xinitrc"

ICON_OK="✅"
ICON_ERR="❌"

# ---------------------------------------------------------
# Preconditions
# ---------------------------------------------------------
if [ ! -f "$XINITRC" ]; then
  whiptail --msgbox \
"$ICON_ERR Nem található a kliens indító fájl:\n\n$XINITRC" \
10 60
  exit 1
fi

# ---------------------------------------------------------
# Read current values
# ---------------------------------------------------------
CURRENT_ADDR=$(grep -oP -- '--address\s+\K\S+' "$XINITRC" | head -n1 || true)
CURRENT_PORT=$(grep -oP -- '--port\s+\K\S+' "$XINITRC" | head -n1 || true)

if [ -z "$CURRENT_ADDR" ] || [ -z "$CURRENT_PORT" ]; then
  whiptail --msgbox \
"$ICON_ERR Nem sikerült kiolvasni az aktuális szerver beállításokat.\n\n\
(--address / --port hiányzik)" \
12 70
  exit 1
fi

# ---------------------------------------------------------
# Input dialogs
# ---------------------------------------------------------
NEW_ADDR=$(whiptail --inputbox \
"Szerver IP vagy hostname:" \
10 60 "$CURRENT_ADDR" \
3>&1 1>&2 2>&3) || exit 0

NEW_PORT=$(whiptail --inputbox \
"Szerver port (1–65535):" \
10 60 "$CURRENT_PORT" \
3>&1 1>&2 2>&3) || exit 0

# ---------------------------------------------------------
# Validation
# ---------------------------------------------------------
if [ -z "$NEW_ADDR" ]; then
  whiptail --msgbox "$ICON_ERR A szerver cím nem lehet üres." 8 50
  exit 1
fi

if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1 ] || [ "$NEW_PORT" -gt 65535 ]; then
  whiptail --msgbox "$ICON_ERR Érvénytelen port szám." 8 50
  exit 1
fi


# ---------------------------------------------------------
# Connection test BEFORE save
# ---------------------------------------------------------
TEST_SCRIPT="$HOME/mm-manager/client_connection_test.sh"

if [ -x "$TEST_SCRIPT" ]; then
  TEST_RESULT=$("$TEST_SCRIPT" "$NEW_ADDR" "$NEW_PORT")
  TEST_STATUS="${TEST_RESULT%%|*}"
  TEST_MSG="${TEST_RESULT#*|}"

  case "$TEST_STATUS" in
    FAIL)
      whiptail --msgbox \
"$ICON_ERR Kapcsolat teszt sikertelen:\n\n$TEST_MSG\n\n\
A beállítás NEM kerül mentésre." \
12 70
      exit 1
      ;;
    WARN)
      if ! whiptail --yesno \
"⚠️ Kapcsolat figyelmeztetés:\n\n$TEST_MSG\n\n\
Biztosan mented a beállítást?" \
14 70; then
        exit 0
      fi
      ;;
    OK)
      whiptail --msgbox \
"$ICON_OK Kapcsolat rendben.\n\n$TEST_MSG" \
10 60
      ;;
    *)
      whiptail --msgbox \
"⚠️ Ismeretlen teszt eredmény:\n\n$TEST_RESULT\n\n\
A mentés megszakadt." \
12 70
      exit 1
      ;;
  esac
else
  whiptail --msgbox \
"⚠️ Kapcsolat teszt script nem található:\n\n$TEST_SCRIPT\n\n\
A mentés megszakadt." \
12 70
  exit 1
fi



# ---------------------------------------------------------
# Apply changes
# ---------------------------------------------------------
sed -i \
  -e "s/--address\s\+\S\+/--address $NEW_ADDR/" \
  -e "s/--port\s\+\S\+/--port $NEW_PORT/" \
  "$XINITRC"

# ---------------------------------------------------------
# Ask for client restart (SAFE MODE)
# ---------------------------------------------------------
if whiptail --yesno \
"Szeretnéd most újraindítani a klienst?\n\n\
(A rendszer újraindul)" \
10 60
then
  whiptail --msgbox \
"$ICON_OK Beállítás mentve.\n\n\
Szerver: $NEW_ADDR\n\
Port: $NEW_PORT\n\n\
A rendszer most újraindul." \
12 60

  sudo reboot
else
  whiptail --msgbox \
"$ICON_OK Beállítás mentve.\n\n\
A módosítás a következő újraindításkor lép életbe." \
10 60
fi

exit 0
