# 01. Introduction to Terraform

## What is Infrastructure as Code (IaC)?

**Definition**: Managing and provisioning infrastructure through code instead of manual processes.

**Benefits**:
- **Version Control**: Track changes over time
- **Automation**: Reduce manual errors
- **Consistency**: Same infrastructure every time
- **Speed**: Deploy in minutes, not hours
- **Documentation**: Code is documentation

**Example Without IaC**:
```
1. Login to AWS Console
2. Click EC2 → Launch Instance
3. Select AMI, instance type, VPC, subnet
4. Configure security groups
5. Add tags
6. Launch
7. Repeat for each environment (dev, staging, prod)
```

**Example With IaC (Terraform)**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

---

## What is Terraform?

**Terraform** is an open-source Infrastructure as Code tool by HashiCorp.

**Key Features**:
- **Declarative**: Describe desired state, Terraform figures out how
- **Multi-cloud**: AWS, Azure, GCP, and 1000+ providers
- **State Management**: Tracks real infrastructure
- **Plan Before Apply**: Preview changes before execution
- **Resource Graph**: Understands dependencies

**Use Cases**:
- Provision cloud infrastructure
- Manage Kubernetes clusters
- Configure networking
- Deploy applications
- Multi-cloud deployments

---

## Terraform vs Other IaC Tools

### Terraform vs CloudFormation

| Feature | Terraform | CloudFormation |
|---------|-----------|----------------|
| Cloud Support | Multi-cloud | AWS only |
| Language | HCL (human-readable) | JSON/YAML |
| State | Explicit state file | Implicit (AWS managed) |
| Modularity | Excellent | Limited |
| Community | Large | AWS-focused |

### Terraform vs Ansible

| Feature | Terraform | Ansible |
|---------|-----------|---------|
| Purpose | Infrastructure provisioning | Configuration management |
| Approach | Declarative | Procedural |
| State | Stateful | Stateless |
| Idempotency | Built-in | Requires careful coding |
| Best For | Creating infrastructure | Configuring servers |

**When to Use Both**:
```
Terraform → Provision EC2 instances
Ansible → Install and configure software on instances
```

---

## Terraform Architecture

```
┌─────────────────┐
│  Terraform CLI  │
└────────┬────────┘
         │
    ┌────▼────┐
    │  Core   │ ← Reads configuration
    └────┬────┘
         │
    ┌────▼────────────┐
    │   Providers     │ ← AWS, Azure, GCP
    └────┬────────────┘
         │
    ┌────▼────────────┐
    │  Infrastructure │ ← Actual resources
    └─────────────────┘
```

**Components**:

1. **Terraform Core**: 
   - Reads configuration files
   - Builds resource graph
   - Plans and applies changes

2. **Providers**: 
   - Plugins for specific platforms
   - Translate Terraform → API calls
   - Examples: AWS, Azure, Kubernetes

3. **State**: 
   - Tracks current infrastructure
   - Maps config to real resources
   - Stored in `terraform.tfstate`

---

## Installation

### Linux
```bash
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

### macOS
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
```

### Windows
```powershell
choco install terraform
terraform version
```

### Verify Installation
```bash
terraform version
# Output: Terraform v1.7.0
```

---

## Terraform Workflow

### 1. Write Configuration
```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### 2. Initialize
```bash
terraform init
```
**What it does**:
- Downloads provider plugins
- Initializes backend
- Prepares working directory

### 3. Plan
```bash
terraform plan
```
**What it does**:
- Shows what will be created/modified/destroyed
- No actual changes made
- Preview before execution

### 4. Apply
```bash
terraform apply
```
**What it does**:
- Executes the plan
- Creates/modifies infrastructure
- Updates state file

### 5. Destroy
```bash
terraform destroy
```
**What it does**:
- Removes all managed infrastructure
- Cleans up resources
- Updates state file

---

## Terraform Configuration Language (HCL)

### Basic Syntax

**Block Structure**:
```hcl
<BLOCK_TYPE> "<BLOCK_LABEL>" "<BLOCK_LABEL>" {
  # Block body
  <IDENTIFIER> = <EXPRESSION>
}
```

**Example**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

### Block Types

1. **Provider Block**:
```hcl
provider "aws" {
  region = "us-east-1"
}
```

2. **Resource Block**:
```hcl
resource "aws_s3_bucket" "mybucket" {
  bucket = "my-unique-bucket-name"
}
```

3. **Data Block**:
```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}
```

4. **Variable Block**:
```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
```

5. **Output Block**:
```hcl
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

---

## First Terraform Project

### Project Structure
```
my-first-terraform/
├── main.tf          # Main configuration
├── variables.tf     # Variable definitions
├── outputs.tf       # Output definitions
├── terraform.tfvars # Variable values
└── .gitignore       # Git ignore file
```

### main.tf
```hcl
terraform {
  required_version = ">= 1.0"
  
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
    Name        = "MyFirstInstance"
    Environment = "Learning"
  }
}
```

### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### outputs.tf
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}
```

### terraform.tfvars
```hcl
aws_region    = "us-east-1"
ami_id        = "ami-0c55b159cbfafe1f0"
instance_type = "t2.micro"
```

### .gitignore
```
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log

# Exclude all .tfvars files
*.tfvars

# Ignore CLI configuration files
.terraformrc
terraform.rc
```

---

## Hands-on Lab 1: Deploy Your First EC2 Instance

### Prerequisites
- AWS account
- AWS CLI configured
- Terraform installed

### Step 1: Create Project Directory
```bash
mkdir terraform-lab1
cd terraform-lab1
```

### Step 2: Create main.tf
```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "my_first_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"
  
  tags = {
    Name = "TerraformLab1"
  }
}

output "instance_public_ip" {
  value = aws_instance.my_first_instance.public_ip
}
```

### Step 3: Initialize Terraform
```bash
terraform init
```

**Expected Output**:
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.x.x...
Terraform has been successfully initialized!
```

### Step 4: Plan
```bash
terraform plan
```

**Review the output** - it shows what will be created.

### Step 5: Apply
```bash
terraform apply
```

Type `yes` when prompted.

### Step 6: Verify
```bash
# Check outputs
terraform output

# Verify in AWS Console
aws ec2 describe-instances --filters "Name=tag:Name,Values=TerraformLab1"
```

### Step 7: Destroy
```bash
terraform destroy
```

Type `yes` when prompted.

---

## Key Takeaways

✅ Terraform is declarative IaC tool  
✅ Supports multi-cloud providers  
✅ Uses HCL (human-readable) language  
✅ Workflow: init → plan → apply → destroy  
✅ State file tracks infrastructure  
✅ Always plan before apply  
✅ Version control your code, not state files

## Next Section

[02. Deploying Infrastructure with Terraform](../02-Deploying-Infrastructure/)
