#!/bin/bash
set -u

# =========================================================
# Network Watchdog Check
# Read-only network health evaluation
# Returns: OK | WARN | FAIL
# =========================================================

STATUS="OK"
REASON="network healthy"

# ---------------------------------------------------------
# Helper: downgrade status (OK -> WARN -> FAIL)
# ---------------------------------------------------------
set_warn() {
  [ "$STATUS" = "OK" ] && STATUS="WARN" && REASON="$1"
}

set_fail() {
  STATUS="FAIL"
  REASON="$1"
}

# ---------------------------------------------------------
# 1. NetworkManager running?
# ---------------------------------------------------------
if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
  set_fail "NetworkManager not running"
fi

# ---------------------------------------------------------
# 2. Active connection?
# ---------------------------------------------------------
ACTIVE_DEVICE=""
if [ "$STATUS" != "FAIL" ]; then
  ACTIVE_DEVICE=$(nmcli -t -f DEVICE connection show --active 2>/dev/null | head -n1 || true)
  [ -z "$ACTIVE_DEVICE" ] && set_fail "no active network connection"
fi

# ---------------------------------------------------------
# 3. IPv4 address present?
# ---------------------------------------------------------
if [ "$STATUS" != "FAIL" ]; then
  IP_ADDR=$(ip -4 addr show "$ACTIVE_DEVICE" 2>/dev/null \
    | awk '/inet / {print $2}' | head -n1 || true)
  [ -z "$IP_ADDR" ] && set_warn "no IPv4 address"
fi

# ---------------------------------------------------------
# 4. Default gateway present?
# ---------------------------------------------------------
if [ "$STATUS" != "FAIL" ]; then
  GW=$(ip route 2>/dev/null | awk '/default/ {print $3}' | head -n1 || true)
  [ -z "$GW" ] && set_warn "no default gateway"
fi

# ---------------------------------------------------------
# 5. DNS resolution works?
# ---------------------------------------------------------
if [ "$STATUS" != "FAIL" ]; then
  getent hosts github.com >/dev/null 2>&1 || set_warn "dns resolution failed"
fi

# ---------------------------------------------------------
# 6. Internet reachable? (ICMP)
# ---------------------------------------------------------
if [ "$STATUS" != "FAIL" ]; then
  ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 || set_warn "internet unreachable"
fi

# ---------------------------------------------------------
# RESULT
# ---------------------------------------------------------
echo "${STATUS}|${REASON}"
exit 0
