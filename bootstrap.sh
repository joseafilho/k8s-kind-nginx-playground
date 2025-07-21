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
sudo bash -c 'echo "127.0.0.1  domain.local" >> /etc/hosts'
echo "[End] Config /etc/hosts."

# Create ingress controller.
echo "[Begin] Create ingress controller."
kubectl apply -f /home/vagrant/ingress-nginx/ingress.yaml
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
kubectl apply -f /home/vagrant/apache-hello/hello-apache-cm.yaml
kubectl apply -f /home/vagrant/apache-hello/hello-apache-dpl.yaml
kubectl apply -f /home/vagrant/apache-hello/hello-apache-svc.yaml
kubectl apply -f /home/vagrant/apache-hello/hello-apache-ing.yaml
echo "[End] Create apache hello."
