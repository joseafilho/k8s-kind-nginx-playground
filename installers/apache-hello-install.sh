#!/bin/bash
# Script to install apache hello.

# Check if the --local-debug parameter was passed
APACHE_HELLO_DIR="./playground/apache-hello"
for arg in "$@"; do
  if [ "$arg" == "--local-debug" ]; then
    APACHE_HELLO_DIR="./apache-hello"
    break
  fi
done

set -e

echo "=========================================="
echo "🔧 Installing apache hello"
echo "=========================================="

kubectl create namespace ns1
kubectl apply -f $APACHE_HELLO_DIR/hello-apache-cm.yaml
kubectl apply -f $APACHE_HELLO_DIR/hello-apache-dpl.yaml
kubectl apply -f $APACHE_HELLO_DIR/hello-apache-svc.yaml
kubectl apply -f $APACHE_HELLO_DIR/hello-apache-ing.yaml

echo ""
echo "=========================================="
echo "✅ Apache hello installed successfully!"
echo "=========================================="