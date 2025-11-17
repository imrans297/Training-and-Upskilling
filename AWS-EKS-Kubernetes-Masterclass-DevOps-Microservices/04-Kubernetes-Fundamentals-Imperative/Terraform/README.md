# Kubernetes Fundamentals - Terraform Infrastructure

## What We're Achieving
Create a dedicated Kubernetes learning environment using Infrastructure as Code with Terraform.

## What We're Doing
Provisioning a complete Kubernetes cluster optimized for learning fundamentals with proper tagging and cost management.

## Architecture
```
┌─────────────────────────────────────┐
│     EKS Control Plane (AWS Managed) │
│  - API Server                       │
│  - etcd                             │
│  - Scheduler                        │
│  - Controller Manager               │
└─────────────────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼────┐         ┌───▼────┐
│ Node 1 │         │ Node 2 │
│t3.medium│        │t3.medium│
└────────┘         └────────┘
```

## Cost Estimation
- **EKS Control Plane**: $0.10/hour ($72/month)
- **Worker Nodes**: 2x t3.medium = $0.0832/hour ($60/month)
- **EBS Volumes**: 2x 20GB = $2/month
- **NAT Gateway**: $0.045/hour ($32/month)
- **Total**: ~$166/month

**Cost Optimization Tips:**
- Use Spot instances for worker nodes (-60% cost)
- Stop cluster when not in use
- Use smaller instance types for learning

## Prerequisites
- AWS CLI configured
- Terraform installed (>= 1.0)
- kubectl installed

## Quick Start
```bash
# Clone and setup
cd Terraform
terraform init

# Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# Deploy
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name k8s-learning-cluster

# Verify
kubectl get nodes
```

## Files Structure
```
Terraform/
├── main.tf                 # Main EKS cluster configuration
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── vpc.tf               # VPC and networking
├── iam.tf              # IAM roles and policies
├── terraform.tfvars.example  # Example variables
└── README.md           # This file
```

## What Gets Created
- **VPC**: Dedicated network (10.0.0.0/16)
- **Subnets**: Public and private across 2 AZs
- **EKS Cluster**: Kubernetes control plane
- **Node Group**: 2 managed worker nodes
- **IAM Roles**: Proper permissions for cluster and nodes
- **Security Groups**: Network access controls
- **Tags**: Proper resource tagging for cost tracking

## Post-Deployment Steps
1. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region ap-south-1 --name k8s-learning-cluster
   ```

2. **Verify cluster**:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   ```

3. **Install additional tools** (optional):
   ```bash
   # Metrics server
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   
   # Kubernetes dashboard
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
   ```

## Cleanup
```bash
# Destroy infrastructure
terraform destroy

# Confirm deletion in AWS Console
```

## Troubleshooting

### Common Issues
1. **Insufficient permissions**: Ensure AWS credentials have EKS permissions
2. **VPC limits**: Check VPC and subnet limits in your region
3. **Instance limits**: Verify EC2 instance limits

### Useful Commands
```bash
# Check Terraform state
terraform state list
terraform state show aws_eks_cluster.main

# Debug kubectl issues
kubectl config current-context
kubectl config view

# Check cluster status
aws eks describe-cluster --name k8s-learning-cluster --region ap-south-1
```

## Security Considerations
- Cluster endpoint is public (for learning)
- Worker nodes in private subnets
- Security groups restrict access
- IAM roles follow least privilege

## Next Steps
1. Deploy the infrastructure
2. Practice with CLI commands
3. Work through Labs 1-5
4. Clean up resources when done