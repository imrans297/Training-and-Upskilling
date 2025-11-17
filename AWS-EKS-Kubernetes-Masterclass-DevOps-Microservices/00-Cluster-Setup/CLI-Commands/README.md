# Shared EKS Cluster - CLI Commands

## Overview
Complete command-line setup for the shared EKS cluster used throughout all training sections.

## Prerequisites
- AWS CLI configured
- eksctl installed
- kubectl installed

## One-Time Cluster Creation

### Method 1: Using eksctl (Recommended)
```bash
# Create cluster with node group
eksctl create cluster \
  --name training-cluster \
  --region ap-south-1 \
  --zones ap-south-1a,ap-south-1b \
  --nodegroup-name training-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed \
  --tags Owner=imran.shaikh@einfochips.com,Project="Internal POC",DM="Shahid Raza",Department=PES-Digital,Environment=learning,ENDDate=30-11-2025,ManagedBy=eksctl

# Associate OIDC provider
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster training-cluster \
  --approve
```

### Method 2: Step by Step
```bash
# 1. Create cluster (control plane only)
eksctl create cluster \
  --name training-cluster \
  --region ap-south-1 \
  --zones ap-south-1a,ap-south-1b \
  --without-nodegroup \
  --tags Owner=imran.shaikh@einfochips.com,Project="Internal POC"

# 2. Create managed node group
eksctl create nodegroup \
  --cluster training-cluster \
  --region ap-south-1 \
  --name training-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed \
  --ssh-access \
  --ssh-public-key training-key

# 3. Associate OIDC provider
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster training-cluster \
  --approve
```

## Configure kubectl
```bash
# Update kubeconfig
aws eks update-kubeconfig --region ap-south-1 --name training-cluster

# Verify connection
kubectl get nodes
kubectl cluster-info
```

## Create Namespaces for All Sections
```bash
# Create all training namespaces
kubectl create namespace docker-fundamentals
kubectl create namespace k8s-imperative
kubectl create namespace k8s-declarative
kubectl create namespace pod-identity
kubectl create namespace storage-ebs
kubectl create namespace secrets-probes
kubectl create namespace storage-rds
kubectl create namespace loadbalancers
kubectl create namespace alb-controller
kubectl create namespace ingress-basics
kubectl create namespace ingress-context-path
kubectl create namespace ingress-host-header
kubectl create namespace ingress-groups
kubectl create namespace ingress-target-ip
kubectl create namespace ingress-internal
kubectl create namespace ecr-integration
kubectl create namespace microservices
kubectl create namespace hpa-autoscaler
kubectl create namespace vpa-autoscaler
kubectl create namespace cluster-autoscaler
kubectl create namespace container-insights

# Verify namespaces
kubectl get namespaces
```

## Install Essential Add-ons
```bash
# Install AWS Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster=training-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install controller via Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=training-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Install EBS CSI Driver
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster training-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole

eksctl create addon --name aws-ebs-csi-driver --cluster training-cluster --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole --force
```

## Daily Usage Commands
```bash
# Switch to section namespace
kubectl config set-context --current --namespace=k8s-imperative

# Check current namespace
kubectl config view --minify | grep namespace

# List resources in namespace
kubectl get all

# Clean up section resources (keep cluster)
kubectl delete all --all -n k8s-imperative
```

## Cluster Management
```bash
# Check cluster status
eksctl get cluster --region ap-south-1

# Scale node group
eksctl scale nodegroup --cluster=training-cluster --nodes=3 --name=training-nodes

# Update cluster
eksctl update cluster --name=training-cluster --region=ap-south-1

# Get cluster info
kubectl cluster-info
kubectl get nodes -o wide
```

## Cleanup (End of Training)
```bash
# Delete cluster and all resources
eksctl delete cluster --name training-cluster --region ap-south-1

# Verify deletion
aws eks list-clusters --region ap-south-1
```