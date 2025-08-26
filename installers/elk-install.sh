#!/bin/bash

# Script to install ELK Stack (Elasticsearch, Kibana)
# Optimized for local study environments with Kind cluster
# Simplified version focusing on core components

set -e

echo "=========================================="
echo "ELK Stack Installation (Simplified)"
echo "=========================================="

# Add Helm repositories
echo "📦 Adding Helm repositories..."
helm repo add elastic https://helm.elastic.co
helm repo update

# Add entries to /etc/hosts
echo "📝 Adding entries to /etc/hosts..."
sudo bash -c 'echo "127.0.0.1 elasticsearch.local" >> /etc/hosts' 2>/dev/null || true
sudo bash -c 'echo "127.0.0.1 kibana.local" >> /etc/hosts' 2>/dev/null || true

# Create namespace for ELK stack
echo "🏗️ Creating namespace for ELK stack..."
kubectl create namespace elk --dry-run=client -o yaml | kubectl apply -f -

# 1. Install Elasticsearch (lightweight version)
echo "🔍 Installing Elasticsearch..."
helm install elasticsearch elastic/elasticsearch \
    --namespace elk \
    --set replicas=1 \
    --set minimumMasterNodes=1 \
    --set resources.requests.memory=512Mi \
    --set resources.requests.cpu=250m \
    --set resources.limits.memory=1Gi \
    --set resources.limits.cpu=500m \
    --set volumeClaimTemplate.resources.requests.storage=1Gi \
    --wait \
    --timeout 10m

# 2. Install Kibana
echo "📊 Installing Kibana..."
helm install kibana elastic/kibana \
    --namespace elk \
    --set replicas=1 \
    --set resources.requests.memory=256Mi \
    --set resources.requests.cpu=100m \
    --set resources.limits.memory=512Mi \
    --set resources.limits.cpu=250m \
    --set service.type=ClusterIP \
    --wait \
    --timeout 5m

# Wait for pods to be ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=kibana -n elk --timeout=300s
kubectl wait --for=condition=ready pod -l app=elasticsearch-master -n elk --timeout=300s

# Check installation status
echo "🔍 Checking installation status..."
kubectl get pods -n elk
kubectl get svc -n elk

# Test Elasticsearch connectivity
echo "🔍 Testing Elasticsearch connectivity..."
ELASTIC_PASSWORD=$(kubectl get secret elasticsearch-master-credentials -n elk -o jsonpath='{.data.password}' | base64 -d)
echo "✅ Elasticsearch password obtained: ${ELASTIC_PASSWORD:0:8}..."

# Wait a bit more for services to be fully ready
echo "⏳ Waiting for services to be fully ready..."
sleep 30

# Create Ingress for Kibana
echo "🌐 Creating Ingress for Kibana..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-ingress
  namespace: elk
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: kibana.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kibana-kibana
            port:
              number: 5601
EOF

# Create Ingress for Elasticsearch
echo "🌐 Creating Ingress for Elasticsearch..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: elasticsearch-ingress
  namespace: elk
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: elasticsearch.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: elasticsearch-master
            port:
              number: 9200
EOF

# Get Elasticsearch password (already obtained above)
echo "🔑 Using Elasticsearch credentials..."

echo ""
echo "=========================================="
echo "✅ ELK Stack installed successfully!"
echo "=========================================="
echo ""
echo "🌐 Access URLs:"
echo "  - Kibana: http://kibana.local"
echo "    User: elastic"
echo "    Password: $ELASTIC_PASSWORD"
echo ""
echo "  - Elasticsearch: https://elasticsearch.local:9200"
echo "    User: elastic"
echo "    Password: $ELASTIC_PASSWORD"
echo ""
echo "📊 To check pod status:"
echo "   kubectl get pods -n elk"
echo ""
echo "📝 To see logs:"
echo "   kubectl logs -f -l app=kibana -n elk"
echo "   kubectl logs -f -l app=elasticsearch-master -n elk"
echo ""
echo "🔍 To check Ingress:"
echo "   kubectl get ingress -n elk"
echo ""
echo "=========================================="
