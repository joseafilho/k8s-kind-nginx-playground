#!/bin/bash

# Script to generate Terraform configuration dynamically
# Usage: ./generate-config.sh --instance-type t3a.medium --region us-east-1 --key-name my-key

set -e

# Default values
INSTANCE_TYPE="t3a.medium"
REGION="us-east-1"
KEY_NAME=""
VOLUME_SIZE=50
SUBNET_ID=""
SECURITY_GROUP_ID=""
AMI_ID=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --instance-type TYPE    AWS instance type (default: t3a.medium)"
    echo "  --region REGION         AWS region (default: us-east-1)"
    echo "  --key-name KEY          AWS key pair name (required)"
    echo "  --volume-size GB        EBS volume size in GB (default: 50)"
    echo "  --ami-id AMI            AWS AMI ID (optional, uses data source if not specified)"
    echo "  --subnet-id SUBNET      AWS subnet ID (optional)"
    echo "  --security-group SG     AWS security group ID (optional)"
    echo "  --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --instance-type t3a.large --key-name my-key"
    echo "  $0 --instance-type t3a.xlarge --region us-west-2 --key-name my-key"
    echo "  $0 --instance-type t3a.medium --ami-id ami-12345 --key-name my-key"
}

# Function to validate parameters
validate_parameters() {
    if [ -z "$KEY_NAME" ]; then
        echo "❌ Error: --key-name is required"
        show_usage
        exit 1
    fi
    
    # Validate instance type
    case $INSTANCE_TYPE in
        t3a.medium|t3a.large|t3a.xlarge|t3a.2xlarge)
            ;;
        *)
            echo "❌ Error: Invalid instance type. Must be t3a.medium, t3a.large, t3a.xlarge, or t3a.2xlarge"
            exit 1
            ;;
    esac
    
    # Validate volume size
    if [ "$VOLUME_SIZE" -lt 20 ] || [ "$VOLUME_SIZE" -gt 1000 ]; then
        echo "❌ Error: Volume size must be between 20 and 1000 GB"
        exit 1
    fi
}

# Função para limpar arquivos e diretórios gerados pelo script
clean_generated_files() {
    echo "🧹 Limpando arquivos e diretórios gerados..."

    # Lista de arquivos gerados
    FILES=("main.tf" "variables.tf" "terraform.tfvars" "user_data.sh" ".terraform.lock.hcl")

    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "  - Removido: $file"
        fi
    done

    # Limpa diretórios temporários se existirem (exemplo: .terraform)
    if [ -d ".terraform" ]; then
        rm -rf .terraform
        echo "  - Removido diretório: .terraform"
    fi

    # Limpa arquivos de estado do Terraform, se existirem
    for state_file in terraform.tfstate terraform.tfstate.backup; do
        if [ -f "$state_file" ]; then
            rm -f "$state_file"
            echo "  - Removido: $state_file"
        fi
    done

    echo "✅ Limpeza concluída!"
}

# Function to generate main.tf
generate_main_tf() {
    echo "📝 Generating main.tf..."
    
    cat > main.tf << EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  required_version = ">= 1.0"
}

provider "aws" {
  region = "${REGION}"
  
  default_tags {
    tags = {
      Project     = "k8s-playground"
      Environment = "development"
      ManagedBy   = "terraform"
    }
  }
}

# VPC and networking
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }
}

# Security group for K8S Playground
resource "aws_security_group" "k8s_playground" {
  name_prefix = "k8s-playground-"
  vpc_id      = data.aws_vpc.default.id
  description = "Security group for K8S Playground"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # K8S services ports
  ingress {
    from_port   = 30001
    to_port     = 30002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K8S services (Harbor, Dashboard, etc.)"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "k8s-playground-sg"
  }
}

