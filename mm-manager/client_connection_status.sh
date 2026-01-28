#!/bin/bash

SERVER_IP="$1"
SERVER_PORT="$2"
TIMEOUT=2

# ----------------------------
# Defaults
# ----------------------------
PING_STATUS="⏳"
TCP_STATUS="⏳"

# ----------------------------
# Ping test
# ----------------------------
if ping -c 1 -W "$TIMEOUT" "$SERVER_IP" >/dev/null 2>&1; then
  PING_STATUS="✅"
else
  PING_STATUS="❌"
fi

# ----------------------------
# TCP port test
# ----------------------------
if timeout "$TIMEOUT" bash -c "</dev/tcp/$SERVER_IP/$SERVER_PORT" \
  >/dev/null 2>&1; then
  TCP_STATUS="✅"
else
  TCP_STATUS="❌"
fi

# ----------------------------
# Output (display only)
# ----------------------------
cat <<EOF
Kapcsolat teszt (csak információ):

  Ping (ICMP):     $PING_STATUS
  TCP port ($SERVER_PORT): $TCP_STATUS
EOF
