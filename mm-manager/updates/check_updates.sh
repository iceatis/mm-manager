#!/bin/bash
# =========================================================
# check_updates.sh
# MagicMirror Manager – Update status checker
# Version: v1.4.3
# =========================================================

set -e

BASE_DIR="$HOME/mm-manager"
MM_DIR="$HOME/MagicMirror"
STATE_DIR="/var/lib/mm-manager"

ROLE=$(cat "$STATE_DIR/system_mode" 2>/dev/null || echo "unknown")

echo "=== MagicMirror Update Status ==="
echo "Role: $ROLE"
echo

# ---------------------------------------------------------
# NODE.JS
# ---------------------------------------------------------
NODE_CURRENT="not installed"
NODE_LATEST_LTS="unknown"
NODE_STATUS="unknown"

if command -v node >/dev/null 2>&1; then
  NODE_CURRENT=$(node -v | sed 's/^v//')
fi

if command -v nvm >/dev/null 2>&1; then
  NODE_LATEST_LTS=$(nvm ls-remote --lts | tail -1 | awk '{print $1}' | sed 's/^v//')
fi

if [ "$NODE_CURRENT" != "not installed" ] && [ "$NODE_LATEST_LTS" != "unknown" ]; then
  if [ "$NODE_CURRENT" = "$NODE_LATEST_LTS" ]; then
    NODE_STATUS="up-to-date"
  else
    NODE_STATUS="update available"
  fi
fi

echo "Node.js:"
echo "  Installed : $NODE_CURRENT"
echo "  Latest LTS: $NODE_LATEST_LTS"
echo "  Status    : $NODE_STATUS"
echo

# ---------------------------------------------------------
# NPM
# ---------------------------------------------------------
NPM_CURRENT="not installed"
NPM_LATEST="unknown"
NPM_STATUS="unknown"

if command -v npm >/dev/null 2>&1; then
  NPM_CURRENT=$(npm -v)
  NPM_LATEST=$(npm view npm version 2>/dev/null || echo "unknown")
fi

if [ "$NPM_CURRENT" != "not installed" ] && [ "$NPM_LATEST" != "unknown" ]; then
  if [ "$NPM_CURRENT" = "$NPM_LATEST" ]; then
    NPM_STATUS="up-to-date"
  else
    NPM_STATUS="update available"
  fi
fi

echo "npm:"
echo "  Installed : $NPM_CURRENT"
echo "  Latest    : $NPM_LATEST"
echo "  Status    : $NPM_STATUS"
echo

# ---------------------------------------------------------
# MAGICMIRROR
# ---------------------------------------------------------
MM_STATUS="not installed"
MM_BRANCH="n/a"
MM_LOCAL_COMMIT="n/a"
MM_REMOTE_STATUS="n/a"

if [ -d "$MM_DIR/.git" ]; then
  MM_STATUS="installed"
  cd "$MM_DIR"

  MM_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  MM_LOCAL_COMMIT=$(git rev-parse --short HEAD)

  git fetch origin >/dev/null 2>&1

  LOCAL_HASH=$(git rev-parse HEAD)
  REMOTE_HASH=$(git rev-parse @{u} 2>/dev/null || echo "")

  if [ -n "$REMOTE_HASH" ]; then
    if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
      MM_REMOTE_STATUS="up-to-date"
    else
      MM_REMOTE_STATUS="update available"
    fi
  fi
fi

echo "MagicMirror:"
echo "  Status    : $MM_STATUS"
echo "  Branch    : $MM_BRANCH"
echo "  Commit    : $MM_LOCAL_COMMIT"
echo "  Update    : $MM_REMOTE_STATUS"
echo

# ---------------------------------------------------------
# SUMMARY (machine-readable)
# ---------------------------------------------------------
echo "=== SUMMARY ==="
echo "NODE_STATUS=$NODE_STATUS"
echo "NPM_STATUS=$NPM_STATUS"
echo "MM_STATUS=$MM_REMOTE_STATUS"