# Data source for Ubuntu AMI (only used if ami_id is not specified)
data "aws_ami" "ubuntu" {
  count = var.ami_id == null ? 1 : 0
  
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# EC2 instance
resource "aws_instance" "k8s_playground" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type = "${INSTANCE_TYPE}"
  key_name      = "${KEY_NAME}"
  subnet_id     = data.aws_subnet.default.id

  vpc_security_group_ids = [aws_security_group.k8s_playground.id]

  root_block_device {
    volume_size = ${VOLUME_SIZE}
    volume_type = "gp3"
    encrypted   = true
    
    tags = {
      Name = "k8s-playground-root"
    }
  }

  user_data = base64encode(templatefile("\${path.module}/user_data.sh", {
    instance_type = "${INSTANCE_TYPE}"
    region        = "${REGION}"
  }))

  monitoring = true

  tags = {
    Name = "k8s-playground"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for persistent public IP
resource "aws_eip" "k8s_playground" {
  instance = aws_instance.k8s_playground.id
  domain   = "vpc"

  tags = {
    Name = "k8s-playground-eip"
  }
}

# Outputs
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.k8s_playground.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k8s_playground.id
}

output "instance_type" {
  description = "Type of the EC2 instance"
  value       = aws_instance.k8s_playground.instance_type
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@\${aws_eip.k8s_playground.public_ip}"
}

output "access_urls" {
  description = "Access URLs for K8S Playground services"
  value = {
    ssh            = "ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@\${aws_eip.k8s_playground.public_ip}"
    hello_apache   = "http://\${aws_eip.k8s_playground.public_ip}:30001/hello-apache/"
    k8s_dashboard  = "https://\${aws_eip.k8s_playground.public_ip}:30002/"
    harbor         = "http://\${aws_eip.k8s_playground.public_ip}:30001/"
    pgadmin        = "http://\${aws_eip.k8s_playground.public_ip}:30001/"
    grafana        = "http://\${aws_eip.k8s_playground.public_ip}:30001/"
    jaeger         = "http://\${aws_eip.k8s_playground.public_ip}:30001/"
  }
}

output "setup_instructions" {
  description = "Instructions to setup K8S Playground"
  value = <<-EOT
    ==========================================
    ✅ AWS deployment completed!
    ==========================================
    
    📋 Next steps:
    1. SSH into the instance:
       ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@\${aws_eip.k8s_playground.public_ip}
    
    2. Clone the repository:
       git clone <your-repo-url>
       cd k8s-kind-nginx
    
    3. Run the bootstrap script:
       ./bootstrap.sh
    
    🔗 Access URLs:
    - Hello Apache: http://\${aws_eip.k8s_playground.public_ip}:30001/hello-apache/
    - K8S Dashboard: https://\${aws_eip.k8s_playground.public_ip}:30002/
    - Harbor Registry: http://\${aws_eip.k8s_playground.public_ip}:30001/
    - pgAdmin: http://\${aws_eip.k8s_playground.public_ip}:30001/
    - Grafana: http://\${aws_eip.k8s_playground.public_ip}:30001/
    - Jaeger: http://\${aws_eip.k8s_playground.public_ip}:30001/
    
    🗑️  To destroy: terraform destroy
    ==========================================
  EOT
}
EOF

    echo "✅ main.tf generated!"
}

# Function to generate terraform.tfvars
generate_tfvars() {
    echo "📝 Generating terraform.tfvars..."
    
    cat > terraform.tfvars << EOF
# Generated by generate-config.sh
aws_region = "${REGION}"
instance_type = "${INSTANCE_TYPE}"
key_name = "${KEY_NAME}"
volume_size = ${VOLUME_SIZE}
EOF

    if [ -n "$AMI_ID" ]; then
        echo "ami_id = \"${AMI_ID}\"" >> terraform.tfvars
    fi

    if [ -n "$SUBNET_ID" ]; then
        echo "subnet_id = \"${SUBNET_ID}\"" >> terraform.tfvars
    fi
    
    if [ -n "$SECURITY_GROUP_ID" ]; then
        echo "security_group_ids = [\"${SECURITY_GROUP_ID}\"]" >> terraform.tfvars
    fi

    echo "✅ terraform.tfvars generated!"
}

# Function to generate variables.tf
generate_variables_tf() {
    echo "📝 Generating variables.tf..."
    
    cat > variables.tf << EOF
variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "${REGION}"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "${INSTANCE_TYPE}"
  
  validation {
    condition     = can(regex("^t3a\\\\.(medium|large|xlarge|2xlarge)$", var.instance_type))
    error_message = "Instance type must be t3a.medium, t3a.large, t3a.xlarge, or t3a.2xlarge."
  }
}

variable "key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
  default     = "${KEY_NAME}"
  
  validation {
    condition     = length(var.key_name) > 0
    error_message = "Key name must not be empty."
  }
}

variable "volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = ${VOLUME_SIZE}
  
  validation {
    condition     = var.volume_size >= 20 && var.volume_size <= 1000
    error_message = "Volume size must be between 20 and 1000 GB."
  }
}

variable "subnet_id" {
  description = "Subnet ID to deploy the instance (optional, uses default if not specified)"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs (optional, creates new one if not specified)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "k8s-playground"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for the EC2 instance"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption for the EBS volume"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance (optional, uses data source if not specified)"
  type        = string
  default     = null
}
EOF

    echo "✅ variables.tf generated!"
}

