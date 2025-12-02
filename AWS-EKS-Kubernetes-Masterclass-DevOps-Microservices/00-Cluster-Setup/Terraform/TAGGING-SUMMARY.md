# EKS Cluster Tagging Summary

## Overview
All resources created by this Terraform configuration are properly tagged with consistent metadata for tracking, billing, and compliance.

## Tag Structure

All resources use the following tags:

```hcl
Name        = "training-cluster" (or resource-specific name)
Owner       = "imran.shaikh@einfochips.com"
Project     = "Internal POC"
DM          = "Shahid Raza"
Department  = "PES-Digital"
Environment = "training"
ENDDate     = "30-11-2025"
ManagedBy   = "Terraform"
Purpose     = "EKS Training Cluster"
```

## Tagged Resources

### 1. EKS Cluster
- **Resource**: `aws_eks_cluster.training_cluster`
- **Name Tag**: `training-cluster`

### 2. VPC & Networking
- **VPC**: `training-cluster-vpc`
- **Public Subnets**: `training-cluster-public-1`, `training-cluster-public-2`
- **Private Subnets**: `training-cluster-private-1`, `training-cluster-private-2`
- **Internet Gateway**: `training-cluster-igw`
- **NAT Gateways**: `training-cluster-nat-1`, `training-cluster-nat-2`
- **NAT EIPs**: `training-cluster-nat-eip-1`, `training-cluster-nat-eip-2`
- **Route Tables**: `training-cluster-public-rt`, `training-cluster-private-rt-1`, `training-cluster-private-rt-2`

### 3. Security Groups
- **Cluster SG**: `training-cluster-cluster-sg`
- **Nodes SG**: `training-cluster-nodes-sg`

### 4. IAM Roles
- **Cluster Role**: `training-cluster-cluster-role`
- **Node Group Role**: `training-cluster-node-group-role`
- **Load Balancer Controller Role**: `training-cluster-aws-load-balancer-controller`
- **EBS CSI Driver Role**: `training-cluster-ebs-csi-driver`

### 5. EKS Node Group & ASG
- **Node Group**: `training-cluster-nodes`
- **Auto Scaling Group**: Automatically tagged via launch template
- **EC2 Instances**: `training-cluster-node` (via launch template)
- **EBS Volumes**: `training-cluster-node-volume` (via launch template)

### 6. CloudWatch Logs
- **Log Group**: `/aws/eks/training-cluster/cluster`

## Launch Template Tagging

The launch template ensures that all EC2 instances and volumes created by the Auto Scaling Group are properly tagged:

```hcl
tag_specifications {
  resource_type = "instance"
  tags = {
    Name        = "training-cluster-node"
    Owner       = "imran.shaikh@einfochips.com"
    Project     = "Internal POC"
    DM          = "Shahid Raza"
    Department  = "PES-Digital"
    Environment = "training"
    ENDDate     = "30-11-2025"
    ManagedBy   = "Terraform"
    Purpose     = "EKS Training Cluster"
  }
}

tag_specifications {
  resource_type = "volume"
  tags = {
    Name        = "training-cluster-node-volume"
    # ... same tags as above
  }
}
```

## Verification

After deployment, verify tags using AWS CLI:

```bash
# Check EC2 instance tags
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=training-cluster-node" \
  --query 'Reservations[].Instances[].Tags'

# Check ASG tags
aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `training-cluster`)].Tags'

# Check all EKS-related resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=ManagedBy,Values=Terraform Key=Purpose,Values="EKS Training Cluster"
```

## Cost Allocation

These tags enable:
- **Cost tracking** by Owner, Project, and Department
- **Resource lifecycle management** using ENDDate
- **Compliance reporting** for internal audits
- **Automated cleanup** based on tags
