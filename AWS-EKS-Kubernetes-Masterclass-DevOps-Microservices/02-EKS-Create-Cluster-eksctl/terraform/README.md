# EKS Cluster - Terraform Infrastructure

## Purpose
Create production-ready EKS cluster infrastructure using Terraform with best practices.

## What We're Creating
- Custom VPC with public/private subnets across 3 AZs
- EKS cluster with managed node groups
- Security groups restricted to your IP
- Essential cluster add-ons

## What We'll Achieve
- Automated, repeatable infrastructure
- Secure cluster with restricted access
- Production-ready configuration
- Easy to manage and update

## Prerequisites
- Terraform installed (v1.0+)
- AWS CLI configured
- Your public IP address

## Deployment Steps

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review Configuration
```bash
# Update my_ip in variables.tf with your IP
# Get your IP: curl ifconfig.me

# Review what will be created
terraform plan
```

### 3. Deploy Infrastructure
```bash
terraform apply

# Type 'yes' when prompted
# Wait 15-20 minutes for completion
```

### 4. Configure kubectl
```bash
# Get command from output
terraform output configure_kubectl

# Run the command
aws eks update-kubeconfig --region us-east-1 --name eks-masterclass-cluster

# Verify
kubectl get nodes
```

## Resources Created
- VPC with 3 public and 3 private subnets
- Internet Gateway
- 3 NAT Gateways (one per AZ)
- EKS Control Plane
- Managed Node Group (2 t3.medium instances)
- Security Groups (restricted to your IP)
- IAM Roles and Policies
- Cluster Add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)

## Security Features
- API access restricted to your IP
- SSH access restricted to your IP
- Private subnets for worker nodes
- IAM roles with least privilege
- Encrypted EBS volumes

## Cleanup
```bash
# Delete all Kubernetes resources first
kubectl delete all --all --all-namespaces

# Destroy infrastructure
terraform destroy

# Type 'yes' when prompted
```

## Cost Estimate
- EKS Control Plane: ~$73/month
- 2 x t3.medium nodes: ~$60/month
- NAT Gateways: ~$100/month
- Total: ~$233/month

## Best Practices Implemented
1. Multi-AZ deployment for high availability
2. Separate public/private subnets
3. Security groups restricted to known IPs
4. Proper subnet tagging for EKS
5. Managed node groups for easy updates
6. CloudWatch logging enabled
7. Standard tags for resource management
