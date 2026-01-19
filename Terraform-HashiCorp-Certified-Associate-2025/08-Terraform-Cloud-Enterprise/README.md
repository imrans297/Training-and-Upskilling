# 08. Terraform Cloud and Enterprise

## What is Terraform Cloud?

**Terraform Cloud** = SaaS platform for team collaboration on Terraform.

**Key Features**:
- Remote state management
- Remote execution
- VCS integration
- Private module registry
- Sentinel policy as code
- Cost estimation
- Team management

**Free Tier**: Up to 5 users

---

## Terraform Cloud vs CLI

| Feature | CLI (Local) | Terraform Cloud |
|---------|-------------|-----------------|
| State Storage | Local/S3 | Managed |
| Execution | Local machine | Cloud runners |
| Collaboration | Manual | Built-in |
| VCS Integration | Manual | Automatic |
| Policy Enforcement | Manual | Sentinel |
| Cost Estimation | No | Yes |
| Private Registry | No | Yes |

---

## Getting Started

### 1. Create Account

```bash
# Sign up at https://app.terraform.io

# Login via CLI
terraform login
```

### 2. Create Organization

- Go to https://app.terraform.io
- Click "Create Organization"
- Enter organization name

### 3. Create Workspace

**Via UI**:
1. Click "New Workspace"
2. Choose workflow (VCS, CLI, API)
3. Configure settings

**Via Code**:
```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "my-workspace"
    }
  }
}
```

---

## Workspace Types

### 1. VCS-Driven Workflow

**Best for**: GitOps, team collaboration

**Configuration**:
```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "production"
    }
  }
}
```

**Setup**:
1. Connect VCS (GitHub, GitLab, Bitbucket)
2. Select repository
3. Configure trigger paths
4. Push code → Auto-run

### 2. CLI-Driven Workflow

**Best for**: Local development, testing

**Configuration**:
```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "dev"
    }
  }
}
```

**Usage**:
```bash
terraform init
terraform plan   # Runs in cloud
terraform apply  # Runs in cloud
```

### 3. API-Driven Workflow

**Best for**: CI/CD integration, automation

**Using API**:
```bash
curl \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @payload.json \
  https://app.terraform.io/api/v2/runs
```

---

## Remote Operations

### What are Remote Operations?

**Remote operations** = Terraform runs execute in Terraform Cloud, not locally.

**Benefits**:
- Consistent environment
- No local dependencies
- Centralized logs
- Better security

### Enable Remote Operations

```hcl
terraform {
  cloud {
    organization = "my-org"
    
    workspaces {
      name = "production"
    }
  }
}
```

**Execution Mode**:
- **Remote**: Runs in Terraform Cloud (default)
- **Local**: Runs locally, state in cloud

---

## VCS Integration

### Connect GitHub

**Steps**:
1. Workspace Settings → Version Control
2. Connect to VCS → GitHub
3. Authorize Terraform Cloud
4. Select repository
5. Configure settings

**Auto-Trigger Settings**:
```hcl
# Trigger on specific paths
trigger_paths = [
  "terraform/**",
  "modules/**"
]

# Working directory
working_directory = "terraform/production"

# Auto-apply
auto_apply = false  # Require manual approval
```

### Workflow

```
1. Developer pushes code to GitHub
2. Terraform Cloud detects change
3. Automatically runs terraform plan
4. Team reviews plan
5. Approve → terraform apply
```

---

## Variables in Terraform Cloud

### Terraform Variables

**Set via UI**:
1. Workspace → Variables
2. Add Variable
3. Key: `instance_type`
4. Value: `t2.micro`
5. Category: Terraform

**Set via CLI**:
```bash
terraform cloud workspace variable create \
  -name instance_type \
  -value t2.micro \
  -category terraform
```

### Environment Variables

**For AWS credentials**:
```
AWS_ACCESS_KEY_ID     = <access-key>
AWS_SECRET_ACCESS_KEY = <secret-key> (sensitive)
AWS_DEFAULT_REGION    = us-east-1
```

**Mark as Sensitive**: Checkbox for secrets

---

## Sentinel Policy as Code

### What is Sentinel?

**Sentinel** = Policy as code framework for governance.

**Use Cases**:
- Enforce tagging standards
- Restrict instance types
- Require encryption
- Cost controls
- Compliance checks

### Sentinel Policy Example

**require-tags.sentinel**:
```sentinel
import "tfplan/v2" as tfplan

# Get all EC2 instances
ec2_instances = filter tfplan.resource_changes as _, rc {
  rc.type is "aws_instance" and
  rc.mode is "managed" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

# Rule: All instances must have Name and Environment tags
main = rule {
  all ec2_instances as _, instance {
    instance.change.after.tags contains "Name" and
    instance.change.after.tags contains "Environment"
  }
}
```

