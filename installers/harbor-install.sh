#!/bin/bash
# Script to install harbor.

# Check if the --local-debug parameter was passed
HARBOR_DIR="./playground/harbor"
for arg in "$@"; do
  if [ "$arg" == "--local-debug" ]; then
    HARBOR_DIR="./harbor"
    break
  fi
done

set -e

echo "=========================================="
echo "🔧 Installing Harbor"
echo "=========================================="

# Add entries to /etc/hosts.
echo "📝 Adding entries to /etc/hosts..."
sudo bash -c 'echo "127.0.0.1 core.harbor.domain" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 notary.harbor.domain" >> /etc/hosts'

# Add harbor repository to helm.
echo "🔍 Adding harbor repository to helm..."
helm repo add harbor https://helm.goharbor.io
helm repo update

# Install harbor.
echo "🚀 Installing Harbor..."
kubectl create namespace harbor
helm install harbor harbor/harbor --namespace harbor --values $HARBOR_DIR/values.yaml

echo ""
echo "=========================================="
echo "✅ Harbor installed successfully!"
echo "=========================================="