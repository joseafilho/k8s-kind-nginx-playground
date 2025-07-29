#!/bin/bash

# Script to create environment without GUI with named parameters
# Usage: ./create-environment-without-gui.sh --memory 4096 --cpus 2

set -e

# Default values
MEMORY=4096
CPUS=2

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --memory MB             Memory in MB (default: 4096)"
    echo "  --cpus NUM              Number of CPUs (default: 2)"
    echo "  --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --memory 8192 --cpus 4"
    echo "  $0 --memory 2048 --cpus 1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

echo "=========================================="
echo "Creating Environment Without GUI"
echo "=========================================="
echo "Memory: ${MEMORY}MB"
echo "CPUs: ${CPUS}"
echo "=========================================="

echo "🛑 Stopping and destroying existing VM..."
vagrant halt
vagrant destroy -f
sleep 2

echo "🚀 Creating new VM..."
vagrant up
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
echo "  - Memory: ${MEMORY}MB"
echo "  - CPUs: ${CPUS}"
echo "  - Kind/K8s: Installed and configured"
echo "=========================================="