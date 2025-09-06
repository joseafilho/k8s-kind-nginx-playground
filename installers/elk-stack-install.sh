#!/bin/bash
# Script to install ELK Stack (Elasticsearch, Logstash, Kibana)

set -e

echo "=========================================="
echo "🔍 Installing ELK Stack"
echo "=========================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Por favor, instale o kubectl primeiro."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm não encontrado. Por favor, instale o Helm primeiro."
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cluster Kubernetes não está rodando. Por favor, inicie o cluster primeiro."
    exit 1
fi

echo "📦 Adicionando repositórios Helm necessários..."

# Add Elastic Helm repository
helm repo add elastic https://helm.elastic.co
helm repo update

echo "🏗️ Criando namespace para ELK Stack..."
kubectl create namespace elk --dry-run=client -o yaml | kubectl apply -f -

echo "🔧 Instalando Elasticsearch..."
helm upgrade --install elasticsearch elastic/elasticsearch \
    --namespace elk \
    --values ./elk/elasticsearch-values.yaml \
    --wait \
    --timeout=10m

echo "📊 Verificando status do Elasticsearch..."
kubectl wait --namespace elk \
    --for=condition=ready pod \
    --selector=app=elasticsearch-master \
    --timeout=300s

echo "🔍 Instalando Kibana..."
helm upgrade --install kibana elastic/kibana \
    --namespace elk \
    --values ./elk/kibana-values.yaml \
    --wait \
    --timeout=10m

echo "📊 Verificando status do Kibana..."
kubectl wait --namespace elk \
    --for=condition=ready pod \
    --selector=app=kibana \
    --timeout=300s

echo "🔄 Instalando Logstash..."
helm upgrade --install logstash elastic/logstash \
    --namespace elk \
    --values ./elk/logstash-values.yaml \
    --wait \
    --timeout=10m

echo "📊 Verificando status do Logstash..."
kubectl wait --namespace elk \
    --for=condition=ready pod \
    --selector=app=logstash \
    --timeout=300s

echo ""
echo "=========================================="
echo "✅ ELK Stack instalado com sucesso!"
echo "=========================================="

echo ""
echo "📋 Informações de acesso:"
echo "  - Elasticsearch: http://elasticsearch.local"
echo "  - Kibana: http://kibana.local"
echo "  - Logstash: Porta 5044 (Beats), 5000 (TCP/UDP)"

echo ""
echo "🔧 Para configurar os hosts locais, adicione ao /etc/hosts:"
echo "  127.0.0.1 elasticsearch.local kibana.local"

echo ""
echo "📊 Para verificar o status dos pods:"
echo "  kubectl get pods -n elk"

echo ""
echo "📝 Para ver os logs:"
echo "  kubectl logs -n elk -l app=elasticsearch-master"
echo "  kubectl logs -n elk -l app=kibana"
echo "  kubectl logs -n elk -l app=logstash"

echo ""
echo "🎯 Para testar o envio de logs via TCP:"
echo "  echo '{\"message\":\"Test log entry\",\"timestamp\":\"$(date -Iseconds)\"}' | nc localhost 5000"

echo ""
echo "=========================================="
