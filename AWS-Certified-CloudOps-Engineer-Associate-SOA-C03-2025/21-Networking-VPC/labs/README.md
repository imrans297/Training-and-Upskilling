# VPC Labs - Terraform

## Overview
Complete VPC infrastructure with multi-AZ setup, NAT Gateways, security groups, VPC endpoints, and flow logs.

## Architecture
- VPC: 10.0.0.0/16
- 2 Public Subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 Private Subnets (10.0.10.0/24, 10.0.11.0/24)
- 2 Database Subnets (10.0.20.0/24, 10.0.21.0/24)
- Internet Gateway
- 2 NAT Gateways (one per AZ)
- S3 VPC Endpoint
- VPC Flow Logs

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply -auto-approve

# Destroy
terraform destroy -auto-approve
```

## Resources Created
- 1 VPC
- 6 Subnets (2 public, 2 private, 2 database)
- 1 Internet Gateway
- 2 NAT Gateways
- 2 Elastic IPs
- 3 Route Tables
- Security Groups
- VPC Endpoints
- Flow Logs
