#!/bin/bash

# First step
sudo apt update -y
sudo apt install -y xauth x11-utils x11-xserver-utils software-properties-common
sudo snap remove firefox || echo "⚠️ Snap Firefox não instalado, prosseguindo..."
sudo add-apt-repository -y ppa:mozillateam/ppa
sudo apt update -y
sudo apt upgrade -y
sudo reboot

# Second step after reboot
sudo apt install -y firefox
sudo tee /etc/apt/preferences.d/mozilla-firefox <<EOF
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

