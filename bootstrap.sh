#!/bin/bash
echo "[Begin] Bootstrap script."
sudo apt update && \
sudo apt install -y apt-transport-https

# Install kind.
echo "==> [Begin] Installing kind."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version
echo "==> [End] Installing kind."

# Create kind configuration file.
cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster1
nodes:
- role: control-plane
  extraPortMappings: # Ports to be exposed from the cluster
  - containerPort: 30001
    hostPort: 30001
  - containerPort: 30002
    hostPort: 30002
- role: worker
- role: worker
networking:
  disableDefaultCNI: true # Disable the default CNI plugin
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.245.0.0/16"
EOF
sudo chown vagrant:vagrant kind-config.yaml

# Create cluster.
echo "==> [Begin] Create cluster."
kind create cluster --name k8s-nginx --config kind-config.yaml
echo "==> [End] Create cluster."

# Install kubectl.
echo "==> [Begin] Installing kubectl."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version
echo "==> [End] Installing kubectl."

# Configure kubectl to use kind cluster.
echo "[Begin] Configuring kubectl to use kind cluster."
mkdir .kube/
sudo chown -R vagrant:vagrant .kube/
kind get kubeconfig --name k8s-nginx > .kube/config
echo "[End] Configuring kubectl to use kind cluster."

# Validating kubectl installation.
echo "==> [Begin] Validating kubectl installation."
kubectl cluster-info
kubectl get nodes
echo "==> [End] Validating kubectl installation."

# Install helm.
echo "==> [Begin] Install helm."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
helm version
rm get_helm.sh
echo "==> [End] Install helm."

# Install Cilium.
echo "==> [Begin] Install Cilium."
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
cilium install --version=$(curl -s https://raw.githubusercontent.com/cilium/cilium/refs/heads/main/stable.txt)
kubectl get pods -A
cilium version
cilium status --wait
echo "==> [End] Install Cilium."

# Config /etc/hosts.
echo "[Begin] Config /etc/hosts."
sudo bash -c 'echo "127.0.0.1 domain.local" >> /etc/hosts'
echo "[End] Config /etc/hosts."

# Create ingress controller.
echo "[Begin] Create ingress controller."
kubectl apply -f /home/vagrant/playground/ingress-nginx/ingress.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
echo "[End] Create ingress controller."

# Create namespaces.
echo "[Begin] Create namespaces."
kubectl create namespace ns1
echo "[End] Create namespaces."

# Create apache hello.
echo "[Begin] Create apache hello."
kubectl apply -f /home/vagrant/playground/apache-hello/hello-apache-cm.yaml
kubectl apply -f /home/vagrant/playground/apache-hello/hello-apache-dpl.yaml
kubectl apply -f /home/vagrant/playground/apache-hello/hello-apache-svc.yaml
kubectl apply -f /home/vagrant/playground/apache-hello/hello-apache-ing.yaml
echo "[End] Create apache hello."

# Install kubernetes dashboard.
echo "[Begin] Install kubernetes dashboard."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl apply -f /home/vagrant/playground/kubernetes-dashboard/dash-admin.yaml
kubectl -n kubernetes-dashboard create token admin-user; echo
kubectl apply -f /home/vagrant/playground/kubernetes-dashboard/dash-ing.yaml

echo "*************************."
echo "==> Token to access kubernetes dashboard."
echo "*************************."
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d >> ./playground/dash-token; echo
cat ./playground/dash-token; echo
echo "*************************."
echo "[End] Install kubernetes dashboard."

# Add repository to helm.
echo "[Begin] Add repository to helm."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
echo "[End] Add repository to helm."

# Install postgres.
echo "[Begin] Install postgres."
kubectl create namespace postgresql
helm install postgres-17 bitnami/postgresql --namespace postgresql --set image.tag=17.5.0

echo "*************************."
echo "==> Password to access postgres." 
echo "*************************."
kubectl get secret --namespace postgresql postgres-17-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d; echo
echo "*************************."
echo "[End] Install postgres."

# Install pgadmin.
echo "[Begin] Install pgadmin."
sudo bash -c 'echo "127.0.0.1 pgadmin.local" >> /etc/hosts'
helm repo add runix https://helm.runix.net
helm repo update
helm install pgadmin runix/pgadmin4 --set env.email=admin@admin.com --set env.password=admin-user --set service.type=ClusterIP --namespace postgresql
kubectl apply -f /home/vagrant/playground/pgadmin/pgadmin-ing.yaml
echo "[End] Install pgadmin."

# Deploy ecom-python.
echo "[Begin] Deploy ecom-python."
sudo bash -c 'echo "127.0.0.1 ecom-python.local" >> /etc/hosts'
docker build -t ecom-python-api:latest -f /home/vagrant/playground/projects/ecom-python/Dockerfile /home/vagrant/playground/projects/ecom-python
kind load docker-image ecom-python-api:latest --name k8s-nginx
export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgresql postgres-17-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl run postgres-17-postgresql-client --rm --tty -i --restart='Never' --namespace postgresql --image docker.io/bitnami/postgresql:17.5.0 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host postgres-17-postgresql -U postgres -d postgres -p 5432 -c "CREATE DATABASE ecom_python;"
kubectl apply -f /home/vagrant/playground/projects/ecom-python/infra/namespace.yaml
envsubst < /home/vagrant/playground/projects/ecom-python/infra/deployment.yaml | kubectl apply -f - 
kubectl apply -f /home/vagrant/playground/projects/ecom-python/infra/service.yaml
kubectl apply -f /home/vagrant/playground/projects/ecom-python/infra/ingress.yaml
echo "[End] Deploy ecom-python."