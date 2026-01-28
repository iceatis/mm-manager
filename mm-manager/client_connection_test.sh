#!/bin/bash

# Client-side MagicMirror server connection test
# Used before saving server IP / port

SERVER_IP="$1"
SERVER_PORT="$2"
TIMEOUT=3

# ----------------------------
# 1. Ping test
# ----------------------------
if ! ping -c 1 -W "$TIMEOUT" "$SERVER_IP" >/dev/null 2>&1; then
  echo "FAIL|host unreachable"
  exit 2
fi

# ----------------------------
# 2. TCP port test
# ----------------------------
if ! timeout "$TIMEOUT" bash -c "</dev/tcp/$SERVER_IP/$SERVER_PORT" 2>/dev/null; then
  echo "WARN|host reachable but port closed"
  exit 1
fi

# ----------------------------
# 3. HTTP test
# ----------------------------
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --connect-timeout "$TIMEOUT" \
  "http://$SERVER_IP:$SERVER_PORT/")

if [[ "$HTTP_CODE" =~ ^2|^3 ]]; then
  echo "OK|server reachable on http"
  exit 0
fi

echo "WARN|port open but http failed ($HTTP_CODE)"
exit 1
