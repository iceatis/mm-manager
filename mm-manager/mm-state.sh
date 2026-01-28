#!/bin/bash
set -e

STATE_DIR="/var/lib/mm-manager"
REBOOT_FLAG="$STATE_DIR/reboot-required"

init_state() {
  if [ ! -d "$STATE_DIR" ]; then
    sudo mkdir -p "$STATE_DIR"
    sudo chown "$USER":"$USER" "$STATE_DIR"
  fi
}

set_reboot_required() {
  init_state
  sudo touch "$REBOOT_FLAG"
  sudo chown "$USER":"$USER" "$REBOOT_FLAG"
}

clear_reboot_required() {
  sudo rm -f "$REBOOT_FLAG"
}

is_reboot_required() {
  [ -f "$REBOOT_FLAG" ]
}
