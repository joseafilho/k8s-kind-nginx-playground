#!/bin/bash

# Script para instalar o Loki Stack (Grafana + Loki + Promtail)
# Stack completo de observabilidade para logs

set -e

echo "=========================================="
echo "🚀 Loki Stack Installation"
echo "=========================================="

# Verificar se o Helm está instalado
if ! command -v helm &> /dev/null; then
    echo "❌ Helm não está instalado. Execute primeiro: ./installers/helm-install.sh"
    exit 1
fi

# Verificar se o kubectl está funcionando
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl não consegue se conectar ao cluster. Verifique se o cluster está rodando."
    exit 1
fi

# Adicionar repositório Helm do Grafana
echo "📦 Adicionando repositório Helm do Grafana..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Adicionar entradas no /etc/hosts
echo "📝 Adicionando entradas no /etc/hosts..."
if ! grep -q "grafana.local" /etc/hosts; then
    sudo bash -c 'echo "127.0.0.1 grafana.local" >> /etc/hosts'
    echo "✅ Adicionado grafana.local ao /etc/hosts"
else
    echo "ℹ️  grafana.local já existe no /etc/hosts"
fi

if ! grep -q "loki.local" /etc/hosts; then
    sudo bash -c 'echo "127.0.0.1 loki.local" >> /etc/hosts'
    echo "✅ Adicionado loki.local ao /etc/hosts"
else
    echo "ℹ️  loki.local já existe no /etc/hosts"
fi

# Criar namespace para logging
echo "🏗️  Criando namespace logging..."
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

# Instalar Loki Stack
echo "🚀 Instalando Loki Stack..."
helm install loki-stack grafana/loki-stack \
    --namespace logging \
    --values ./observability/loki-stack-values.yaml \
    --wait \
    --timeout 15m

# Aguardar pods ficarem prontos
echo "⏳ Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n logging --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=loki -n logging --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=promtail -n logging --timeout=300s

# Verificar status da instalação
echo "🔍 Verificando status da instalação..."
echo ""
echo "📊 Pods no namespace logging:"
kubectl get pods -n logging

echo ""
echo "🌐 Ingress configurados:"
kubectl get ingress -n logging

echo ""
echo "🔗 Services configurados:"
kubectl get svc -n logging

# Verificar se o Ingress Controller está funcionando
echo ""
echo "🔍 Verificando Ingress Controller..."
if kubectl get pods -n ingress-nginx | grep -q "Running"; then
    echo "✅ Ingress Controller está rodando"
else
    echo "⚠️  Ingress Controller não está rodando. Execute: ./installers/ingress-controller-install.sh"
fi

echo ""
echo "=========================================="
echo "✅ Loki Stack instalado com sucesso!"
echo "=========================================="
echo ""
echo "🌐 URLs de acesso:"
echo "  - Grafana: http://grafana.local"
echo "    Usuário: admin, Senha: admin123"
echo ""
echo "  - Loki: http://loki.local"
echo ""
echo "📊 Dashboards disponíveis:"
echo "  - Loki Overview (ID: 12019)"
echo "  - Kubernetes Cluster (ID: 315)"
echo ""
echo "📋 Data Sources configurados:"
echo "  - Loki (padrão)"
echo "  - Prometheus"
echo ""
echo "🔍 Para ver logs em tempo real:"
echo "  kubectl logs -f -l app=promtail -n logging"
echo ""
echo "📚 Para mais informações:"
echo "  https://grafana.com/docs/loki/latest/"
echo "=========================================="
