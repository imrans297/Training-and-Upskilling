# 07. Security Primer

## Sensitive Data in Terraform

### What is Sensitive Data?

**Sensitive data** includes:
- Passwords and API keys
- Database credentials
- Private keys and certificates
- Access tokens
- Encryption keys

### Marking Outputs as Sensitive

```hcl
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true  # Hidden from console output
}
```

**Result**:
```bash
terraform output
# db_password = <sensitive>

# View sensitive output
terraform output -raw db_password
```

### Sensitive Variables

```hcl
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

---

## Managing Secrets

### 1. Environment Variables

**Best for**: Local development, CI/CD pipelines

```bash
# Set environment variable
export TF_VAR_db_password="MySecretPassword123"

# Use in Terraform
terraform apply
```

**Configuration**:
```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_db_instance" "main" {
  password = var.db_password
}
```

### 2. AWS Secrets Manager

**Best for**: Production secrets, rotation

**Store Secret**:
```bash
aws secretsmanager create-secret \
  --name prod/db/password \
  --secret-string "MySecretPassword123"
```

**Retrieve in Terraform**:
```hcl
data "aws_secretsmanager_secret" "db_password" {
  name = "prod/db/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

### 3. AWS Systems Manager Parameter Store

**Best for**: Configuration values, simple secrets

**Store Parameter**:
```bash
aws ssm put-parameter \
  --name /prod/db/password \
  --value "MySecretPassword123" \
  --type SecureString
```

**Retrieve in Terraform**:
```hcl
data "aws_ssm_parameter" "db_password" {
  name = "/prod/db/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_ssm_parameter.db_password.value
}
```

### 4. HashiCorp Vault

**Best for**: Enterprise secrets management

**Vault Provider**:
```hcl
provider "vault" {
  address = "https://vault.example.com"
}

data "vault_generic_secret" "db_password" {
  path = "secret/database/password"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db_password.data["password"]
}
```

---

## .gitignore Best Practices

**Essential .gitignore**:
```gitignore
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files (may contain sensitive data)
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc

# Ignore Mac .DS_Store files
.DS_Store

# Ignore plan files
*.tfplan

# Ignore any files with "secret" in name
*secret*
*private*
```

**What to commit**:
- ✅ `.tf` files
- ✅ `.tf.example` files
- ✅ `README.md`
- ✅ `.terraform.lock.hcl`

**What NOT to commit**:
- ❌ `.tfstate` files
- ❌ `.tfvars` files with secrets
- ❌ Private keys
- ❌ Credentials

---

## Secure Variable Files

### terraform.tfvars.example

**Commit this**:
```hcl
# terraform.tfvars.example
aws_region    = "us-east-1"
instance_type = "t2.micro"
db_username   = "admin"
db_password   = "CHANGE_ME"  # Change before use
```

**Don't commit this**:
```hcl
# terraform.tfvars (in .gitignore)
aws_region    = "us-east-1"
instance_type = "t2.micro"
db_username   = "admin"
db_password   = "ActualSecretPassword123"
```

---

## IAM Best Practices

### Least Privilege

**Bad** (too permissive):
```hcl
resource "aws_iam_policy" "bad" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}
```

**Good** (specific permissions):
```hcl
resource "aws_iam_policy" "good" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "arn:aws:ec2:us-east-1:123456789012:instance/*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Environment" = "Production"
          }
        }
      }
    ]
  })
}
```

### Use IAM Roles

**For EC2**:
```hcl
resource "aws_iam_role" "ec2_role" {
  name = "ec2-app-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-app-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app" {
  ami                  = "ami-0c55b159cbfafe1f0"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
}
```

---

## Encryption

### Encrypt State File

**S3 Backend with Encryption**:
```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true  # Server-side encryption
  }
}
```

### Encrypt Resources

**EBS Volume**:
```hcl
resource "aws_ebs_volume" "encrypted" {
  availability_zone = "us-east-1a"
  size              = 10
  encrypted         = true
  kms_key_id        = aws_kms_key.main.arn
}
```

**S3 Bucket**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}
```

---

## Hands-on Lab 7: Secure Secrets Management

### Objective
Implement secure secrets management using AWS Secrets Manager.

### Project Structure
```
lab7-security/
├── main.tf
├── variables.tf
├── outputs.tf
├── secrets.tf
└── terraform.tfvars.example
```

### secrets.tf
```hcl
# Create secret in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "lab7/db/credentials"
  recovery_window_in_days = 7
  
  tags = {
    Name        = "Database Credentials"
    Environment = "Lab"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# Retrieve secret
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id  = aws_secretsmanager_secret.db_credentials.id
  depends_on = [aws_secretsmanager_secret_version.db_credentials]
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}
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

# RDS instance using secrets
resource "aws_db_instance" "main" {
  identifier        = "lab7-database"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  
  db_name  = "myapp"
  username = local.db_creds.username
  password = local.db_creds.password
  
  skip_final_snapshot = true
  
  tags = {
    Name = "Lab7-Database"
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

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

### outputs.tf
```hcl
output "db_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.main.endpoint
}

output "secret_arn" {
  description = "Secrets Manager ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

# Don't output password directly
output "db_password" {
  description = "Database password (sensitive)"
  value       = "Stored in Secrets Manager"
}
```

### terraform.tfvars.example
```hcl
aws_region  = "us-east-1"
db_username = "admin"
db_password = "CHANGE_ME_TO_STRONG_PASSWORD"
```

### Deployment
```bash
# 1. Copy example file
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars with real password
nano terraform.tfvars

# 3. Initialize
terraform init

# 4. Apply
terraform apply

# 5. Verify secret in AWS
aws secretsmanager get-secret-value \
  --secret-id lab7/db/credentials

# 6. Cleanup
terraform destroy
```

---

## Security Checklist

### Before Deployment
- [ ] No hardcoded secrets in `.tf` files
- [ ] Sensitive variables marked as `sensitive = true`
- [ ] `.gitignore` configured properly
- [ ] Secrets stored in Secrets Manager/Vault
- [ ] IAM roles use least privilege
- [ ] Encryption enabled for state and resources

### After Deployment
- [ ] Review IAM policies
- [ ] Enable CloudTrail logging
- [ ] Set up AWS Config rules
- [ ] Enable GuardDuty
- [ ] Regular security audits
- [ ] Rotate secrets periodically

---

## Key Takeaways

✅ Never commit secrets to version control  
✅ Use Secrets Manager/Vault for production  
✅ Mark sensitive variables and outputs  
✅ Enable encryption for state and resources  
✅ Follow least privilege for IAM  
✅ Use IAM roles instead of access keys  
✅ Maintain proper .gitignore  
✅ Regular security audits

## Next Section

[08. Terraform Cloud and Enterprise](../08-Terraform-Cloud-Enterprise/)
