#!/bin/bash
echo "[Begin] Bootstrap script."
sudo apt update && \
sudo apt install -y apt-transport-https

pushd ./playground/installers 
./configure-docker-daemon.sh
./install-kind.sh
./install-kubectl.sh
popd

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

# Add repositories to helm.
echo "[Begin] Add repositories to helm."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add runix https://helm.runix.net
helm repo add harbor https://helm.goharbor.io
# helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update
echo "[End] Add repositories to helm."

# Install stack observability.
echo "[Begin] Install stack observability."
pushd ./playground/observability
./install-observability.sh
popd
echo "[End] Install stack observability."

Install harbor.
echo "[Begin] Install harbor."
sudo bash -c 'echo "127.0.0.1 core.harbor.domain" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 notary.harbor.domain" >> /etc/hosts'
kubectl create namespace harbor
helm install harbor harbor/harbor --namespace harbor --values /home/vagrant/playground/harbor/values.yaml
 echo "[End] Install harbor."

# TODO: Install nexus.
# echo "[Begin] Install nexus."
# kubectl create namespace nexus
# helm install nexus sonatype/nxrm-ha --namespace nexus \
#     --set nexus.ingress.enabled=true \
#     --set nexus.ingress.className=nginx \
#     --set nexus.env[0].name=INSTALL4J_ADD_VM_PARAMS \
#     --set nexus.env[0].value="-Xms512m -Xmx1024m" \
#     --set nexus.resources.requests.memory=512Mi \
#     --set nexus.resources.requests.cpu=250m \
#     --set nexus.resources.limits.memory=1Gi \
#     --set nexus.resources.limits.cpu=500m \
#     --set persistence.size=5Gi
# echo "[End] Install nexus."

# Install quay.
# echo "[Begin] Install quay."
# kubectl create namespace quay
# helm install quay redhat-cop/quay --namespace quay
# echo "[End] Install quay."

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
