# VPC Infrastructure with Terraform Modules

## Project Overview
Infrastructure as Code (IaC) solution using Terraform modules to deploy a production-ready VPC with public and private subnets, following AWS networking best practices.

## Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────────────────────────────────────────┤
│  AZ-1a                           │  AZ-1b                   │
│  ┌─────────────────────────────┐ │ ┌─────────────────────────┐ │
│  │ Public Subnet (10.0.1.0/24)│ │ │ Public Subnet (10.0.2.0/24)│ │
│  │                             │ │ │                         │ │
│  │ ┌─────────────────────────┐ │ │ │ ┌─────────────────────┐ │ │
│  │ │    Bastion Host         │ │ │ │ │    NAT Gateway      │ │ │
│  │ └─────────────────────────┘ │ │ │ └─────────────────────┘ │ │
│  └─────────────────────────────┘ │ └─────────────────────────┘ │
│                                  │                           │
│  ┌─────────────────────────────┐ │ ┌─────────────────────────┐ │
│  │Private Subnet (10.0.3.0/24)│ │ │Private Subnet (10.0.4.0/24)│ │
│  │                             │ │ │                         │ │
│  │ ┌─────────────────────────┐ │ │ │                         │ │
│  │ │   Private EC2           │ │ │ │                         │ │
│  │ └─────────────────────────┘ │ │ │                         │ │
│  └─────────────────────────────┘ │ └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                        │
                ┌───────▼───────┐
                │ Internet      │
                │ Gateway       │
                └───────────────┘
```

## Components
- **VPC**: Custom Virtual Private Cloud (10.0.0.0/16)
- **Public Subnets**: 2 subnets across different AZs for high availability
- **Private Subnets**: 2 subnets for secure backend resources
- **Internet Gateway**: Public internet access for public subnets
- **NAT Gateway**: Outbound internet access for private subnets
- **Bastion Host**: Secure SSH access to private instances
- **Route Tables**: Proper routing configuration
- **Security Groups**: Network-level security

## Features
-  Multi-AZ deployment for high availability
-  Modular Terraform code for reusability
-  Security best practices implementation
-  Cost-optimized NAT Gateway setup
-  Comprehensive security groups

## Quick Start

### 1. Clone and Setup
```bash
cd /home/einfochips/TrainingPlanNew/Tasks/TASKS-Dec15/Task3
terraform init
```

### 2. Plan Infrastructure
```bash
terraform plan
```

### 3. Deploy Infrastructure
```bash
terraform apply
```

### 4. Connect to Private Instance
```bash
# SSH to Bastion Host
ssh -i vpc-key.pem ec2-user@<bastion-public-ip>

# From Bastion, SSH to Private Instance
ssh -i vpc-key.pem ec2-user@<private-instance-ip>
```

### 5. Cleanup
```bash
terraform destroy
```

## Module Structure
```
Task3/
├── main.tf                 # Root configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars        # Variable values
├── modules/
│   ├── vpc/               # VPC module
│   ├── subnets/           # Subnets module
│   ├── security/          # Security Groups module
│   └── compute/           # EC2 instances module
├── scripts/
│   └── user-data.sh       # EC2 initialization script
└── screenshots/
    ├── 01-vpc-overview.png
    ├── 02-subnets-routing.png
    ├── 03-security-groups.png
    ├── 04-instances.png
    └── 05-ssh-connection.png
```

## Networking Details

### Subnets
| Subnet | CIDR | AZ | Type | Purpose |
|--------|------|----|----- |---------|
| Public-1 | 10.0.1.0/24 | us-east-1a | Public | Bastion Host |
| Public-2 | 10.0.2.0/24 | us-east-1b | Public | NAT Gateway |
| Private-1 | 10.0.3.0/24 | us-east-1a | Private | Application Servers |
| Private-2 | 10.0.4.0/24 | us-east-1b | Private | Database Servers |

### Route Tables
- **Public Route Table**: Routes to Internet Gateway (0.0.0.0/0)
- **Private Route Table**: Routes to NAT Gateway (0.0.0.0/0)

### Security Groups
- **Bastion SG**: SSH (22) from your IP
- **Private SG**: SSH (22) from Bastion SG only
- **Web SG**: HTTP/HTTPS from anywhere (if needed)