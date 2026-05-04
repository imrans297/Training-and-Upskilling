# Automobile DevOps Project - Final Implementation Plan

## Project Overview
**Production-grade DevOps infrastructure for Automobile Application using Terraform + Terragrunt with GitOps workflow**

---

## Table of Contents
1. [Technology Stack](#technology-stack)
2. [AFT (Account Factory for Terraform) - Deep Dive](#aft-account-factory-for-terraform---deep-dive)
3. [Project Structure](#project-structure)
4. [Infrastructure Components](#infrastructure-components)
5. [Implementation Phases](#implementation-phases)
6. [GitOps Workflow](#gitops-workflow)

---

## Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Terraform | 1.10.x | Infrastructure provisioning |
| Terragrunt | 0.68.x | DRY configuration, multi-env management |
| AWS Provider | ~>5.0 | AWS resource management |
| Docker | Latest | Containerization |
| GitHub Actions | - | CI/CD pipeline |
| Region | ap-south-1 | Primary region (Mumbai) |

---

## AFT (Account Factory for Terraform) - Deep Dive

### What is AFT?

**AFT (Account Factory for Terraform)** is an AWS solution that automates the provisioning, customization, and management of multiple AWS accounts within an AWS Organization using Terraform and AWS Control Tower.

### The Problem AFT Solves

#### Without AFT (Manual Approach)
```
Scenario: Create 10 AWS accounts for different teams/environments

Manual Steps per Account:
1. Login to AWS Organizations
2. Create new account manually
3. Setup billing and cost allocation
4. Configure IAM roles and policies
5. Enable CloudTrail, GuardDuty, Config
6. Create VPC and networking
7. Setup security baselines
8. Configure compliance policies
9. Enable logging and monitoring
10. Document everything

Time: 2-4 hours per account × 10 accounts = 20-40 hours ❌
Consistency: High risk of configuration drift ❌
Scalability: Not sustainable for 50+ accounts ❌
```

#### With AFT (Automated Approach)
```
Scenario: Create 10 AWS accounts for different teams/environments

Automated Steps:
1. Define account in Terraform code
2. Commit to Git repository
3. AFT pipeline automatically:
   - Creates AWS account
   - Applies global customizations
   - Applies account-specific configs
   - Runs validation tests
   - Sends notification

Time: 5 minutes to write code + 20-30 min automated provisioning ✅
Consistency: 100% consistent across all accounts ✅
Scalability: Can provision 100+ accounts easily ✅
```

---

### AFT Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Organization                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │         Management Account (Root)                       │    │
│  │  - AWS Organizations                                    │    │
│  │  - AWS Control Tower                                    │    │
│  │  - Billing & Cost Management                            │    │
│  └────────────────────────────────────────────────────────┘    │
│                           │                                      │
│                           ├──────────────────────────────────┐  │
│                           │                                  │  │
│  ┌────────────────────────▼──────────┐  ┌─────────────────▼──┐│
│  │   AFT Management Account           │  │  Audit Account     ││
│  │  - AFT Pipeline (Step Functions)   │  │  - CloudTrail      ││
│  │  - CodePipeline                    │  │  - Config          ││
│  │  - Terraform State (S3/DynamoDB)   │  │  - Security Hub    ││
│  │  - Lambda Functions                │  └────────────────────┘│
│  └────────────────────────────────────┘                        │
│                           │                                      │
│         ┌─────────────────┼─────────────────┐                  │
│         │                 │                 │                  │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐           │
│  │ Production  │  │  Non-Prod   │  │   POC-1     │           │
│  │  Account    │  │   Account   │  │   Account   │  ... (N)  │
│  │             │  │             │  │             │           │
│  │ - VPC       │  │ - VPC       │  │ - VPC       │           │
│  │ - EKS       │  │ - EKS       │  │ - EKS       │           │
│  │ - RDS       │  │ - RDS       │  │ - RDS       │           │
│  └─────────────┘  └─────────────┘  └─────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

---

### AFT Components & Workflow

#### 1. AFT Core Infrastructure

**Deployed in AFT Management Account:**
- **AWS Step Functions**: Orchestrates account provisioning workflow
- **AWS CodePipeline**: CI/CD for account requests
- **AWS Lambda**: Custom logic execution
- **S3 Buckets**: Terraform state storage
- **DynamoDB**: State locking
- **SNS Topics**: Notifications
- **CloudWatch Logs**: Audit trail

#### 2. Four AFT Git Repositories

##### Repository 1: `aft-account-request`
**Purpose**: Define which AWS accounts to create

```hcl
# terraform/account-requests/production-account.tf
module "production_account" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "aws-prod@company.com"
    AccountName               = "Production-Account"
    ManagedOrganizationalUnit = "Production"
    SSOUserEmail              = "admin@company.com"
    SSOUserFirstName          = "Admin"
    SSOUserLastName           = "User"
  }

  account_tags = {
    Environment = "production"
    CostCenter  = "engineering"
    Owner       = "devops-team"
    Compliance  = "pci-dss"
  }

  change_management_parameters = {
    change_requested_by = "DevOps Team"
    change_reason       = "New production environment for automobile platform"
  }

  account_customizations_name = "production-baseline"
}

# terraform/account-requests/poc-accounts.tf
module "poc_1_account" {
  source = "./modules/aft-account-request"

  control_tower_parameters = {
    AccountEmail              = "aws-poc1@company.com"
    AccountName               = "POC-1-Account"
    ManagedOrganizationalUnit = "Sandbox"
    SSOUserEmail              = "poc-admin@company.com"
    SSOUserFirstName          = "POC"
    SSOUserLastName           = "Admin"
  }

  account_tags = {
    Environment = "poc"
    CostCenter  = "research"
    Owner       = "innovation-team"
  }

  account_customizations_name = "sandbox-baseline"
}
```

**Workflow:**
1. Developer creates new `.tf` file defining account
2. Commits to Git and raises PR
3. Team reviews account requirements
4. PR merged → AFT pipeline triggers
5. Account created in 20-30 minutes

---

##### Repository 2: `aft-global-customizations`
**Purpose**: Apply configurations to ALL accounts (security baseline)

```
aft-global-customizations/
├── terraform/
│   ├── cloudtrail.tf          # Enable CloudTrail in all accounts
│   ├── guardduty.tf           # Enable GuardDuty
│   ├── config.tf              # AWS Config rules
│   ├── iam-baseline.tf        # Standard IAM roles
│   ├── security-hub.tf        # Security Hub integration
│   ├── vpc-flow-logs.tf       # Enable VPC flow logs
│   └── tags.tf                # Mandatory tags
├── api_helpers/
│   ├── pre-api-helpers.sh     # Run before Terraform
│   └── post-api-helpers.sh    # Run after Terraform
└── python/
    └── requirements.txt
```

**Example: cloudtrail.tf**
```hcl
# Applied to every account automatically
resource "aws_cloudtrail" "organization_trail" {
  name                          = "organization-trail"
  s3_bucket_name                = var.central_logging_bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    ManagedBy = "AFT"
    Purpose   = "Security-Audit"
  }
}
```

**Example: iam-baseline.tf**
```hcl
# Standard IAM roles for all accounts
resource "aws_iam_role" "admin_role" {
  name = "OrganizationAccountAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.management_account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin_policy" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
```

---

##### Repository 3: `aft-account-customizations`
**Purpose**: Account-specific configurations (per account or per group)

```
aft-account-customizations/
├── production-baseline/        # For production accounts
│   ├── terraform/
│   │   ├── vpc.tf             # Production VPC (multi-AZ)
│   │   ├── eks.tf             # EKS cluster
│   │   ├── rds.tf             # Multi-AZ RDS
│   │   ├── backup.tf          # AWS Backup configuration
│   │   └── waf.tf             # WAF rules
│   └── api_helpers/
│       └── post-api-helpers.sh
├── sandbox-baseline/           # For POC/sandbox accounts
│   ├── terraform/
│   │   ├── vpc.tf             # Simple VPC (single AZ)
│   │   └── budget-alerts.tf   # Cost alerts
│   └── api_helpers/
└── shared-services-baseline/   # For shared services
    ├── terraform/
    │   ├── vpc.tf
    │   ├── eks.tf             # Management EKS for CI/CD
    │   ├── ecr.tf             # Shared ECR
    │   └── argo-cd.tf         # Argo CD setup
    └── api_helpers/
```

**Example: production-baseline/terraform/vpc.tf**
```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "auto-prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Production-grade settings
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  tags = {
    Environment = "production"
    ManagedBy   = "AFT"
  }
}
```

---

##### Repository 4: `aft-account-provisioning-customizations`
**Purpose**: Custom scripts and logic during account provisioning

```
aft-account-provisioning-customizations/
├── terraform/
│   └── customizations.tf      # Optional Terraform resources
├── api_helpers/
│   ├── pre-api-helpers.sh     # Runs BEFORE account creation
│   └── post-api-helpers.sh    # Runs AFTER account creation
└── python/
    ├── requirements.txt
    └── custom_logic.py
```

**Example: pre-api-helpers.sh**
```bash
#!/bin/bash
# Runs before account provisioning

echo "Starting account provisioning..."

# Validate account email is unique
ACCOUNT_EMAIL=$1
if aws organizations list-accounts | grep -q "$ACCOUNT_EMAIL"; then
    echo "Error: Account email already exists"
    exit 1
fi

# Send notification to Slack
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"New AWS account provisioning started: '"$ACCOUNT_EMAIL"'"}'

echo "Pre-provisioning checks completed"
```

**Example: post-api-helpers.sh**
```bash
#!/bin/bash
# Runs after account provisioning

ACCOUNT_ID=$1
ACCOUNT_NAME=$2

echo "Account $ACCOUNT_NAME ($ACCOUNT_ID) provisioned successfully"

# Configure AWS CLI for new account
aws configure set region ap-south-1 --profile $ACCOUNT_NAME

# Enable Cost Explorer
aws ce enable-cost-explorer --account-id $ACCOUNT_ID

# Create billing alerts
aws cloudwatch put-metric-alarm \
  --alarm-name "${ACCOUNT_NAME}-billing-alert" \
  --alarm-description "Alert when costs exceed $100" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold

# Send success notification
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"✅ AWS account '"$ACCOUNT_NAME"' is ready!"}'

echo "Post-provisioning tasks completed"
```

---

### AFT Provisioning Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AFT Account Provisioning Flow                │
└─────────────────────────────────────────────────────────────────┘

1. Developer Action
   └─> Create account request in aft-account-request repo
   └─> Commit and push to Git
   └─> Raise Pull Request

2. Review & Approval
   └─> Team reviews account requirements
   └─> Security team approves
   └─> PR merged to main branch

3. AFT Pipeline Triggered (AWS Step Functions)
   └─> CodePipeline detects Git change
   └─> Validates Terraform code
   └─> Starts Step Functions workflow

4. Pre-Provisioning (5 min)
   └─> Run pre-api-helpers.sh scripts
   └─> Validate account parameters
   └─> Check for duplicates

5. Account Creation (10-15 min)
   └─> AWS Control Tower creates account
   └─> Assigns to Organizational Unit
   └─> Configures SSO access
   └─> Sets up billing

6. Global Customizations (5-10 min)
   └─> Apply aft-global-customizations
   └─> Enable CloudTrail
   └─> Enable GuardDuty
   └─> Configure AWS Config
   └─> Setup IAM baseline roles

7. Account-Specific Customizations (10-15 min)
   └─> Apply aft-account-customizations
   └─> Create VPC
   └─> Deploy EKS/ECS
   └─> Configure RDS
   └─> Setup monitoring

8. Post-Provisioning (5 min)
   └─> Run post-api-helpers.sh scripts
   └─> Enable Cost Explorer
   └─> Configure billing alerts
   └─> Send notifications

9. Validation & Completion
   └─> Run compliance checks
   └─> Generate documentation
   └─> Update CMDB
   └─> Notify stakeholders

Total Time: 35-50 minutes ✅
Manual Effort: 5 minutes (writing code) ✅
```

---

### AFT Prerequisites & Requirements

#### 1. AWS Organization Setup
```
Required:
✅ AWS Organizations enabled
✅ Management account with admin access
✅ At least 2 OUs (Organizational Units) created
✅ AWS Control Tower deployed
```

#### 2. AWS Control Tower
```
Cost: ~$50-100/month

Components:
- Landing Zone setup
- Guardrails (preventive & detective)
- Account Factory
- Dashboard and reporting

Setup Time: 1-2 hours
```

#### 3. AFT Management Account
```
Dedicated AWS account for AFT infrastructure

Resources:
- Step Functions
- CodePipeline
- Lambda functions
- S3 buckets (Terraform state)
- DynamoDB tables (state locking)
- CloudWatch Logs

Cost: ~$20-50/month
```

#### 4. Git Repository Access
```
Supported:
✅ GitHub
✅ GitLab
✅ AWS CodeCommit
✅ Bitbucket

Required:
- 4 repositories created
- Webhook/integration configured
- Access tokens/credentials
```

#### 5. IAM Permissions
```
Management Account needs:
- organizations:*
- controltower:*
- sts:AssumeRole
- iam:CreateRole
- Full access to AFT resources
```

---

### When to Use AFT vs Our Approach

| Criteria | Use AFT | Use Our Approach (Single Account) |
|----------|---------|------------------------------------|
| **Number of Accounts** | 5+ accounts | 1-2 accounts |
| **Team Size** | 10+ engineers | 1-5 engineers |
| **Budget** | $500+/month | $0-100/month |
| **Compliance Needs** | High (SOC2, PCI-DSS) | Low to Medium |
| **Account Provisioning** | Frequent (weekly) | Rare (once/twice) |
| **Governance** | Centralized control | Flexible |
| **Learning Curve** | High (2-3 weeks) | Medium (1 week) |
| **Use Case** | Enterprise production | Learning, POC, Startups |
| **Prerequisites** | Control Tower required | None |
| **Maintenance** | Dedicated team | Single person |

---

### AFT Cost Breakdown

```
Initial Setup Costs:
├── AWS Control Tower: $0 (service is free, pay for resources)
├── AFT Infrastructure: ~$50/month
│   ├── Step Functions: ~$5
│   ├── CodePipeline: ~$10
│   ├── Lambda: ~$5
│   ├── S3: ~$5
│   ├── DynamoDB: ~$5
│   └── CloudWatch: ~$20
└── Per Account Costs: ~$10-20/month
    ├── CloudTrail: ~$5
    ├── Config: ~$5
    └── GuardDuty: ~$5

Total for 10 Accounts:
- AFT Infrastructure: $50/month
- 10 Accounts × $15: $150/month
- Account Resources (VPC, EKS, etc.): $500-2000/month

Grand Total: $700-2200/month
```

---

### AFT vs Our Project: Decision Matrix

#### Our Project (Automobile Platform)
```
Requirements:
✅ Single AWS account
✅ 2 environments (dev, prod)
✅ Learning purpose
✅ Cost optimization critical
✅ Interview demonstration
✅ Quick setup needed

Decision: DON'T use AFT ❌

Reason:
- Overkill for single account
- High complexity for learning
- Additional costs ($700+/month)
- Longer setup time
- Not necessary for interviews
```

#### Enterprise Scenario (When AFT Makes Sense)
```
Requirements:
✅ 20+ AWS accounts needed
✅ Multiple teams/departments
✅ Strict compliance (PCI-DSS, HIPAA)
✅ Frequent account provisioning
✅ Centralized governance
✅ Budget available ($5000+/month)

Decision: USE AFT ✅

Reason:
- Scales to 100+ accounts
- Consistent security baseline
- Automated compliance
- Reduces manual effort
- Industry best practice
```

---

### AFT Interview Talking Points

**Question: "Have you worked with AWS Account Factory for Terraform?"**

**Answer:**
> "While I haven't implemented AFT in production yet, I have in-depth knowledge of its architecture and use cases. AFT is AWS's solution for automating multi-account provisioning using Terraform and Control Tower.
>
> In my automobile platform project, I evaluated AFT but chose a single-account approach with Terragrunt for cost optimization and learning purposes. However, I understand AFT's value in enterprise environments where you need to provision and manage 10+ accounts with consistent security baselines.
>
> AFT uses four Git repositories: account-request for defining accounts, global-customizations for security baselines applied to all accounts, account-customizations for environment-specific configs, and provisioning-customizations for custom automation.
>
> The workflow is GitOps-based: you define an account in Terraform, raise a PR, and upon merge, AFT's Step Functions pipeline automatically provisions the account with all customizations in 30-40 minutes.
>
> For my next project involving multiple AWS accounts, I would definitely implement AFT to demonstrate enterprise-grade account management."

---

### Summary: AFT vs Our Approach

```
┌─────────────────────────────────────────────────────────────┐
│                    Our Project Approach                      │
├─────────────────────────────────────────────────────────────┤
│ Single AWS Account                                          │
│ ├── Dev Environment (Terragrunt workspace)                  │
│ │   ├── VPC: 10.0.0.0/16                                    │
│ │   ├── EKS/ECS                                             │
│ │   └── RDS                                                 │
│ └── Prod Environment (Terragrunt workspace)                 │
│     ├── VPC: 10.1.0.0/16                                    │
│     ├── EKS/ECS                                             │
│     └── RDS                                                 │
│                                                              │
│ Benefits:                                                    │
│ ✅ Cost: $0-100/month                                        │
│ ✅ Setup: 1-2 days                                           │
│ ✅ Complexity: Medium                                        │
│ ✅ Perfect for learning                                      │
│ ✅ Interview-ready                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    AFT Approach (Future)                     │
├─────────────────────────────────────────────────────────────┤
│ AWS Organization                                             │
│ ├── Management Account                                       │
│ ├── AFT Management Account                                   │
│ ├── Production Account                                       │
│ ├── Non-Production Account                                   │
│ ├── Shared Services Account                                  │
│ └── POC Accounts (1-N)                                       │
│                                                              │
│ Benefits:                                                    │
│ ✅ Scales to 100+ accounts                                   │
│ ✅ Automated provisioning                                    │
│ ✅ Consistent security baseline                              │
│ ✅ Enterprise-grade governance                               │
│                                                              │
│ Drawbacks:                                                   │
│ ❌ Cost: $700-2000/month                                     │
│ ❌ Setup: 1-2 weeks                                          │
│ ❌ Complexity: High                                          │
│ ❌ Overkill for learning                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
automobile-devops-project/
│
├── terraform-modules/              # Reusable Terraform modules
│   ├── aws-vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── aws-eks/
│   ├── aws-ecs/
│   ├── aws-ecr/
│   ├── aws-alb/
│   ├── aws-rds/
│   ├── aws-s3/
│   └── aws-common/                # Shared tags, naming
│
├── terragrunt/                     # Live infrastructure (Terragrunt)
│   ├── terragrunt.hcl             # Root configuration
│   ├── _envcommon/                # Shared environment configs
│   │   ├── vpc.hcl
│   │   ├── eks.hcl
│   │   └── rds.hcl
│   ├── dev/
│   │   ├── account.hcl            # Dev account settings
│   │   └── ap-south-1/
│   │       ├── region.hcl
│   │       ├── vpc/
│   │       │   └── terragrunt.hcl
│   │       ├── eks/
│   │       │   └── terragrunt.hcl
│   │       ├── ecr/
│   │       │   └── terragrunt.hcl
│   │       ├── alb/
│   │       │   └── terragrunt.hcl
│   │       └── rds/
│   │           └── terragrunt.hcl
│   └── prod/
│       ├── account.hcl
│       └── ap-south-1/
│           ├── region.hcl
│           ├── vpc/
│           ├── eks/
│           ├── ecr/
│           ├── alb/
│           └── rds/
│
├── application/                    # Automobile Application
│   ├── backend/                   # Node.js/Python API
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── frontend/                  # React Web App
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── docker-compose.yml         # Local development
│
├── kubernetes/                     # K8s manifests (if using EKS)
│   ├── deployments/
│   │   ├── backend-deployment.yaml
│   │   └── frontend-deployment.yaml
│   ├── services/
│   │   ├── backend-service.yaml
│   │   └── frontend-service.yaml
│   └── ingress/
│       └── alb-ingress.yaml
│
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml     # PR validation
│       ├── terraform-apply.yml    # Auto deployment
│       ├── app-build.yml          # Build Docker images
│       └── app-deploy.yml         # Deploy to ECS/EKS
│
├── scripts/
│   ├── setup-backend.sh           # Initialize S3/DynamoDB
│   ├── deploy.sh                  # Deployment helper
│   └── destroy.sh                 # Cleanup script
│
└── docs/
    ├── architecture.md
    ├── setup-guide.md
    └── interview-guide.md
```

---

## Infrastructure Components

### Cost-Optimized Architecture (3 Options)

#### Option 1: EC2 + Docker (FREE TIER) ⭐ RECOMMENDED START
```
Cost: $0-5/month

Components:
├── VPC (Free)
├── EC2 t2.micro (750 hrs free)
├── S3 (5GB free)
├── RDS t3.micro (750 hrs free)
└── Route53 ($0.50/month)
```

#### Option 2: ECS Fargate (LOW COST)
```
Cost: $20-40/month

Components:
├── VPC (Free)
├── ECS Fargate (~$15-20)
├── ALB (~$16)
├── ECR (500MB free)
├── RDS t3.micro (Free)
└── S3 (Free)
```

#### Option 3: EKS (FULL LEARNING)
```
Cost: $120-150/month

Components:
├── VPC (Free)
├── EKS Control Plane ($73)
├── EC2 t3.medium nodes ($30-40)
├── ALB (~$16)
├── RDS (Free)
└── ECR (Free)
```

---

## Automobile Application Features

### Backend API (Node.js/FastAPI)
- Vehicle CRUD operations
- User authentication (JWT)
- Search and filter vehicles
- Booking management
- Admin dashboard API

### Frontend (React)
- Vehicle catalog with images
- Advanced search filters
- User registration/login
- Booking interface
- Responsive design

### Database Schema
```sql
Tables:
├── vehicles (id, make, model, year, price, image_url)
├── users (id, email, password_hash, role)
├── bookings (id, user_id, vehicle_id, date, status)
└── test_drives (id, booking_id, location, time)
```

---

## Terragrunt Configuration Examples

### Root terragrunt.hcl
```hcl
# Remote state configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = "auto-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "auto-terraform-locks"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.aws_region
}
EOF
}
```

### Environment-specific: dev/ap-south-1/vpc/terragrunt.hcl
```hcl
include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/vpc.hcl"
}

inputs = {
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization
  
  tags = {
    Project     = "automobile-platform"
    Environment = "dev"
    ManagedBy   = "terragrunt"
  }
}
```

---

## GitOps Workflow

### 1. Pull Request (Plan Phase)
```
Developer → Feature Branch → Push → GitHub
                                      ↓
                              GitHub Actions
                                      ↓
                    ┌─────────────────┴─────────────────┐
                    ↓                                   ↓
            terraform fmt                      terraform validate
                    ↓                                   ↓
            terraform plan                        tfsec scan
                    ↓                                   ↓
            Comment on PR ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                    ↓
            Team Review & Approval
```

### 2. Merge (Apply Phase)
```
PR Merged → main branch
              ↓
      GitHub Actions
              ↓
    terraform apply -auto-approve
              ↓
    Infrastructure Updated ✅
```

---

## Implementation Phases

### Phase 1: Setup & Foundation (Days 1-3)
- [ ] Create GitHub repository
- [ ] Setup Terraform backend (S3 + DynamoDB)
- [ ] Create VPC module
- [ ] Create common/tags module
- [ ] Setup Terragrunt structure
- [ ] Configure GitHub Actions

### Phase 2: Compute Infrastructure (Days 4-6)
- [ ] Create ECS/EKS module
- [ ] Create ALB module
- [ ] Create ECR module
- [ ] Deploy dev environment
- [ ] Test infrastructure

### Phase 3: Database & Storage (Days 7-9)
- [ ] Create RDS module
- [ ] Create S3 module
- [ ] Setup database schema
- [ ] Configure backups

### Phase 4: Application Development (Days 10-14)
- [ ] Build backend API
- [ ] Build frontend app
- [ ] Create Dockerfiles
- [ ] Setup docker-compose for local dev
- [ ] Write unit tests

### Phase 5: CI/CD Pipeline (Days 15-17)
- [ ] Complete GitHub Actions workflows
- [ ] Automated Docker builds
- [ ] Automated deployments
- [ ] Integration tests

### Phase 6: Production Deployment (Days 18-21)
- [ ] Deploy prod environment
- [ ] Configure monitoring (CloudWatch)
- [ ] Setup logging
- [ ] Performance testing
- [ ] Documentation

---

## Naming Conventions

### Resources
```
Format: auto-${env}-${service}-${resource}

Examples:
- auto-dev-vpc
- auto-prod-eks-cluster
- auto-dev-alb-public
- auto-prod-rds-postgres
- auto-dev-ecr-backend
```

### Tags (All Resources)
```hcl
tags = {
  Project     = "automobile-platform"
  Environment = "dev" | "prod"
  ManagedBy   = "terragrunt"
  Application = "backend" | "frontend"
  CostCenter  = "engineering"
  Owner       = "devops-team"
}
```

---

## Security Best Practices

✅ IAM roles with least privilege
✅ Secrets in AWS Secrets Manager
✅ VPC with private subnets
✅ Security groups (principle of least access)
✅ Encryption at rest (RDS, S3)
✅ Encryption in transit (TLS/SSL)
✅ No hardcoded credentials
✅ MFA for AWS console access
✅ CloudTrail enabled
✅ GuardDuty for threat detection

---

## Monitoring & Logging

- **CloudWatch Logs**: Application logs
- **CloudWatch Metrics**: Infrastructure metrics
- **CloudWatch Alarms**: Alert on thresholds
- **X-Ray**: Distributed tracing (optional)
- **Cost Explorer**: Track spending

---

## Interview Talking Points

### Technical Skills Demonstrated
1. **Infrastructure as Code**: Modular Terraform + Terragrunt
2. **GitOps**: PR-based workflow with automated deployments
3. **AWS Services**: VPC, ECS/EKS, RDS, ALB, ECR, S3, Route53
4. **CI/CD**: GitHub Actions pipelines
5. **Containerization**: Docker, multi-stage builds
6. **Security**: IAM, secrets management, network isolation
7. **Cost Optimization**: Free tier usage, right-sizing
8. **Monitoring**: CloudWatch integration

### Key Questions You Can Answer
- How do you manage Terraform state across environments?
- Explain your GitOps workflow
- How do you handle secrets in infrastructure code?
- What's your disaster recovery strategy?
- How do you ensure infrastructure security?
- Explain your module versioning approach
- How do you optimize AWS costs?
- What's your testing strategy for infrastructure?

---

## Cost Management

### Free Tier Limits (12 months)
- EC2: 750 hours/month (t2.micro)
- RDS: 750 hours/month (t3.micro)
- S3: 5GB storage
- ALB: 750 hours/month
- ECR: 500MB storage

### Cost Optimization Tips
1. Use t2.micro/t3.micro instances
2. Single NAT Gateway (not per AZ)
3. Delete unused resources
4. Use S3 lifecycle policies
5. Enable cost allocation tags
6. Set up billing alerts

---

## Success Criteria

✅ Infrastructure fully automated with Terraform + Terragrunt
✅ Working automobile application (frontend + backend + database)
✅ PR-based GitOps workflow functional
✅ All code in GitHub with documentation
✅ Can demo end-to-end in 15 minutes
✅ Costs under $50/month (or free)
✅ Security best practices implemented
✅ Monitoring and logging configured
✅ Interview-ready explanations prepared

---

## Next Steps

**Ready to start building?**

1. ✅ Confirm compute option (EC2/ECS/EKS)
2. ✅ Create repository structure
3. ✅ Build Terraform modules
4. ✅ Setup Terragrunt configurations
5. ✅ Develop automobile application
6. ✅ Configure CI/CD pipelines
7. ✅ Deploy and test

**Which compute option do you want to start with?**
- Option 1: EC2 + Docker (FREE)
- Option 2: ECS Fargate ($20-40/month)
- Option 3: EKS ($120-150/month)
