# K8S Playground

## Descrição

Este projeto fornece um ambiente completo de estudos, desenvolvimento e testes para Kubernetes:

- **Vagrant**: Provisionamento da VM
- **Kind**: Kubernetes IN Docker
- **Ingress**: Nginx
- **Container Registry**: Harbor para gerenciamento de imagens Docker
- **Banco de Dados**: PostgreSQL com interface pgAdmin
- **Aplicação de Exemplo**: API FastAPI em Python conectando ao PostgreSQL
- **Dashboard**: Kubernetes Dashboard para monitoramento
- **Aplicação Web**: Hello Apache App para demonstração
- **Stack de Observabilidade**: Prometheus + Grafana + Jaeger para monitoramento completo
- **Automação**: Scripts de provisionamento e configuração

O ambiente é ideal para desenvolvedores que precisam de um playground completo para testar aplicações Kubernetes, incluindo registry de containers, banco de dados, aplicações de exemplo e monitoramento avançado com métricas, logs e traces distribuídos.

## Pré-requisitos

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) (ou outro provider compatível com Vagrant)

## Estrutura do Projeto

```
.
├── apache-hello/                    # Aplicação de exemplo Apache
│   ├── hello-apache-app.png        # Exemplo visual da aplicação Apache
│   ├── hello-apache-cm.yaml        # ConfigMap para o Apache
│   ├── hello-apache-dpl.yaml       # Deployment do Apache
│   ├── hello-apache-ing.yaml       # Ingress para expor o serviço Apache
│   └── hello-apache-svc.yaml       # Service para o Apache
├── harbor/                          # Container Registry
│   ├── values.yaml                  # Configuração Helm do Harbor sem HTTPS
│   ├── docker-daemon-config.md      # Instruções para configurar Docker daemon
│   └── README.md                    # Documentação de acesso ao Harbor
├── ingress-nginx/                   # Controlador de Ingress
│   └── ingress.yaml                # Configuração do Ingress Nginx
├── kubernetes-dashboard/            # Dashboard do Kubernetes
│   ├── kube-dashboard.png          # Exemplo visual do Dashboard
│   ├── dash-ing.yaml               # Ingress para o Dashboard
│   └── dash-admin.yaml             # ServiceAccount e permissões para o Dashboard
├── pgadmin/                         # Interface de administração PostgreSQL
│   ├── README.md                   # Documentação de acesso ao pgAdmin
│   └── pgadmin-ing.yaml            # Ingress para o pgAdmin
├── projects/                        # Projetos de exemplo
│   └── ecom-python/
│       ├── main.py                  # API FastAPI de produtos
│       ├── requirements.txt         # Dependências Python
│       ├── Dockerfile               # Dockerfile da API
│       ├── README.md                # Instruções da API
│       └── infra/
│           ├── deployment.yaml      # Deployment do app no K8s
│           ├── ingress.yaml         # Ingress do app
│           ├── namespace.yaml       # Namespace ecom-python
│           └── service.yaml         # Service do app
├── terraform/                       # Configurações Terraform para AWS
│   ├── README.md                   # Documentação de deploy AWS
│   ├── play-terraform.sh           # Gerador dinâmico de configuração Terraform
│   └── user_data.sh                # Script de inicialização para EC2
├── aws/                            # Scripts específicos para AWS
│   └── ec2-setup.sh               # Configuração de ambiente EC2
├── docs/                           # Documentação do projeto
│   └── draft/
│       └── rh-ecosystem.png       # Diagrama do ecossistema Red Hat
├── command-utils/                   # Utilitários de linha de comando
│   └── debug.sh                     # Script utilitário
├── installers/                      # Scripts de instalação
│   ├── configure-docker-daemon.sh   # Script para configurar Docker daemon
│   ├── kind-vagrant-install.sh      # Script para instalar Kind (Vagrant)
│   ├── kind-ec2-install.sh          # Script para instalar Kind (EC2)
│   ├── kubectl-vagrant-install.sh   # Script para instalar kubectl (Vagrant)
│   ├── kubectl-ec2-install.sh       # Script para instalar kubectl (EC2)
│   ├── helm-install.sh              # Script para instalar Helm
│   ├── cilium-install.sh            # Script para instalar Cilium
│   ├── kubectl-top-install.sh       # Script para instalar Metrics Server
│   ├── configure-hosts.sh           # Script para configurar /etc/hosts
│   ├── apache-hello-install.sh      # Script para instalar Apache Hello App
│   ├── harbor-install.sh            # Script para instalar Harbor
│   ├── ingress-controller-install.sh # Script para instalar Ingress Controller
│   ├── kube-dash-install.sh         # Script para instalar Kubernetes Dashboard
│   ├── postgres-install.sh          # Script para instalar PostgreSQL
│   ├── ecom-python-install.sh       # Script para instalar aplicação Python
│   ├── observability-install.sh     # Script para instalar stack de observabilidade
│   ├── firefox-x11-ec2-install.sh   # Script para instalar Firefox (EC2)
│   ├── xfce-xrdp-k8s-ec2-install.sh # Script para instalar XFCE (EC2)
│   ├── installer.py                 # Script Python especialista em executar shell scripts
│   ├── installer-config.yaml        # Configuração YAML para o installer.py
│   ├── installer-README.md          # Documentação do installer.py
│   ├── requirements.txt             # Dependências Python completas para installer.py
│   └── requirements-minimal.txt     # Dependências Python mínimas para installer.py
├── observability/                   # Stack de observabilidade
│   ├── README.md                    # Documentação da stack de observabilidade
│   ├── prometheus-values.yaml       # Configuração do Prometheus Stack
│   ├── jaeger-values.yaml           # Configuração do Jaeger
│   ├── loki-values.yaml             # Configuração do Loki
│   └── alerts.yaml                  # Configuração de alertas
├── bootstrap.sh                     # Script de bootstrap para provisionamento
├── create-environment.sh            # Script unificado para criar ambiente (Local/AWS)
├── Vagrantfile                      # Arquivo de configuração do Vagrant
└── README.md                        # Este arquivo
```

