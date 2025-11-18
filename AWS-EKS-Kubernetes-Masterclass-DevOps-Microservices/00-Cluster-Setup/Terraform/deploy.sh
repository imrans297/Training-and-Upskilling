#!/bin/bash

# EKS Cluster Deployment Script
set -e

echo "🚀 Starting EKS Cluster Deployment..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &>/dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &>/dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create EC2 Key Pair if it doesn't exist
echo "🔑 Checking/Creating EC2 Key Pair..."
chmod +x create-keypair.sh
./create-keypair.sh

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Apply the configuration
echo "🏗️  Deploying EKS cluster..."
terraform apply tfplan

# Configure kubectl
echo "⚙️  Configuring kubectl..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
AWS_REGION=$(terraform output -raw aws_region || echo "ap-south-1")
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# Verify cluster
echo "✅ Verifying cluster..."
kubectl get nodes
kubectl get namespaces

echo "🎉 EKS Cluster deployment completed successfully!"
echo "📝 Cluster details:"
terraform output