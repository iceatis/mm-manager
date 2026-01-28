#!/bin/bash
set -u

# =========================================================
# System Status Overview (v1.4.4)
# =========================================================

# ---------------------------------------------------------
# USER CONTEXT
# ---------------------------------------------------------
RUN_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$RUN_USER")

# ---------------------------------------------------------
# Icon set
# ---------------------------------------------------------
ICON_OK="✅"
ICON_WARN="⚠️"
ICON_ERR="❌"

# ---------------------------------------------------------
# MagicMirror status (CLIENT + SERVER) - JAVÍTOTT
# ---------------------------------------------------------
MM_STATUS="$ICON_ERR Nem fut"

# Client mód
if pgrep -f "node clientonly" >/dev/null 2>&1; then
  MM_STATUS="$ICON_OK Fut (CLIENT)"
fi
  
# Server mód – Electron / npm start / start:x11 (JAVÍTOTT)
if pgrep -f "node --run start:x11" >/dev/null 2>&1 || \
   pgrep -f "electron js/electron.js" >/dev/null 2>&1 || \
   pgrep -f "MagicMirror/node_modules/electron" >/dev/null 2>&1 || \
   pgrep -f "npm start" >/dev/null 2>&1; then
  
  # Kiegészítés: Ellenőrizzük, hogy a 8080-as porton fut-e valami
  if ss -lnt 2>/dev/null | grep -q ":8080 "; then
    MM_STATUS="$ICON_OK Fut (SERVER)"
  else
    # Ha nem a 8080-on, próbáljunk más portokat is
    for PORT in 8080 8081 3000 80; do
      if ss -lnt 2>/dev/null | grep -Eq "[:.]$SERVER_PORT\b"; then
        MM_STATUS="$ICON_OK Fut (SERVER - port $PORT)"
        break
      fi
    done
  fi
fi

# ---------------------------------------------------------
# Watchdog status
# ---------------------------------------------------------
if systemctl list-unit-files 2>/dev/null | grep -q '^mm-watchdog.service'; then
  if systemctl is-enabled --quiet mm-watchdog 2>/dev/null; then
    if systemctl is-failed --quiet mm-watchdog 2>/dev/null; then
      WD_STATUS="$ICON_WARN Engedelyezve, hiba"
    else
      WD_STATUS="$ICON_OK Engedelyezve (systemd)"
    fi
  else
    WD_STATUS="$ICON_WARN Telepitve, nem aktiv"
  fi
else
  WD_STATUS="$ICON_ERR Nincs telepitve"
fi

# ---------------------------------------------------------
# Scheduled reboot (USER cron)
# ---------------------------------------------------------
REBOOT_STATUS="$ICON_ERR Nincs beallitva"
REBOOT_CRON=$(crontab -u "$RUN_USER" -l 2>/dev/null | grep -E "/sbin/reboot|/usr/sbin/reboot" | head -n1 || true)

if [ -n "$REBOOT_CRON" ]; then
  MIN=$(echo "$REBOOT_CRON" | awk '{print $1}')
  HOUR=$(echo "$REBOOT_CRON" | awk '{print $2}')
  REBOOT_STATUS="$ICON_OK Naponta $(printf "%02d:%02d" "$HOUR" "$MIN")"
fi

# ---------------------------------------------------------
# System metrics
# ---------------------------------------------------------
UPTIME=$(uptime -p 2>/dev/null | sed 's/^up //' || echo "-")
LOAD=$(awk '{print $1"  "$2"  "$3}' /proc/loadavg 2>/dev/null || echo "-")
DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}' || echo "-")

# ---------------------------------------------------------
# NetworkManager status
# ---------------------------------------------------------
NM_STATUS="$ICON_WARN ismeretlen"
NM_STATE="-"

