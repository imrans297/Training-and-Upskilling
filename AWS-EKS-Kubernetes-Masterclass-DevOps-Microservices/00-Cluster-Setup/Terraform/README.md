# EKS Cluster Setup with Terraform

This Terraform configuration creates a production-ready EKS cluster with security groups restricted to your IP address.

## Security Features

- **IP Restriction**: All inbound traffic is restricted to your IP address (106.215.176.143/32)
- **SSH Access**: Only your IP can SSH to worker nodes
- **HTTP/HTTPS**: Only your IP can access HTTP (80) and HTTPS (443) ports
- **EKS API**: Cluster API endpoint is only accessible from your IP

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. kubectl installed

## Quick Deployment

```bash
# 1. Configure MDATP onboarding (see MDATP-SETUP.md)
# Edit user-data.sh and add your onboarding files

# 2. Make scripts executable
chmod +x deploy.sh create-keypair.sh

# 3. Deploy the cluster
./deploy.sh
```

## Manual Deployment

1. **Create EC2 Key Pair**:
   ```bash
   ./create-keypair.sh
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region ap-south-1 --name training-cluster
   ```

## Configuration

Edit `terraform.tfvars` to customize:

- `aws_region`: AWS region (default: ap-south-1)
- `cluster_name`: EKS cluster name (default: training-cluster)
- `instance_type`: Worker node instance type (default: t3.medium)
- `desired_capacity`: Number of worker nodes (default: 2)

## Security Groups

### EKS Cluster Security Group
- **Inbound**: HTTPS (443) from your IP only
- **Outbound**: All traffic allowed

### Worker Nodes Security Group
- **Inbound**: 
  - SSH (22) from your IP only
  - HTTP (80) from your IP only
  - HTTPS (443) from your IP only
  - Node-to-node communication within VPC
- **Outbound**: All traffic allowed

## Resource Tagging

All resources are automatically tagged with:
- Owner, Project, Department information
- Environment and lifecycle metadata
- Cost allocation tags

See [TAGGING-SUMMARY.md](TAGGING-SUMMARY.md) for complete details.

## MDATP Integration

All EC2 nodes are automatically configured with Microsoft Defender for Endpoint.

See [MDATP-SETUP.md](MDATP-SETUP.md) for configuration instructions.

## Cleanup

```bash
# Use the cleanup script
./destroy.sh

# Or manually
terraform destroy
```

## Files Structure

- `main.tf`: Main infrastructure configuration
- `variables.tf`: Variable definitions
- `outputs.tf`: Output values
- `iam.tf`: IAM roles and policies
- `terraform.tfvars`: Variable values
- `deploy.sh`: Automated deployment script
- `create-keypair.sh`: EC2 key pair creation script

## Training Namespaces

The following namespaces are automatically created for training purposes:

- docker-fundamentals
- k8s-imperative
- k8s-declarative
- pod-identity
- storage-ebs
- secrets-probes
- storage-rds
- loadbalancers
- alb-controller
- ingress-basics
- ingress-context-path
- ingress-host-header
- ingress-groups
- ingress-target-ip
- ingress-internal
- ecr-integration
- microservices
- hpa-autoscaler
- vpa-autoscaler
- cluster-autoscaler
- container-insights