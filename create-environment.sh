#!/bin/bash

# Unified script to create environment with or without GUI
# Usage: ./create-environment.sh --gui --memory 8192 --cpus 4
# Usage: ./create-environment.sh --no-gui --memory 4096 --cpus 2

set -e

# Default values
MEMORY=4096
CPUS=2
GUI=false
WITH_GUI=""
INSTALL_BROWSER=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --gui                   Install environment with GUI (Xubuntu + Firefox)"
    echo "  --no-gui                Install environment without GUI (terminal only)"
    echo "  --memory MB             Memory in MB (default: 4096)"
    echo "  --cpus NUM              Number of CPUs (default: 2)"
    echo "  --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --gui --memory 8192 --cpus 4"
    echo "  $0 --no-gui --memory 2048 --cpus 1"
    echo "  $0 --gui"
    echo "  $0 --no-gui"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --gui)
            GUI=true
            WITH_GUI="1"
            INSTALL_BROWSER="1"
            shift
            ;;
        --no-gui)
            GUI=false
            WITH_GUI=""
            INSTALL_BROWSER=""
            shift
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --cpus)
            CPUS="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ "$GUI" != true ] && [ "$GUI" != false ]; then
    echo "❌ Error: You must specify either --gui or --no-gui"
    show_usage
    exit 1
fi

echo "=========================================="
echo "Creating Unified Environment"
echo "=========================================="
echo "GUI Mode: $([ "$GUI" = true ] && echo "Enabled" || echo "Disabled")"
echo "Memory: ${MEMORY}MB"
echo "CPUs: ${CPUS}"
echo "=========================================="

echo "🛑 Stopping and destroying existing VM..."
vagrant halt
vagrant destroy -f
sleep 2

echo "🚀 Creating new VM..."
if [ "$GUI" = true ]; then
    echo "📺 Installing with GUI (Xubuntu + Firefox)..."
    WITH_GUI=1 INSTALL_BROWSER=1 vagrant up
else
    echo "💻 Installing without GUI (terminal only)..."
    vagrant up
fi
sleep 2

echo "⏸️  Stopping VM for configuration..."
vagrant halt
sleep 2

echo "⚙️  Configuring VM resources..."
VM_NAME=$(VBoxManage list vms | grep "kind-nginx" | awk -F\" '{print $2}')
VBoxManage modifyvm $VM_NAME --memory $MEMORY --cpus $CPUS

echo "🔄 Reloading VM with Kind/K8s setup..."
SETUP_KIND_K8S=1 vagrant reload --provision

echo ""
echo "=========================================="
echo "✅ Environment created successfully!"
echo "=========================================="
echo "VM Configuration:"
echo "  - GUI Mode: $([ "$GUI" = true ] && echo "Enabled" || echo "Disabled")"
echo "  - Memory: ${MEMORY}MB"
echo "  - CPUs: ${CPUS}"
echo "  - Kind/K8s: Installed and configured"
echo ""
if [ "$GUI" = true ]; then
    echo "🌐 Access URLs (after VM is ready):"
    echo "  - Hello Apache: http://domain.local:30001/hello-apache/"
    echo "  - Kubernetes Dashboard: https://domain.local:30002/"
    echo "  - Harbor Registry: http://core.harbor.domain:30001/"
    echo "  - pgAdmin: http://pgadmin.local:30001/"
    echo "  - Grafana: http://grafana.local:30001/"
    echo "  - Jaeger: http://jaeger.local:30001/"
else
    echo "💻 Terminal Access:"
    echo "  - SSH: vagrant ssh"
    echo "  - Test: curl http://domain.local:30001/hello-apache/"
fi
echo "==========================================" 