# EKS Infrastructure Setup

**Created by:** Imran Shaikh  
**Region:** us-east-1  
**Purpose:** GitOps-ready EKS cluster for application deployment

---

## Infrastructure Overview

This Terraform configuration creates:
- **EKS Cluster** (Kubernetes 1.31)
- **VPC** with public and private subnets
- **NAT Gateway** for private subnet internet access
- **Node Group** with t3.small instances (2 nodes)
- **IAM Roles** for EKS cluster and nodes

## Cost Estimate

| Resource | Monthly Cost |
|----------|--------------|
| EKS Control Plane | ~$73 |
| t3.small instances (2x) | ~$30 |
| NAT Gateway | ~$32 |
| **Total** | **~$135/month** |

**Note:** EKS is NOT free tier eligible. Consider using minikube or kind for local development.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- kubectl installed

## Deployment Steps

### 1. Initialize Terraform
```bash
cd 1EKS-infra-setup
terraform init
```

### 2. Review Plan
```bash
terraform plan
```

### 3. Deploy Infrastructure
```bash
terraform apply -auto-approve
```

### 4. Configure kubectl
```bash
aws eks update-kubeconfig --region us-east-1 --name gitops-eks-cluster
```

### 5. Verify Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.1.0/24, 10.0.2.0/24)
│   ├── Internet Gateway
│   └── NAT Gateway
└── Private Subnets (10.0.10.0/24, 10.0.11.0/24)
    └── EKS Node Group (t3.small x2)
        └── Application Pods
```

## Configuration

### Default Values
- **Cluster Name:** gitops-eks-cluster
- **Kubernetes Version:** 1.31
- **Instance Type:** t3.small
- **Node Count:** 2 (min: 1, max: 3)
- **AMI:** AL2023 (Amazon Linux 2023)

### Customization
Edit `variables.tf` to change:
- Instance types
- Node count
- Cluster name
- VPC CIDR

## Cleanup

To destroy all resources:
```bash
terraform destroy -auto-approve
```

**Important:** Delete any LoadBalancers created by Kubernetes before destroying!

---

**Status:** Ready for ArgoCD deployment
