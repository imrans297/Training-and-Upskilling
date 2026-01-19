# 05. Modules and Workspaces

## Part 1: Terraform Modules

### What are Modules?

**Module** = Container for multiple resources used together.

**Purpose**:
- Code reusability
- Organization
- Encapsulation
- Standardization
- Sharing across teams

**Every Terraform configuration has at least one module**: the **root module** (files in working directory).

---

### Module Structure

**Basic Module Structure**:
```
modules/
└── vpc/
    ├── main.tf       # Resources
    ├── variables.tf  # Input variables
    ├── outputs.tf    # Output values
    └── README.md     # Documentation
```

**Example VPC Module**:

**modules/vpc/main.tf**:
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-${count.index + 1}"
      Type = "Public"
    }
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-private-${count.index + 1}"
      Type = "Private"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

**modules/vpc/variables.tf**:
```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

**modules/vpc/outputs.tf**:
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
```

---

### Using Modules

**Call Module in Root Configuration**:

**main.tf**:
```hcl
provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_name             = "production-vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Use module outputs
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.public_subnet_ids[0]
  
  tags = {
    Name = "WebServer"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
```

---

### Module Sources

**1. Local Path**:
```hcl
module "vpc" {
  source = "./modules/vpc"
}
```

**2. Terraform Registry**:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

**3. GitHub**:
```hcl
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"
}

# Specific branch/tag
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.0.0"
}
```

**4. Git (Generic)**:
```hcl
module "vpc" {
  source = "git::https://example.com/vpc.git"
}

# With SSH
module "vpc" {
  source = "git::ssh://git@github.com/user/repo.git"
}
```

**5. S3 Bucket**:
```hcl
module "vpc" {
  source = "s3::https://s3.amazonaws.com/my-bucket/vpc-module.zip"
}
```

**6. HTTP URL**:
```hcl
module "vpc" {
  source = "https://example.com/vpc-module.zip"
}
```

---

### Module Versioning

**Specify Version**:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"  # Exact version
}
```

**Version Constraints**:
```hcl
version = ">= 5.0.0"         # Greater than or equal
version = "~> 5.0"           # Any 5.x version
version = ">= 5.0, < 6.0"    # Range
```

---

### Module Best Practices

**1. Single Responsibility**:
```
✅ Good: modules/vpc, modules/ec2, modules/rds
❌ Bad: modules/everything
```

**2. Clear Inputs/Outputs**:
```hcl
# Good: Descriptive variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

# Bad: Unclear variables
variable "cidr" {
  type = string
}
```

**3. Sensible Defaults**:
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"  # Sensible default
}
```

**4. Documentation**:
```markdown
# VPC Module

Creates a VPC with public and private subnets.

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name = "my-vpc"
  vpc_cidr = "10.0.0.0/16"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| vpc_name | Name of VPC | string | n/a |
| vpc_cidr | CIDR block | string | 10.0.0.0/16 |
```

---

## Part 2: Terraform Workspaces

### What are Workspaces?

**Workspace** = Named container for Terraform state.

**Purpose**:
- Manage multiple environments (dev, staging, prod)
- Same configuration, different state
- Isolate infrastructure instances

**Default Workspace**: `default` (always exists)

---

### Workspace Commands

**List Workspaces**:
```bash
terraform workspace list
# Output:
# * default
#   dev
#   prod
```

**Create Workspace**:
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

**Switch Workspace**:
```bash
terraform workspace select dev
```

**Show Current Workspace**:
```bash
terraform workspace show
```

**Delete Workspace**:
```bash
terraform workspace delete dev
```

---

### Using Workspaces in Configuration

**Access Current Workspace**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = terraform.workspace == "prod" ? "t2.large" : "t2.micro"
  
  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

**Workspace-Specific Variables**:
```hcl
locals {
  env_config = {
    dev = {
      instance_type = "t2.micro"
      instance_count = 1
    }
    staging = {
      instance_type = "t2.small"
      instance_count = 2
    }
    prod = {
      instance_type = "t2.large"
      instance_count = 5
    }
  }
  
  config = local.env_config[terraform.workspace]
}

resource "aws_instance" "web" {
  count         = local.config.instance_count
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = local.config.instance_type
  
  tags = {
    Name = "web-${terraform.workspace}-${count.index}"
  }
}
```

---

### Workspace State Files

**State File Location**:
```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

**Default workspace**: `terraform.tfstate` (root directory)

---

### Workspace Use Cases

**✅ Good Use Cases**:

1. **Multiple Environments**:
```bash
terraform workspace new dev
terraform apply  # Deploy dev environment