## Como usar

1. **Clone o repositório:**
   ```sh
   git clone git@github.com:joseafilho/k8s-kind-nginx-playground.git
   cd k8s-kind-nginx-playground
   ```

2. **Suba o ambiente:**

   - **Local com Vagrant:**
     ```sh
     # Com GUI
     ./create-environment.sh --gui --memory 8192 --cpus 4
     
     # Sem GUI
     ./create-environment.sh --no-gui --memory 4096 --cpus 2
     ```

     Acesso a máquina virtual via ssh:
     ```sh
     vagrant ssh
     ```
   
   - **AWS EC2 (via Terraform):**
     ```sh
     # Deploy simples
     ./create-environment.sh --aws --key-name my-key
     
     # Deploy com recursos personalizados
     ./create-environment.sh --aws --instance-type t3a.large --region us-east-1 --key-name my-key
     ```

## Validação de Funcionamento

- **Com interface gráfica (GUI):**
  1. Após acessar a máquina virtual via VirtualBox, abra o navegador Firefox instalado na VM.
     - Usuário padrão da VM: **vagrant**
     - Senha padrão da VM: **vagrant**
  2. **Hello Apache App**: Acesse http://domain.local:30001/hello-apache/
     - Você deve ver a página de boas-vindas do Hello Apache App
     - ![Exemplo Hello Apache App](./apache-hello/hello-apache-app.png)
  3. **Kubernetes Dashboard**: Acesse https://domain.local:30002/
     - Token de acesso: `/home/vagrant/playground/dash-token` na VM
     - ![Kubernetes Dashboard](./kubernetes-dashboard/kube-dashboard.png)

- **Somente terminal (sem GUI):**
  1. Acesse a VM com `vagrant ssh`
  2. **Teste Hello Apache App**:
     ```sh
     curl -v http://domain.local:30001/hello-apache/
     ```
     
## Referências

- [Kind - Kubernetes IN Docker](https://kind.sigs.k8s.io/)
- [Ingress Nginx Controller](https://kubernetes.github.io/ingress-nginx/)
- [Vagrant](https://www.vagrantup.com/)
- [Prometheus](https://prometheus.io/)
- [Grafana](https://grafana.com/)
- [Jaeger](https://www.jaegertracing.io/)
- Projeto inspirado em: [README.md original de mascosta](https://github.com/mascosta/docs/blob/main/kind-ingress-nginx/README.md)
