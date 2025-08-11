#!/bin/bash

# Script to install the complete observability stack
# Prometheus + Grafana + Jaeger + Loki + AlertManager

set -e

echo "=========================================="
echo "Observability Stack Installation"
echo "=========================================="

# Add Helm repositories
echo "📦 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

# Add entries to /etc/hosts
echo "📝 Adding entries to /etc/hosts..."
sudo bash -c 'echo "127.0.0.1 grafana.local" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 prometheus.local" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 jaeger.local" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 loki.local" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 alertmanager.local" >> /etc/hosts'

# 1. Install Prometheus Stack
echo "🚀 Installing Prometheus Stack..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values ./playground/observability/prometheus-values.yaml \
    --wait \
    --timeout 10m

# 2. Install Jaeger
# echo "🔍 Installing Jaeger..."
# kubectl create namespace jaeger --dry-run=client -o yaml | kubectl apply -f -
# helm install jaeger jaegertracing/jaeger \
#     --namespace jaeger \
#     --values ./playground/observability/jaeger-values.yaml \
#     --wait \
#     --timeout 5m

# 3. Install Loki
echo "📋 Installing Loki..."
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
helm install loki grafana/loki \
    --namespace logging \
    --values ./playground/observability/loki-values.yaml \
    --wait \
    --timeout 10m

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=loki -n logging --timeout=300s
# kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=jaeger -n jaeger --timeout=300s

# Check installation status
echo "🔍 Checking installation status..."
kubectl get pods -n monitoring
# kubectl get pods -n jaeger
kubectl get pods -n logging
kubectl get ingress -A | grep -E "(grafana|jaeger|loki)"

echo ""
echo "=========================================="
echo "✅ Observability Stack installed successfully!"
echo "=========================================="
echo ""
echo "🌐 Access URLs:"
echo "  - Grafana: http://grafana.local:30001"
echo "    User: admin, Password: prom-operator"
echo ""
echo "  - Prometheus: http://prometheus.local:30001"
echo ""
echo "  - Jaeger: http://jaeger.local:30001"
echo ""
echo "  - Loki: http://loki.local:30001"
echo ""
echo "  - AlertManager: http://alertmanager.local:30001"
echo "==========================================" 