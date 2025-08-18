#!/bin/bash

# Create password for user ubuntu.
# Test RDP connection via remote desktop(Remmina).

# Setup python and project virtual environment.
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-pip python3-venv
git clone https://github.com/joseafilho/k8s-kind-nginx-playground.git
mv k8s-kind-nginx-playground playground
cd playground
git checkout developer
cd ..
python3 -m venv ./playground/.venv
sudo chown -R ubuntu:ubuntu ./playground/.venv/
source ./playground/.venv/bin/activate
pip3 install -r ./playground/installers/requirements.txt

# Install k8s components.
sudo ./playground/installers/configure-docker-daemon.sh
sudo ./playground/installers/configure-hosts.sh
sudo ./playground/installers/kind-ec2-install.sh
sudo ./playground/installers/kubectl-ec2-install.sh
sudo ./playground/installers/helm-install.sh
sudo ./playground/installers/cilium-install.sh
sudo ./playground/installers/kubectl-top-install.sh
sudo ./playground/installers/ingress-controller-install.sh
sudo ./playground/installers/kube-dash-install.sh
sudo ./playground/installers/observability-install.sh
sudo ./playground/installers/apache-hello-install.sh
sudo ./playground/installers/harbor-install.sh
sudo ./playground/installers/postgres-install.sh
sudo ./playground/installers/ecom-python-install.sh