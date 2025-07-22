# k8s-kind-nginx-playground

K8S Playground usando Kind com Ingress Nginx.

## Descrição

Este projeto tem como objetivo fornecer um ambiente de testes local para Kubernetes utilizando o Kind (Kubernetes IN Docker) e o Ingress Nginx. Ele inclui exemplos de deployment, service, configmap e ingress para uma aplicação simples em Apache.

## Pré-requisitos

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) (ou outro provider compatível com Vagrant)

## Estrutura do Projeto

```
.
├── apache-hello/
│   ├── hello-apache-app.png        # Exemplo visual da aplicação Apache
│   ├── hello-apache-cm.yaml        # ConfigMap para o Apache
│   ├── hello-apache-dpl.yaml       # Deployment do Apache
│   ├── hello-apache-ing.yaml       # Ingress para expor o serviço Apache
│   └── hello-apache-svc.yaml       # Service para o Apache
├── ingress-nginx/
│   └── ingress.yaml                # Configuração do Ingress Nginx
├── kubernetes-dashboard/
│   ├── kube-dashboard.png          # Exemplo visual do Dashboard
│   ├── dash-ing.yaml               # Ingress para o Dashboard
│   └── dash-admin.yaml             # ServiceAccount e permissões para o Dashboard
├── bootstrap.sh                    # Script de bootstrap para provisionamento
├── Vagrantfile                     # Arquivo de configuração do Vagrant
└── README.md                       # Este arquivo
```

## Variáveis de Ambiente para Personalização da VM

| Variável             | Valor Esperado | Efeito                                                                 |
|----------------------|:--------------:|------------------------------------------------------------------------|
| WITH_GUI             | "1" ou vazio   | Se "1", instala interface gráfica (Xubuntu Core + LightDM) na VM.      |
| INSTALL_BROWSER      | "1" ou vazio   | Se "1", instala o navegador Firefox na VM.                             |
| SETUP_KIND_K8S       | "1" ou vazio   | Se "1", copia os arquivos do projeto e executa o script bootstrap.sh.  |

## Como usar

1. **Clone o repositório:**
   ```sh
   git clone git@github.com:joseafilho/k8s-kind-nginx-playground.git
   cd k8s-kind-nginx-playgroud
   ```

2. **Suba o ambiente com Vagrant:**
   
   - **Com interface gráfica:**
     ```sh
     WITH_GUI=1 INSTALL_BROWSER=1 vagrant up
     ```
     Ao final da instalação, execute:
     ```sh
     SETUP_KIND_K8S=1 vagrant reload --provision
     ```
   
   - **Somente terminal (sem GUI):**
     ```sh
     SETUP_KIND_K8S=1 vagrant up
     ```
     Acesso a máquina virtual via ssh:**
     ```sh
     vagrant ssh
     ```
   
   - * *Com interface gráfica(Rodando somente um comando) - Em Teste:* *
     ```sh
     ./create-enviroment-gui.sh
     ```

## Validação de Funcionamento

- **Com interface gráfica (GUI):**
  1. Após acessar a máquina virtual via VirtualBox, abra o navegador Firefox instalado na VM.
  2. Acesse o endereço: http://domain.local:30001/hello-apache/.
  3. Você deve ver a página de boas-vindas do Hello Apache App.
  4. Exemplo do resultado esperado:
     ![Exemplo Hello Apache App](./apache-hello/hello-apache-app.png)
  5. Em outra aba acesse o endereço: https://domain.local:30002/
  6. Você deve ver a página do Kubernetes Dashboard.
     ![Kubernetes Dashboard](./kubernetes-dashboard/kube-dashboard.png)

- **Somente terminal (sem GUI):**
  1. Após acessar a máquina virtual com `vagrant ssh`, utilize o comando:
     ```sh
     curl -v http://domain.local:30001/hello-apache/
     ```
  2. O retorno deve conter o conteúdo HTML da página de boas-vindas do Hello Apache App.

## Observações

- Certifique-se de que as portas necessárias estejam liberadas no seu ambiente.
- O Ingress Nginx será exposto conforme definido no arquivo `ingress-nginx/ingress.yaml`.
- Para acessar a aplicação, utilize o endereço configurado no Ingress após a criação dos recursos.

## Referências

- [Kind - Kubernetes IN Docker](https://kind.sigs.k8s.io/)
- [Ingress Nginx Controller](https://kubernetes.github.io/ingress-nginx/)
- Projeto inspirado em: [README.md original de mascosta](https://github.com/mascosta/docs/blob/main/kind-ingress-nginx/README.md)