# Function to generate user_data.sh
generate_user_data() {
    echo "📝 Generating user_data.sh..."
    
    cat > user_data.sh << 'EOF'
#!/bin/bash

# User data script for K8S Playground EC2 instance
# This script runs when the instance first boots

set -e

# Update system
echo "🔄 Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    tree \
    vim \
    nano

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install AWS CLI v2
echo "☁️  Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install Terraform
echo "🏗️  Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y terraform

# Install kubectl
echo "☸️  Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
echo "⚓ Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Create directories
echo "📁 Creating directories..."
mkdir -p /home/ubuntu/playground
mkdir -p /home/ubuntu/.ssh
mkdir -p /home/ubuntu/.kube

# Set permissions
chown -R ubuntu:ubuntu /home/ubuntu/playground
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Create welcome message
cat > /home/ubuntu/welcome.txt << 'WELCOME_EOF'
==========================================
🚀 K8S Playground - AWS Instance Ready!
==========================================

📋 Instance Details:
- Instance Type: ${instance_type}
- Region: ${region}
- Ubuntu 22.04 LTS
- Docker installed and running
- AWS CLI v2 installed
- Terraform installed
- kubectl installed
- Helm installed

📁 Next Steps:
1. Clone your repository:
   git clone <your-repo-url>
   cd k8s-kind-nginx

2. Run the bootstrap script:
   ./bootstrap.sh

3. Access your services:
   - Hello Apache: http://<PUBLIC_IP>:30001/hello-apache/
   - K8S Dashboard: https://<PUBLIC_IP>:30002/
   - Harbor: http://<PUBLIC_IP>:30001/
   - pgAdmin: http://<PUBLIC_IP>:30001/
   - Grafana: http://<PUBLIC_IP>:30001/
   - Jaeger: http://<PUBLIC_IP>:30001/

🔧 Useful Commands:
- Check Docker: docker --version
- Check kubectl: kubectl version
- Check Helm: helm version
- Check AWS CLI: aws --version
- Check Terraform: terraform --version

📊 System Info:
- Check system resources: htop
- Check disk usage: df -h
- Check memory: free -h

==========================================
WELCOME_EOF

# Set welcome message permissions
chown ubuntu:ubuntu /home/ubuntu/welcome.txt

# Create system info script
cat > /home/ubuntu/system-info.sh << 'SYSINFO_EOF'
#!/bin/bash
echo "=========================================="
echo "🔍 K8S Playground System Information"
echo "=========================================="
echo ""
echo "📊 System Resources:"
echo "  - CPU: $(nproc) cores"
echo "  - Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  - Disk: $(df -h / | tail -1 | awk '{print $2}')"
echo ""
echo "🐳 Docker Status:"
docker --version
docker info | grep -E "(Containers|Images|Storage Driver)"
echo ""
echo "☸️  Kubernetes Tools:"
kubectl version --client
helm version
echo ""
echo "☁️  AWS Tools:"
aws --version
terraform --version
echo ""
echo "📁 Directories:"
ls -la /home/ubuntu/
echo ""
echo "=========================================="
SYSINFO_EOF

chmod +x /home/ubuntu/system-info.sh
chown ubuntu:ubuntu /home/ubuntu/system-info.sh

# Create environment setup script
cat > /home/ubuntu/setup-k8s-playground.sh << 'SETUP_EOF'
#!/bin/bash
echo "🚀 Setting up K8S Playground..."

# Clone repository (replace with your actual repo URL)
# git clone https://github.com/your-username/k8s-kind-nginx.git
# cd k8s-kind-nginx

# Run bootstrap script
# ./bootstrap.sh

echo "✅ Setup script ready!"
echo "📋 Please:"
echo "  1. Clone your repository"
echo "  2. Run ./bootstrap.sh"
echo "  3. Access your services"
SETUP_EOF

chmod +x /home/ubuntu/setup-k8s-playground.sh
chown ubuntu:ubuntu /home/ubuntu/setup-k8s-playground.sh

# Display welcome message
echo "=========================================="
echo "✅ K8S Playground instance setup completed!"
echo "=========================================="
echo ""
echo "📋 Instance is ready for K8S Playground deployment"
echo "🔗 SSH into the instance to continue setup"
echo ""
echo "📊 Run system-info.sh to check system status"
echo "🚀 Run setup-k8s-playground.sh to start deployment"
echo "=========================================="

# Reboot to ensure all changes take effect
echo "🔄 Rebooting in 30 seconds to apply all changes..."
sleep 30
reboot
EOF

    echo "✅ user_data.sh generated!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --key-name)
            KEY_NAME="$2"
            shift 2
            ;;
        --volume-size)
            VOLUME_SIZE="$2"
            shift 2
            ;;
        --subnet-id)
            SUBNET_ID="$2"
            shift 2
            ;;
        --security-group)
            SECURITY_GROUP_ID="$2"
            shift 2
            ;;
        --ami-id)
            AMI_ID="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
echo "=========================================="
echo "🔧 Terraform Configuration Generator"
echo "=========================================="

validate_parameters
clean_generated_files
generate_main_tf
generate_variables_tf
generate_user_data
generate_tfvars

echo ""
echo "✅ Configuration generated successfully!"
echo ""
echo "📋 Generated files:"
echo "  - main.tf"
echo "  - variables.tf"
echo "  - user_data.sh"
echo "  - terraform.tfvars"
echo ""
echo "🚀 Next steps:"
echo "  1. terraform init"
echo "  2. terraform plan"
echo "  3. terraform apply"
echo ""
echo "==========================================" 