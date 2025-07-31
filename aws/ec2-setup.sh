#!/bin/bash

# Install XFCE and RDP.
sudo apt update
sudo apt install -y xfce4 xfce4-goodies xrdp
sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Execute with user ubuntu.
echo "startxfce4" > ~/.xsession
chmod +x ~/.xsession
####

# Add user xrdp to ssl-cert group.
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman

# Set password for user ubuntu to access via RDP.
echo "ubuntu:ubuntu-rdp" | sudo chpasswd

# Install firefox.
sudo apt install -y firefox

# Install python3-pip and apt-transport-https.
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-pip python3-venv
sudo apt install -y apt-transport-https

# Clone the repository.
git clone https://github.com/joseafilho/k8s-kind-nginx-playground.git
mv k8s-kind-nginx-playground playground

echo "🔧 Creating virtual environment..."
python3 -m venv ./playground/.venv
sudo chown -R ubuntu:ubuntu ./playground/.venv/
source ./playground/.venv/bin/activate

echo "🔧 Installing python3 packages..."
pip3 install -r ./playground/installers/requirements.txt