if command -v nmcli >/dev/null 2>&1; then
  if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    NM_STATUS="$ICON_OK fut"
    NM_STATE_RAW=$(nmcli -t -f STATE general 2>/dev/null || true)
    case "$NM_STATE_RAW" in
      connected*)    NM_STATE="online" ;;
      connecting*)   NM_STATE="folyamatban" ;;
      disconnected*) NM_STATE="offline" ;;
      *)             NM_STATE="ismeretlen" ;;
    esac
  else
    NM_STATUS="$ICON_WARN nem fut"
  fi
fi

# ---------------------------------------------------------
# Network status (SAFE)
# ---------------------------------------------------------
NET_STATUS="$ICON_WARN nincs adat"
IP_MODE="-"
IP_ADDR="-"
GATEWAY="-"
DNS="-"
SSID=""
SIGNAL=""

if command -v nmcli >/dev/null 2>&1; then
  NET_LINE=$(nmcli -t -f NAME,DEVICE,TYPE connection show --active 2>/dev/null | head -n1 || true)

  if [ -n "$NET_LINE" ]; then
    CON_NAME=$(echo "$NET_LINE" | cut -d: -f1)
    DEVICE=$(echo "$NET_LINE" | cut -d: -f2)
    TYPE=$(echo "$NET_LINE" | cut -d: -f3)

    # determine if device is Wi-Fi hardware
	IS_WIFI_DEV=0
	if [[ "$DEVICE" == wlan* ]]; then
		IS_WIFI_DEV=1
	else
		DEV_TYPE=$(nmcli -g GENERAL.TYPE device show "$DEVICE" 2>/dev/null || true)
	[ "$DEV_TYPE" = "wifi" ] && IS_WIFI_DEV=1
	fi

	if [ "$IS_WIFI_DEV" -eq 1 ]; then
		NET_STATUS="$ICON_OK Wi-Fi ($DEVICE)"

	SSID=$(nmcli -t -f IN-USE,SSID,DEVICE dev wifi list 2>/dev/null \
		| awk -F: -v dev="$DEVICE" '$1=="*" && $3==dev {print $2}' || true)
	SSID=${SSID:-"-"}

	SIGNAL=$(nmcli -t -f IN-USE,SIGNAL,DEVICE dev wifi list 2>/dev/null \
		| awk -F: -v dev="$DEVICE" '$1=="*" && $3==dev {print $2}' || true)
	[ -n "$SIGNAL" ] && SIGNAL="${SIGNAL}%"
	else
	NET_STATUS="$ICON_OK Ethernet ($DEVICE)"
	fi

    IPV4_METHOD=$(nmcli -g ipv4.method connection show "$CON_NAME" 2>/dev/null || true)
    [ "$IPV4_METHOD" = "auto" ] && IP_MODE="DHCP"
    [ "$IPV4_METHOD" = "manual" ] && IP_MODE="Statikus"

    IP_ADDR=$(nmcli -g IP4.ADDRESS connection show "$CON_NAME" 2>/dev/null | head -n1 | cut -d/ -f1)
    GATEWAY=$(nmcli -g IP4.GATEWAY connection show "$CON_NAME" 2>/dev/null)
    DNS=$(nmcli -g IP4.DNS connection show "$CON_NAME" 2>/dev/null | paste -sd ", ")

    IP_ADDR=${IP_ADDR:-"-"}
    GATEWAY=${GATEWAY:-"-"}
    DNS=${DNS:-"-"}
  fi
fi

# ---------------------------------------------------------
# Network warnings (DNS / Gateway)
# ---------------------------------------------------------
NET_WARN=""

if [ "$NET_STATUS" != "$ICON_ERR Nincs adat" ]; then
  if [ -z "$GATEWAY" ] || [ "$GATEWAY" = "-" ]; then
    NET_WARN="$ICON_WARN Hianyzo gateway"
  fi

  if [ -z "$DNS" ] || [ "$DNS" = "-" ]; then
    if [ -n "$NET_WARN" ]; then
      NET_WARN="$NET_WARN, DNS"
    else
      NET_WARN="$ICON_WARN Hianyzo DNS"
    fi
  fi
fi

