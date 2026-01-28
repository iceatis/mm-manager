#!/bin/bash

LOG_TAG="MM-WATCHDOG"

# ---------------------------------------------------------
# USER / HOME – SYSTEMD SAFE
# ---------------------------------------------------------
RUN_USER="$(systemctl show -p User --value mm-watchdog.service)"
[ -z "$RUN_USER" ] && RUN_USER="root"
USER_HOME="$(eval echo "~$RUN_USER")"

DISPLAY=":0"
export DISPLAY
export XAUTHORITY="$USER_HOME/.Xauthority"

# ---------------------------------------------------------
# STARTUP GRACE PERIOD (BOOT PROTECTION)  ✅ NEW
# ---------------------------------------------------------
BOOT_TIME=$(cut -d. -f1 /proc/uptime)

if [ "$BOOT_TIME" -lt 120 ]; then
  logger -t "$LOG_TAG" "Boot grace period active (${BOOT_TIME}s) – waiting 60s"
  sleep 60
fi

# ---------------------------------------------------------
# STATE
# ---------------------------------------------------------
STATE_FILE="/run/mm-watchdog.failcount"
MAX_FAILS=3

# ---------------------------------------------------------
# NETWORK WATCHDOG (OPTIONAL!)
# ---------------------------------------------------------
NETWORK_CHECK_SCRIPT="$USER_HOME/mm-manager/network_watchdog_check.sh"
NET_WARN_FILE="/run/mm-watchdog.netwarn"
NET_FAIL_FILE="/run/mm-watchdog.netfail"

# ---------------------------------------------------------
# HELPERS
# ---------------------------------------------------------
log() { logger -t "$LOG_TAG" "$1"; }
get_count() { [ -f "$1" ] && cat "$1" || echo 0; }
set_count() { echo "$2" > "$1"; }
reset_count() { rm -f "$1"; }

is_x_running() { pgrep -x Xorg >/dev/null; }
is_mm_running() { pgrep -f "node clientonly" >/dev/null; }

# =========================================================
# WATCHDOG LOOP
# =========================================================
while true; do

  # -------------------------------------------------------
  # NETWORK CHECK (SAFE)
  # -------------------------------------------------------
  if [ -x "$NETWORK_CHECK_SCRIPT" ]; then
    NET_RESULT="$("$NETWORK_CHECK_SCRIPT" 2>/dev/null || true)"

    if echo "$NET_RESULT" | grep -q '|'; then
      NET_STATUS="${NET_RESULT%%|*}"
      NET_REASON="${NET_RESULT#*|}"
    else
      NET_STATUS="UNKNOWN"
      NET_REASON="Invalid network watchdog output"
    fi

    case "$NET_STATUS" in
      OK)
        reset_count "$NET_WARN_FILE"
        reset_count "$NET_FAIL_FILE"
        ;;
      WARN)
        WARN_COUNT=$(get_count "$NET_WARN_FILE")
        WARN_COUNT=$((WARN_COUNT + 1))
        set_count "$NET_WARN_FILE" "$WARN_COUNT"
        log "NETWORK WARN ($WARN_COUNT): $NET_REASON"
        ;;
      FAIL)
        FAIL_COUNT=$(get_count "$NET_FAIL_FILE")
        FAIL_COUNT=$((FAIL_COUNT + 1))
        set_count "$NET_FAIL_FILE" "$FAIL_COUNT"
        log "NETWORK FAIL ($FAIL_COUNT): $NET_REASON"
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

  if is_x_running && is_mm_running; then
    reset_count "$STATE_FILE"
    log "OK – X és MagicMirror fut"
    sleep 10
    continue
  fi

  FAILS=$((FAILS + 1))
  set_count "$STATE_FILE" "$FAILS"
  log "Hiba észlelve (fail count: $FAILS)"

  # -------------------------------------------------------
  # FAIL HANDLING – NO X KILL IN EARLY STAGE  ✅ MODIFIED
  # -------------------------------------------------------
  if [ "$FAILS" -lt "$MAX_FAILS" ]; then
    log "Hiba észlelve (kísérlet $FAILS/$MAX_FAILS) – várakozás"
    sleep 10
    continue
  fi

  # -------------------------------------------------------
  # FINAL RECOVERY
  # -------------------------------------------------------
  log "Max hiba elérve – teljes reboot"
  rm -f "$STATE_FILE"
  sleep 2
  systemctl reboot
  exit 0
done
