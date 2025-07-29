# Observability Stack

Stack completa de observabilidade para monitoramento do cluster Kubernetes.

## Componentes

### 1. **Prometheus**
- Coletação de métricas do cluster
- Armazenamento de séries temporais
- Sistema de alertas

### 2. **Grafana**
- Dashboards e visualizações
- Query builder para Prometheus
- Alertas e notificações

### 3. **Jaeger**
- Distributed tracing
- Rastreamento de requisições
- Análise de performance

### 4. **Loki**
- Coletação e armazenamento de logs
- Query de logs similar ao Prometheus
- Integração com Grafana

### 5. **AlertManager**
- Gerenciamento de alertas
- Agrupamento e supressão
- Notificações (email, Slack, etc.)

## Acesso

### Grafana
- **URL**: http://grafana.local:30001
- **Usuário**: admin
- **Senha**: prom-operator

### Prometheus
- **URL**: http://prometheus.local:30001

### Jaeger
- **URL**: http://jaeger.local:30001

### AlertManager
- **URL**: http://alertmanager.local:30001

## Dashboards

### Grafana Dashboards
- **Kubernetes Cluster**: Monitoramento geral do cluster
- **Node Exporter**: Métricas dos nós
- **Jaeger**: Traces distribuídos
- **Loki**: Logs do cluster

## Alertas

### Alertas Configurados
- **High CPU Usage**: CPU > 80%
- **High Memory Usage**: Memory > 80%
- **Pod Restarts**: Pods reiniciando frequentemente
- **Node Down**: Nós indisponíveis
- **Disk Space**: Espaço em disco baixo

## Configuração

### Prometheus Values
- Retenção: 15 dias
- Storage: 5Gi
- Scrape interval: 30s

### Grafana Values
- Persistence: 5Gi
- Admin password: prom-operator
- Dashboards: Pre-configurados

### Jaeger Values
- Storage: Elasticsearch
- Sampling: 100%
- UI: Habilitado

### Loki Values
- Retention: 7 dias
- Storage: 5Gi
- Single binary mode

## Referências

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/) 