# ---------------------------------------------------------
# Network Watchdog status (READ ONLY)
# ---------------------------------------------------------
NET_WD_STATUS="$ICON_OK rendben"
NET_WARN_COUNT=0
NET_FAIL_COUNT=0

[ -f /run/mm-watchdog.netwarn ] && NET_WARN_COUNT=$(cat /run/mm-watchdog.netwarn)
[ -f /run/mm-watchdog.netfail ] && NET_FAIL_COUNT=$(cat /run/mm-watchdog.netfail)

if [ "$NET_FAIL_COUNT" -gt 0 ]; then
  NET_WD_STATUS="$ICON_ERR FAIL ($NET_FAIL_COUNT)"
elif [ "$NET_WARN_COUNT" -gt 0 ]; then
  NET_WD_STATUS="$ICON_WARN WARN ($NET_WARN_COUNT)"
fi

# ---------------------------------------------------------
# Client -> Server connection (READ ONLY)
# ---------------------------------------------------------
SERVER_ADDR="-"
SERVER_PORT="-"

# Server mód – port olvasása config.js-ből
MM_CONFIG="$USER_HOME/MagicMirror/config/config.js"
if [ -f "$MM_CONFIG" ]; then
  PORT_CFG=$(grep -E "port\s*:" "$MM_CONFIG" | grep -o '[0-9]\+' | head -n1)
  [ -n "$PORT_CFG" ] && SERVER_PORT="$PORT_CFG"
fi

#Client mód - port olvasása .xinitrc-ből
XINITRC="$USER_HOME/.xinitrc"

if [ -f "$XINITRC" ]; then
  SERVER_ADDR_TMP=$(grep -oP -- '--address\s+\K\S+' "$XINITRC" | head -n1 || true)
  SERVER_PORT_TMP=$(grep -oP -- '--port\s+\K\S+' "$XINITRC" | head -n1 || true)

  [ -n "$SERVER_ADDR_TMP" ] && SERVER_ADDR="$SERVER_ADDR_TMP"
  [ -n "$SERVER_PORT_TMP" ] && SERVER_PORT="$SERVER_PORT_TMP"
fi

# ---------------------------------------------------------
# Backup status (60 napos szabaly)
# ---------------------------------------------------------
BACKUP_STATUS="$ICON_ERR Nincs backup"
BACKUP_DIR="$USER_HOME/mm-manager/backups"
LAST_BACKUP=$(ls -1 "$BACKUP_DIR"/mm-backup-*.tar.gz 2>/dev/null | tail -n1 || true)

if [ -n "$LAST_BACKUP" ]; then
  NOW_TS=$(date +%s)
  BACKUP_TS=$(stat -c '%Y' "$LAST_BACKUP")
  AGE_DAYS=$(( (NOW_TS - BACKUP_TS) / 86400 ))

  if [ "$AGE_DAYS" -gt 60 ]; then
    BACKUP_STATUS="$ICON_WARN $AGE_DAYS napos (ELAVULT)"
  else
    BACKUP_TIME=$(stat -c '%y' "$LAST_BACKUP" | cut -d'.' -f1)
    BACKUP_STATUS="$ICON_OK $BACKUP_TIME ($AGE_DAYS nap)"
  fi
fi

# ---------------------------------------------------------
# Server connection status (display only)
# ---------------------------------------------------------
if [ "$SERVER_ADDR" != "-" ] && [ "$SERVER_PORT" != "-" ]; then
  if [ -x "$USER_HOME/mm-manager/client_connection_status.sh" ]; then
    CONN_STATUS=$(
      "$USER_HOME/mm-manager/client_connection_status.sh" \
      "$SERVER_ADDR" "$SERVER_PORT"
    )
  else
    CONN_STATUS="  ⚠️ Kapcsolat teszt script nem elérhető"
  fi
else
  CONN_STATUS="  ⏳ Szerver nincs beállítva"
fi

# ---------------------------------------------------------
# Status sections (VIEW LAYERS) - JAVÍTOTT
# ---------------------------------------------------------

