#!/bin/bash
set -e

# Wayland tiltása, X preferálása
sudo mkdir -p /etc/X11/xorg.conf.d

sudo tee /etc/X11/xorg.conf.d/10-force-xorg.conf >/dev/null <<EOF
Section "ServerFlags"
    Option "AutoAddGPU" "true"
EndSection
EOF

# Biztos ami biztos: Wayland tiltása, ha lightdm jelen van
if [ -f /etc/lightdm/lightdm.conf ]; then
  sudo sed -i 's/^#WaylandEnable=.*/WaylandEnable=false/' /etc/lightdm/lightdm.conf || true
  sudo sed -i 's/^WaylandEnable=.*/WaylandEnable=false/' /etc/lightdm/lightdm.conf || true
fi

echo "Xorg kényszerítve, Wayland kizárva"
