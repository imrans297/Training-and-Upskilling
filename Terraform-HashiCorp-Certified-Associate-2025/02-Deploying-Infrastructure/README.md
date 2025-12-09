# 02. Deploying Infrastructure with Terraform

## Providers

### What is a Provider?

**Provider** = Plugin that enables Terraform to interact with APIs of cloud platforms and services.

**Purpose**:
- Translates Terraform config → API calls
- Manages authentication
- Handles resource lifecycle

### Provider Configuration

**Basic Provider**:
```hcl
provider "aws" {
  region = "us-east-1"
}
```

**Provider with Authentication**:
```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key  # Not recommended
  secret_key = var.aws_secret_key  # Not recommended
}
```

**Best Practice - Use AWS CLI Profile**:
```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}
```

**Multiple Provider Configurations**:
```hcl
# Default provider
provider "aws" {
  region = "us-east-1"
}

# Alias for different region
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Use aliased provider
resource "aws_instance" "west_server" {
  provider = aws.west
  ami      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### Provider Version Constraints

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Any 5.x version
    }
  }
}
```

**Version Operators**:
- `= 5.0.0` - Exact version
- `!= 5.0.0` - Exclude version
- `> 5.0.0` - Greater than
- `>= 5.0.0` - Greater than or equal
- `< 5.0.0` - Less than
- `<= 5.0.0` - Less than or equal
- `~> 5.0` - Any 5.x version (pessimistic constraint)

---

## Resources

### What is a Resource?

**Resource** = Infrastructure component (EC2, S3, VPC, etc.)

**Syntax**:
```hcl
resource "PROVIDER_TYPE" "NAME" {
  argument1 = value1
  argument2 = value2
}
```

### Resource Examples

**EC2 Instance**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}
```

**S3 Bucket**:
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-unique-bucket-12345"
  
  tags = {
    Environment = "Dev"
  }
}
```

**Security Group**:
```hcl
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Resource Meta-Arguments

**depends_on** - Explicit dependency:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  depends_on = [aws_security_group.web_sg]
}
```

**count** - Create multiple instances:
```hcl
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "Server-${count.index}"
  }
}
```

**for_each** - Create resources from map/set:
```hcl
resource "aws_instance" "server" {
  for_each = {
    web = "t2.micro"
    db  = "t2.small"
  }
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value
  
  tags = {
    Name = each.key
  }
}
```

**lifecycle** - Control resource behavior:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags]
  }
}
```

---

## Resource Dependencies

### Implicit Dependencies

Terraform automatically detects dependencies through resource references:

```hcl
resource "aws_security_group" "web_sg" {
  name = "web-sg"
}

resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # Implicit dependency
}
```

**Terraform knows**: Create security group first, then instance.

### Explicit Dependencies

Use `depends_on` when implicit dependency isn't detected:

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  depends_on = [aws_s3_bucket.data]  # Explicit dependency
}
```

---

## Variables

### What are Variables?

**Variables** = Input parameters for Terraform configurations.

**Why use variables?**
- Reusability
- Flexibility
- Environment-specific values
- Avoid hardcoding

### Variable Declaration

**variables.tf**:
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {
    Environment = "Dev"
    Project     = "MyApp"
  }
}
```

### Variable Types

**Primitive Types**:
- `string` - Text
- `number` - Numeric
- `bool` - true/false

**Complex Types**:
- `list(type)` - Ordered collection
- `set(type)` - Unordered unique collection
- `map(type)` - Key-value pairs
- `object({...})` - Structured data
- `tuple([...])` - Fixed-length collection

**Example - Object Type**:
```hcl
variable "instance_config" {
  type = object({
    ami           = string
    instance_type = string
    monitoring    = bool
  })
  
  default = {
    ami           = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    monitoring    = false
  }
}
```

### Using Variables

**In Configuration**:
```hcl
resource "aws_instance" "web" {
  ami           = var.instance_config.ami
  instance_type = var.instance_type
  count         = var.instance_count
  
  tags = var.tags
}
```

### Providing Variable Values

**1. terraform.tfvars**:
```hcl
instance_type = "t2.small"
instance_count = 3
```

**2. Command Line**:
```bash
terraform apply -var="instance_type=t2.small" -var="instance_count=3"
```

**3. Environment Variables**:
```bash
export TF_VAR_instance_type="t2.small"
export TF_VAR_instance_count=3
terraform apply
```

**4. Variable Files**:
```bash
terraform apply -var-file="prod.tfvars"
```

### Variable Validation

```hcl
variable "instance_type" {
  type = string
  
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}
```

---

## Outputs

### What are Outputs?

**Outputs** = Values exported after Terraform apply.

**Purpose**:
- Display important information
- Pass values to other configurations
- Use in automation scripts

### Output Declaration

**outputs.tf**:
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = aws_instance.web.private_ip
  sensitive   = true  # Hide from console output
}
```

### Viewing Outputs

```bash
# After apply
terraform output

# Specific output
terraform output instance_public_ip

# JSON format
terraform output -json
```

### Output with Count/For_each

**With count**:
```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

output "all_instance_ids" {
  value = aws_instance.web[*].id
}
```

**With for_each**:
```hcl
resource "aws_instance" "web" {
  for_each = toset(["web", "app", "db"])
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = each.key
  }
}

output "instance_ips" {
  value = {
    for k, v in aws_instance.web : k => v.public_ip
  }
}
```

---

## Data Sources

### What are Data Sources?

**Data Sources** = Fetch information from existing resources.

**Purpose**:
- Query existing infrastructure
- Use external data
- Reference resources not managed by Terraform

### Data Source Examples

**Fetch Latest AMI**:
```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
}
```

**Fetch VPC Information**:
```hcl
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}
```

**Fetch Availability Zones**:
```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

output "azs" {
  value = data.aws_availability_zones.available.names
}
```

---

## Hands-on Lab 2: Complete Web Application Infrastructure

### Objective
Deploy a complete web application with:
- VPC with public/private subnets
- Security groups
- EC2 instance with user data
- S3 bucket for static files
- Outputs for important values

### Project Structure
```
lab2-web-app/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
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

# Data source - Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP and SSH"
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
              echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>" >> /var/www/html/index.html
              EOF
  
  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
  }
}

# S3 Bucket
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.project_name}-static-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "${var.project_name}-static-files"
    Environment = var.environment
  }
}

# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mywebapp"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ssh_cidr" {
  description = "CIDR block for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}
```

### outputs.tf
```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of web server"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${aws_instance.web.public_ip}"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.static_files.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web_sg.id
}
```

### terraform.tfvars
```hcl
aws_region    = "us-east-1"
project_name  = "mywebapp"
environment   = "dev"
instance_type = "t2.micro"
ssh_cidr      = "0.0.0.0/0"  # Change to your IP for security
```

### Deployment Steps

```bash
# 1. Initialize
terraform init

# 2. Validate configuration
terraform validate

# 3. Format code
terraform fmt

# 4. Plan
terraform plan

# 5. Apply
terraform apply -auto-approve

# 6. Get outputs
terraform output

# 7. Test website
curl $(terraform output -raw website_url)

# 8. Destroy when done
terraform destroy -auto-approve
```

---

## Key Takeaways

✅ Providers enable Terraform to interact with APIs  
✅ Resources are infrastructure components  
✅ Variables make configurations reusable  
✅ Outputs display important information  
✅ Data sources fetch existing resource info  
✅ Dependencies can be implicit or explicit  
✅ Use meta-arguments (count, for_each) for multiple resources

## Next Section

[03. Read, Generate, Modify Configurations](../03-Read-Generate-Modify-Configurations/)