terraform workspace new prod
terraform apply  # Deploy prod environment
```

2. **Testing Changes**:
```bash
terraform workspace new test-feature
terraform apply  # Test in isolated environment
terraform workspace select default
```

3. **Temporary Environments**:
```bash
terraform workspace new demo
terraform apply
# After demo
terraform destroy
terraform workspace delete demo
```

**❌ Not Recommended For**:

1. **Different Configurations**: Use separate directories
2. **Different Regions**: Use separate state files
3. **Different Accounts**: Use separate backends
4. **Long-term Isolation**: Use separate projects

---

### Workspace Workflow Example

**Project Structure**:
```
project/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

**main.tf**:
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

locals {
  environment = terraform.workspace
  
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidrs[local.environment]
  
  tags = merge(
    local.common_tags,
    {
      Name = "vpc-${local.environment}"
    }
  )
}

resource "aws_instance" "web" {
  count         = var.instance_counts[local.environment]
  ami           = var.ami_id
  instance_type = var.instance_types[local.environment]
  
  tags = merge(
    local.common_tags,
    {
      Name = "web-${local.environment}-${count.index + 1}"
    }
  )
}
```

**variables.tf**:
```hcl
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

variable "vpc_cidrs" {
  description = "VPC CIDR blocks per environment"
  type        = map(string)
  default = {
    dev     = "10.0.0.0/16"
    staging = "10.1.0.0/16"
    prod    = "10.2.0.0/16"
  }
}

variable "instance_types" {
  description = "Instance types per environment"
  type        = map(string)
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  }
}

variable "instance_counts" {
  description = "Instance counts per environment"
  type        = map(number)
  default = {
    dev     = 1
    staging = 2
    prod    = 5
  }
}
```

**Deployment**:
```bash
# Deploy dev
terraform workspace new dev
terraform apply

# Deploy staging
terraform workspace new staging
terraform apply

# Deploy prod
terraform workspace new prod
terraform apply

# Switch between environments
terraform workspace select dev
terraform plan

terraform workspace select prod
terraform plan
```

---

## Hands-on Lab 5: Modules and Workspaces

### Objective
Create reusable VPC module and deploy to multiple environments using workspaces.

### Project Structure
```
lab5-modules-workspaces/
├── main.tf
├── variables.tf
├── outputs.tf
└── modules/
    └── vpc/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Step 1: Create VPC Module

**modules/vpc/main.tf**:
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-${count.index + 1}"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

**modules/vpc/variables.tf**:
```hcl
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
```

**modules/vpc/outputs.tf**:
```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
```

### Step 2: Root Configuration

**main.tf**:
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

locals {
  environment = terraform.workspace
  
  env_config = {
    dev = {
      vpc_cidr      = "10.0.0.0/16"
      instance_type = "t2.micro"
      instance_count = 1
    }
    staging = {
      vpc_cidr      = "10.1.0.0/16"
      instance_type = "t2.small"
      instance_count = 2
    }
    prod = {
      vpc_cidr      = "10.2.0.0/16"
      instance_type = "t2.large"
      instance_count = 3
    }
  }
  
  config = local.env_config[local.environment]
  
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_name = "lab5-${local.environment}"
  vpc_cidr = local.config.vpc_cidr
  tags     = local.common_tags
}

resource "aws_instance" "app" {
  count         = local.config.instance_count
  ami           = var.ami_id
  instance_type = local.config.instance_type
  subnet_id     = module.vpc.public_subnet_ids[count.index % length(module.vpc.public_subnet_ids)]
  
  tags = merge(
    local.common_tags,
    {
      Name = "app-${local.environment}-${count.index + 1}"
    }
  )
}
```

**variables.tf**:
```hcl
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
```

**outputs.tf**:
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "instance_ids" {
  description = "Instance IDs"
  value       = aws_instance.app[*].id
}

output "instance_ips" {
  description = "Instance public IPs"
  value       = aws_instance.app[*].public_ip
}
```

### Step 3: Deploy to Multiple Environments

```bash
# Initialize
terraform init

# Create and deploy dev environment
terraform workspace new dev
terraform plan
terraform apply -auto-approve

# View outputs
terraform output

# Create and deploy staging
terraform workspace new staging
terraform apply -auto-approve

# Create and deploy prod
terraform workspace new prod
terraform apply -auto-approve

# List all workspaces
terraform workspace list

# Compare environments
terraform workspace select dev
terraform show | grep instance_type

terraform workspace select prod
terraform show | grep instance_type

# Destroy specific environment
terraform workspace select dev
terraform destroy -auto-approve

# Cleanup
terraform workspace select default
terraform workspace delete dev
terraform workspace delete staging
terraform workspace delete prod
```

---

## Key Takeaways

✅ Modules enable code reusability and organization  
✅ Module sources: local, registry, git, S3, HTTP  
✅ Always version modules from registry  
✅ Workspaces manage multiple state files  
✅ Use workspaces for similar environments  
✅ Access workspace name with `terraform.workspace`  
✅ Each workspace has separate state file  
✅ Don't use workspaces for completely different configs

## Next Section

[06. Remote State Management](../06-Remote-State-Management/)
