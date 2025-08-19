# Loki Stack - Grafana + Loki + Promtail

Stack completo de observabilidade para logs usando o chart oficial `loki-stack` do Grafana.

## 🚀 Componentes

### 1. **Grafana**
- Interface web para visualização de logs
- Dashboards pre-configurados
- Data sources integrados (Loki + Prometheus)
- Usuário padrão: `admin` / Senha: `admin123`

### 2. **Loki**
- Sistema de agregação e armazenamento de logs
- Query language similar ao PromQL
- Storage em filesystem (desenvolvimento)
- Retenção configurável (7 dias padrão)

### 3. **Promtail**
- Coletor de logs para Kubernetes
- Descoberta automática de pods
- Pipeline de processamento configurável
- Labels automáticos para nginx e apache

## 📋 Pré-requisitos

- Cluster Kubernetes rodando (Kind, Minikube, etc.)
- Helm 3.x instalado
- Ingress Controller (nginx-ingress)
- kubectl configurado

## 🛠️ Instalação

### Instalação Rápida
```bash
# Executar o script de instalação
./installers/loki-stack-install.sh
```

### Instalação Manual
```bash
# 1. Adicionar repositório Helm
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 2. Criar namespace
kubectl create namespace logging

# 3. Instalar Loki Stack
helm install loki-stack grafana/loki-stack \
    --namespace logging \
    --values observability/loki-stack-values.yaml \
    --wait \
    --timeout 15m
```

## 🌐 Acesso

### URLs
- **Grafana**: http://grafana.local
- **Loki**: http://loki.local

### Credenciais
- **Usuário**: admin
- **Senha**: admin123

## 📊 Dashboards Disponíveis

### Grafana Dashboards
- **Loki Overview** (ID: 12019)
  - Visão geral dos logs do cluster
  - Métricas de ingestão e consultas
  - Status dos componentes

- **Kubernetes Cluster** (ID: 315)
  - Monitoramento geral do cluster
  - Métricas de pods, nós e recursos

### Data Sources
- **Loki** (padrão)
  - URL: http://loki.logging.svc.cluster.local:3100
  - Para consultas de logs

- **Prometheus**
  - URL: http://prometheus-operated.monitoring.svc.cluster.local:9090
  - Para métricas do cluster

## 🔍 Consultas de Logs

### LogQL Básico
```logql
# Todos os logs
{job="kubernetes-pods"}

# Logs de um pod específico
{job="kubernetes-pods", pod="nginx-deployment-xyz"}

# Logs com erro
{job="kubernetes-pods"} |= "error"

# Logs de uma aplicação específica
{job="kubernetes-pods", app="nginx"}

# Logs com regex
{job="kubernetes-pods"} |~ ".*error.*"
```

### Exemplos de Queries
```logql
# Contar logs por namespace
sum by (namespace) (count_over_time({job="kubernetes-pods"}[5m]))

# Logs de erro nos últimos 10 minutos
{job="kubernetes-pods"} |= "error" [10m]

# Logs com labels específicos
{job="kubernetes-pods", app="apache", order_id=~".*"}
```

## ⚙️ Configuração

### Storage
- **Tipo**: filesystem (desenvolvimento)
- **Tamanho**: 5Gi por padrão
- **Retenção**: 7 dias

### Recursos
- **Grafana**: 256Mi-512Mi RAM, 100m-200m CPU
- **Loki**: 512Mi-1Gi RAM, 200m-500m CPU
- **Promtail**: 128Mi-256Mi RAM, 100m-200m CPU

### Ingress
- **Classe**: nginx
- **Hosts**: grafana.local, loki.local
- **TLS**: Desabilitado (desenvolvimento)

## 🔧 Personalização

### Modificar Valores
Edite o arquivo `observability/loki-stack-values.yaml`:

```yaml
# Alterar senha do admin
grafana:
  adminPassword: "minha-senha-segura"

# Alterar retenção de logs
loki:
  retention:
    days: 30

# Adicionar dashboards customizados
grafana:
  dashboards:
    default:
      meu-dashboard:
        gnetId: 12345
        revision: 1
        datasource: Loki
```

### Adicionar Data Sources
```yaml
grafana:
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Elasticsearch
          type: elasticsearch
          url: http://elasticsearch:9200
          access: proxy
```

## 🚨 Troubleshooting

### Pods não ficam Ready
```bash
# Verificar logs dos pods
kubectl logs -f -l app.kubernetes.io/name=grafana -n logging
kubectl logs -f -l app.kubernetes.io/name=loki -n logging

# Verificar eventos
kubectl get events -n logging --sort-by='.lastTimestamp'
```

### Ingress não funciona
```bash
# Verificar se o Ingress Controller está rodando
kubectl get pods -n ingress-nginx

# Verificar status dos Ingress
kubectl get ingress -n logging
kubectl describe ingress -n logging
```

### Logs não aparecem
```bash
# Verificar se o Promtail está coletando
kubectl logs -f -l app.kubernetes.io/name=promtail -n logging

# Verificar configuração do Promtail
kubectl get configmap -n logging
```

## 📚 Referências

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Grafana Documentation](https://grafana.com/docs/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/query/)
- [Helm Chart Values](https://github.com/grafana/helm-charts/tree/main/charts/loki-stack)

## 🔄 Atualizações

### Atualizar Helm Chart
```bash
# Atualizar repositório
helm repo update

# Atualizar release
helm upgrade loki-stack grafana/loki-stack \
    --namespace logging \
    --values observability/loki-stack-values.yaml \
    --wait
```

### Desinstalar
```bash
# Desinstalar Loki Stack
helm uninstall loki-stack -n logging

# Remover namespace
kubectl delete namespace logging
```

