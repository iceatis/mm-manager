#!/bin/bash
set -e

# =========================================================
# Install system dependencies for MagicMirror
# Installer-aware (no UI in installer mode)
# =========================================================

INSTALLER_MODE="${INSTALLER_MODE:-0}"

# ---------------------------------------------------------
# SYSTEM STATE (REBOOT FLAG)
# ---------------------------------------------------------
source "$HOME/mm-manager/mm-state.sh"

log() {
  echo "[deps] $1"
}

ui_msgbox() {
  [ "$INSTALLER_MODE" = "1" ] && return 0
  whiptail --msgbox "$1" 10 60
}

# ---------------------------------------------------------
# WHIPTAIL (only if interactive)
# ---------------------------------------------------------
if [ "$INSTALLER_MODE" != "1" ]; then
  if ! command -v whiptail >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y whiptail
  fi
fi

# ---------------------------------------------------------
# SYSTEM UPDATE
# ---------------------------------------------------------
log "apt update"
sudo apt update -y

# ---------------------------------------------------------
# BASE PACKAGES
# ---------------------------------------------------------
log "Base packages install"

sudo apt install -y \
  xserver-xorg \
  xinit \
  openbox \
  unclutter \
  x11-xserver-utils \
  libgtk-3-0 \
  libgbm1 \
  libasound2 \
  libnss3 \
  libxss1 \
  libxtst6 \
  fonts-dejavu \
  ca-certificates \
  git \
  curl \
  nano \
  dos2unix \
  network-manager

# ---------------------------------------------------------
# NVM + NODE
# ---------------------------------------------------------
if [ ! -d "$HOME/.nvm" ]; then
  log "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -f "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

NODE_VERSION="22.21.1"

if ! command -v node >/dev/null 2>&1; then
  log "Installing Node.js $NODE_VERSION"
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
else
  log "Node.js already installed: $(node -v)"
fi

log "Updating npm"
npm install -g npm@11.7.0

# ---------------------------------------------------------
# MAGICMIRROR CLONE (IF MISSING)
# ---------------------------------------------------------
if [ ! -d "$HOME/MagicMirror" ]; then
  log "Cloning MagicMirror"
  git clone https://github.com/MichMich/MagicMirror.git "$HOME/MagicMirror"
fi

cd "$HOME/MagicMirror"

log "Installing MagicMirror dependencies"
rm -rf node_modules package-lock.json
NODE_OPTIONS="--max_old_space_size=512" npm install --omit=dev

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------
set_reboot_required
ui_msgbox "✅ Függőségek telepítve."
