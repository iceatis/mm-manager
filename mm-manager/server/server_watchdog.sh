#!/bin/bash

# =========================================================
# SERVER WATCHDOG – MagicMirror (local / standalone)
# Policy-based, reboot-last
# v1.4.4
# =========================================================

LOG_TAG="MM-SERVER-WATCHDOG"

# ---------------------------------------------------------
# Resolve user & display (systemd-safe)
# ---------------------------------------------------------
RUN_USER="$(systemctl show -p User --value mm-watchdog.service 2>/dev/null)"
[ -z "$RUN_USER" ] && RUN_USER="root"

USER_HOME="$(eval echo "~$RUN_USER")"

export DISPLAY=":0"
export XAUTHORITY="$USER_HOME/.Xauthority"

# ---------------------------------------------------------
# BOOT GRACE PERIOD (protect boot)
# ---------------------------------------------------------
BOOT_TIME=$(cut -d. -f1 /proc/uptime)

if [ "$BOOT_TIME" -lt 240 ]; then
  logger -t "$LOG_TAG" "Boot grace active (${BOOT_TIME}s) – waiting 120s"
  sleep 120
fi

# ---------------------------------------------------------
# STATE
# ---------------------------------------------------------
STATE_FILE="/run/mm-server-watchdog.failcount"
MAX_FAILS=3

# ---------------------------------------------------------
# NETWORK WATCHDOG (optional, server-aware)
# ---------------------------------------------------------
NETWORK_CHECK="$USER_HOME/mm-manager/server/server_network_watchdog_check.sh"
NET_WARN_FILE="/run/mm-server-watchdog.netwarn"
NET_FAIL_FILE="/run/mm-server-watchdog.netfail"

# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------
log() { logger -t "$LOG_TAG" "$1"; }

get_count() { [ -f "$1" ] && cat "$1" || echo 0; }
set_count() { echo "$2" > "$1"; }
reset_count() { rm -f "$1"; }

is_x_running() { pgrep -x Xorg >/dev/null; }

# ---------------------------------------------------------
# MagicMirror PORT – DYNAMIC RESOLUTION (FIX)
# ---------------------------------------------------------
MM_CONFIG="$USER_HOME/MagicMirror/config/config.js"

get_mm_port() {
  if [ -f "$MM_CONFIG" ]; then
    grep -E 'port:' "$MM_CONFIG" | grep -o '[0-9]\+' | head -n1
  fi
}

MM_PORT="$(get_mm_port)"
[ -z "$MM_PORT" ] && MM_PORT=8080

log "MagicMirror port: $MM_PORT"

is_mm_running() {
  curl -sf "http://localhost:$MM_PORT" >/dev/null
}

# =========================================================
# WATCHDOG LOOP
# =========================================================
while true; do

  # -------------------------------------------------------
  # NETWORK CHECK (SAFE)
  # -------------------------------------------------------
  if [ -x "$NETWORK_CHECK" ]; then
    NET_RESULT="$("$NETWORK_CHECK" 2>/dev/null || true)"

    if echo "$NET_RESULT" | grep -q '|'; then
      NET_STATUS="${NET_RESULT%%|*}"
      NET_REASON="${NET_RESULT#*|}"
    else
      NET_STATUS="UNKNOWN"
      NET_REASON="invalid output"
    fi

    case "$NET_STATUS" in
      OK)
        reset_count "$NET_WARN_FILE"
        reset_count "$NET_FAIL_FILE"
        ;;
      WARN)
        WC=$(get_count "$NET_WARN_FILE")
        WC=$((WC + 1))
        set_count "$NET_WARN_FILE" "$WC"
        log "NETWORK WARN ($WC): $NET_REASON"
        ;;
      FAIL)
        FC=$(get_count "$NET_FAIL_FILE")
        FC=$((FC + 1))
        set_count "$NET_FAIL_FILE" "$FC"
        log "NETWORK FAIL ($FC): $NET_REASON"
        ;;
      *)
        log "NETWORK UNKNOWN: $NET_RESULT"
        ;;
    esac
  fi

  # -------------------------------------------------------
  # MAIN CHECK
  # -------------------------------------------------------
  FAILS=$(get_count "$STATE_FILE")

  if is_mm_running; then
    reset_count "$STATE_FILE"
    log "OK – MagicMirror fut"
    sleep 10
    continue
  fi

  FAILS=$((FAILS + 1))
  set_count "$STATE_FILE" "$FAILS"
  log "Hiba észlelve (fail $FAILS/$MAX_FAILS)"

  if [ "$FAILS" -lt "$MAX_FAILS" ]; then
    sleep 10
    continue
  fi

  # -------------------------------------------------------
  # FINAL RECOVERY
  # -------------------------------------------------------
  log "Max hiba elérve – rendszer reboot"
  rm -f "$STATE_FILE"
  sleep 2
  systemctl reboot
  exit 0
done