**Policy Set**:
```hcl
policy "require-tags" {
  enforcement_level = "hard"  # hard, soft, advisory
}
```

### Enforcement Levels

- **Advisory**: Warning only, doesn't block
- **Soft**: Can be overridden
- **Hard**: Cannot be overridden, blocks apply

---

## Cost Estimation

### Enable Cost Estimation

**Workspace Settings**:
1. Settings → Cost Estimation
2. Enable cost estimation
3. Set currency

**View Costs**:
- Shown in plan output
- Estimated monthly cost
- Cost difference from current

**Example Output**:
```
Cost Estimation:

Resources: 5 of 5 estimated
           $142.56/mo +$142.56

+ aws_instance.web
  +$73.00

+ aws_db_instance.main
  +$69.56
```

---

## Private Module Registry

### Publish Module

**1. Create Module Repository**:
```
terraform-aws-vpc/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

**2. Tag Release**:
```bash
git tag v1.0.0
git push origin v1.0.0
```

**3. Publish to Registry**:
1. Registry → Publish → Module
2. Connect VCS
3. Select repository
4. Publish

### Use Private Module

```hcl
module "vpc" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "1.0.0"
  
  vpc_name = "production"
  vpc_cidr = "10.0.0.0/16"
}
```

---

## Team Management

### Create Team

1. Settings → Teams
2. Create Team
3. Add members
4. Set permissions

### Permission Levels

**Organization**:
- Owners: Full access
- Members: Limited access

**Workspace**:
- Admin: Full workspace control
- Write: Can apply changes
- Plan: Can plan only
- Read: View only

---

## Hands-on Lab 8: Terraform Cloud Setup

### Objective
Set up Terraform Cloud workspace with VCS integration.

### Step 1: Create Terraform Cloud Account

```bash
# Sign up at https://app.terraform.io

# Login
terraform login
```

### Step 2: Create Organization

1. Go to https://app.terraform.io
2. Click "Create Organization"
3. Name: `lab8-org` (or your choice)

### Step 3: Create GitHub Repository

```bash
# Create new repo
mkdir terraform-cloud-lab
cd terraform-cloud-lab
git init

# Create Terraform files
cat > main.tf <<EOF
terraform {
  cloud {
    organization = "lab8-org"
    
    workspaces {
      name = "lab8-workspace"
    }
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = {
    Name        = "TerraformCloud-Lab"
    Environment = "Lab"
    ManagedBy   = "TerraformCloud"
  }
}
EOF

cat > variables.tf <<EOF
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"
}
EOF

cat > outputs.tf <<EOF
output "instance_id" {
  value = aws_instance.web.id
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
EOF

# Push to GitHub
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/terraform-cloud-lab.git
git push -u origin main
```

### Step 4: Create Workspace

1. Terraform Cloud → Workspaces → New Workspace
2. Choose "Version control workflow"
3. Connect to GitHub
4. Select repository: `terraform-cloud-lab`
5. Name workspace: `lab8-workspace`
6. Click "Create workspace"

### Step 5: Configure Variables

1. Workspace → Variables
2. Add Environment Variables:
   - `AWS_ACCESS_KEY_ID` = your-access-key
   - `AWS_SECRET_ACCESS_KEY` = your-secret-key (mark sensitive)
   - `AWS_DEFAULT_REGION` = us-east-1

### Step 6: Trigger Run

```bash
# Make a change
echo "# Updated" >> README.md
git add README.md
git commit -m "Trigger Terraform Cloud run"
git push

# Watch run in Terraform Cloud UI
```

### Step 7: Review and Apply

1. Go to Terraform Cloud
2. View the run
3. Review plan
4. Click "Confirm & Apply"
5. Enter comment
6. Confirm

### Step 8: View Outputs

1. Workspace → States → Latest
2. View outputs
3. Check AWS Console for instance

### Step 9: Cleanup

```bash
# Queue destroy plan
# In Terraform Cloud:
# Settings → Destruction and Deletion → Queue destroy plan
```

---

## Key Takeaways

✅ Terraform Cloud enables team collaboration  
✅ Remote operations provide consistent environment  
✅ VCS integration automates workflows  
✅ Sentinel enforces policies  
✅ Cost estimation before apply  
✅ Private registry for modules  
✅ Team management and permissions  
✅ Free tier available for small teams

## Next Section

[09. Terraform Challenges](../09-Terraform-Challenges/)
