#!/bin/bash

# IF condition
./installers/configure-docker-daemon.sh
./installers/configure-hosts.sh
./installers/kind-install.sh user-name
./installers/kubectl-install.sh user-name
./installers/helm-install.sh
# End IF

./installers/cilium-install.sh
./installers/kubectl-top-install.sh
./installers/ingress-controller-install.sh --local-debug
./installers/kube-dash-install.sh --local-debug
./installers/apache-hello-install.sh --local-debug
./installers/harbor-install.sh --local-debug
./installers/postgres-install.sh --local-debug
./installers/ecom-python-install.sh --local-debug
./installers/observability-install.sh --local-debug