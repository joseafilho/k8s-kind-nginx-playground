#!/bin/bash
# Script para configurar hosts locais para ELK Stack

set -e

echo "=========================================="
echo "🌐 Configurando hosts locais para ELK Stack"
echo "=========================================="

# Get the ingress controller external IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$INGRESS_IP" ]; then
    INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}')
fi

if [ -z "$INGRESS_IP" ]; then
    echo "❌ Não foi possível encontrar o IP do Ingress Controller."
    echo "   Certifique-se de que o Ingress Controller está instalado e rodando."
    exit 1
fi

echo "🔍 IP do Ingress Controller encontrado: $INGRESS_IP"

# Check if entries already exist
if grep -q "elasticsearch.local" /etc/hosts; then
    echo "⚠️  Entradas para ELK Stack já existem no /etc/hosts"
    echo "   Removendo entradas antigas..."
    sudo sed -i '/elasticsearch.local\|kibana.local/d' /etc/hosts
fi

# Add new entries
echo "📝 Adicionando entradas para ELK Stack..."
echo "$INGRESS_IP elasticsearch.local" | sudo tee -a /etc/hosts
echo "$INGRESS_IP kibana.local" | sudo tee -a /etc/hosts

echo ""
echo "✅ Hosts locais configurados com sucesso!"
echo ""
echo "📋 Entradas adicionadas:"
echo "  $INGRESS_IP elasticsearch.local"
echo "  $INGRESS_IP kibana.local"

echo ""
echo "🔍 Para verificar se está funcionando:"
echo "  curl http://elasticsearch.local"
echo "  curl http://kibana.local"

echo ""
echo "=========================================="
