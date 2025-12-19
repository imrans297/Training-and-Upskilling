# EKS Cluster with Private Nodes + Public ALB

**Author:** Imran Shaikh  
**Project:** Production-Ready EKS Implementation

## Quick Start

```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply -auto-approve

# Configure kubectl
./scripts/setup-kubectl.sh

# Deploy application
kubectl apply -f manifests/nginx-deployment.yaml
kubectl apply -f manifests/nginx-ingress.yaml
```

## Architecture

- **Private EKS Nodes**: No public IPs, secure worker nodes
- **Public ALB**: Internet-facing load balancer in public subnets
- **VPC CNI**: Custom networking for pod IP management
- **Production Security**: Proper IAM roles and security groups

## File Structure

```
Task4/
├── provider.tf              # Terraform & AWS provider config
├── networking.tf            # VPC, subnets, routing
├── eks.tf                   # EKS cluster & node groups
├── alb-controller.tf        # ALB controller IAM setup
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── main.tf                  # Main entry point
├── manifests/
│   ├── nginx-deployment.yaml
│   └── nginx-ingress.yaml
├── scripts/
│   └── setup-kubectl.sh
├── screenshots/             # Documentation screenshots
├── DOCUMENTATION.md         # Detailed implementation guide
└── README.md               # This file
```

## Key Features

- ✅ Private worker nodes (no public IPs)
- ✅ Public ALB for external access
- ✅ VPC CNI custom networking
- ✅ Production-ready security
- ✅ Auto-scaling node groups
- ✅ Comprehensive monitoring

See [DOCUMENTATION.md](DOCUMENTATION.md) for detailed implementation steps.