# ---------------------------------------------------------
# Web UI status (SERVER) - JAVÍTOTT
# ---------------------------------------------------------
WEB_UI_STATUS="$ICON_ERR NEM elerheto"

# PORT ellenőrzés javítva
if [ "$SERVER_PORT" != "-" ]; then
  if ss -lnt 2>/dev/null | grep -q ":$SERVER_PORT "; then
    WEB_UI_STATUS="$ICON_OK Fut ($SERVER_PORT)"
  fi
elif ss -lnt 2>/dev/null | grep -q ":8080 "; then
  # Ha nincs beállítva SERVER_PORT, de a 8080-on fut valami
  WEB_UI_STATUS="$ICON_OK Fut (8080 - alapértelmezett)"
  SERVER_PORT="8080"
fi

# Server IP cím hozzáadása (csak megjelenítéshez)
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "-")

SECTION_MM="
MagicMirror:
  $MM_STATUS

Web UI:
  $WEB_UI_STATUS
"

# Ha server módban vagyunk, mutassuk az IP-t is
if [[ "$MM_STATUS" == *"SERVER"* ]]; then
  SECTION_MM+="
Server IP:
  $SERVER_IP
  Port: $SERVER_PORT
"
else
  # Client módban a szerver kapcsolat adatai
  SECTION_MM+="
MagicMirror szerver kapcsolat:
  Cim:           $SERVER_ADDR
  Port:          $SERVER_PORT
"
fi

SECTION_WATCHDOG="
Watchdog:
  $WD_STATUS

Network watchdog:
  $NET_WD_STATUS
"

SECTION_NETWORK="
NetworkManager:
  $NM_STATUS
  Allapot: $NM_STATE

Halozat:
  $NET_STATUS
$( [ -n "$SSID" ] && echo "  SSID:          $SSID" )
$( [ -n "$SIGNAL" ] && echo "  Jel erosseg:   $SIGNAL" )
  IP mod:        $IP_MODE
  IP cim:        $IP_ADDR
  Gateway:       $GATEWAY
  DNS:           $DNS
Szerver kapcsolat:
$CONN_STATUS  
"

SECTION_SYSTEM="
Uptime:
  $UPTIME

Load average (1 / 5 / 15):
  $LOAD

Rendszer lemez:
  $DISK
"

# ---------------------------------------------------------
# Message
# ---------------------------------------------------------

VIEW=$(whiptail --title "Rendszer allapot – nezet" \
  --checklist "Valaszd ki a megjelenitendo szekciokat:" \
  18 72 6 \
  "mm"       "MagicMirror"        ON \
  "network"  "Hálózat"            ON \
  "watchdog" "Watchdog"           ON \
  "system"   "Rendszer"           ON \
  3>&1 1>&2 2>&3)

[ $? -ne 0 ] && exit 0

MSG="⬇⬇⬇  Görgethető statusz (↑ ↓)  ⬇⬇⬇

"

if [[ "$VIEW" == *"mm"* ]]; then
  MSG+="$SECTION_MM
----------------------------------------
"
fi

if [[ "$VIEW" == *"network"* ]]; then
  MSG+="$SECTION_NETWORK
----------------------------------------
"
fi

if [[ "$VIEW" == *"watchdog"* ]]; then
  MSG+="$SECTION_WATCHDOG
----------------------------------------
"
fi

if [[ "$VIEW" == *"system"* ]]; then
  MSG+="$SECTION_SYSTEM
"
fi

# ---------------------------------------------------------
# WHIPTAIL (dynamic size)
# ---------------------------------------------------------
export TERM="${TERM:-linux}"

LINES=$(printf "%s\n" "$MSG" | wc -l)
HEIGHT=$((LINES + 6))

# whiptail max height védelem
[ "$HEIGHT" -gt 30 ] && HEIGHT=30

whiptail --title "Rendszer állapot – v1.4.4" \
  --scrolltext \
  --msgbox "$MSG" "$HEIGHT" 82