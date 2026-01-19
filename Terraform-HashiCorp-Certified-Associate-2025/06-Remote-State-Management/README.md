# 06. Remote State Management

## Why Remote State?

**Local State Problems**:
- ❌ No collaboration (single developer)
- ❌ No locking (concurrent modifications)
- ❌ No encryption (sensitive data exposed)
- ❌ No versioning (hard to recover)
- ❌ Risk of loss (local file deletion)

**Remote State Benefits**:
- ✅ Team collaboration
- ✅ State locking
- ✅ Encryption at rest
- ✅ Versioning and backup
- ✅ Centralized management

---

## Backend Types

**Available Backends**:
- **S3** (AWS) - Most common
- **Terraform Cloud** - HashiCorp managed
- **Azure Blob Storage** (Azure)
- **Google Cloud Storage** (GCP)
- **Consul** (HashiCorp)
- **etcd**, **Kubernetes**, **PostgreSQL**, etc.

---

## S3 Backend Configuration

### Basic S3 Backend

**backend.tf**:
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### S3 Backend with DynamoDB Locking

**Why Locking?**
- Prevents concurrent state modifications
- Avoids state corruption
- Ensures consistency

**backend.tf**:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### Complete S3 Backend Setup

**Step 1: Create S3 Bucket**:
```hcl
# bootstrap/main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "Terraform State"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}

output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}
```

**Step 2: Create DynamoDB Table**:
```hcl
# bootstrap/dynamodb.tf
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "Terraform State Lock"
    Environment = "Production"
  }
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
```

**Step 3: Deploy Bootstrap**:
```bash
cd bootstrap
terraform init
terraform apply
```

**Step 4: Configure Backend in Main Project**:
```hcl
# main-project/backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-123456789012"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Step 5: Migrate State**:
```bash
cd main-project
terraform init  # Will prompt to migrate state
# Type 'yes' to copy state to S3
```

---

## Backend Configuration Options

### Partial Configuration

**Why?** Keep sensitive values out of version control.

**backend.tf** (no credentials):
```hcl
terraform {
  backend "s3" {
    # Bucket and region specified via CLI or config file
  }
}
```

**backend-config.hcl** (not in git):
```hcl
bucket         = "my-terraform-state-bucket"
key            = "prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
```

**Initialize with config**:
```bash
terraform init -backend-config=backend-config.hcl
```

**Or via CLI**:
```bash
terraform init \
  -backend-config="bucket=my-terraform-state-bucket" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-state-lock" \
  -backend-config="encrypt=true"
```

### Environment-Specific Backends

**dev-backend.hcl**:
```hcl
bucket = "terraform-state-dev"
key    = "dev/terraform.tfstate"
```

**prod-backend.hcl**:
```hcl
bucket = "terraform-state-prod"
key    = "prod/terraform.tfstate"
```

**Usage**:
```bash
terraform init -backend-config=dev-backend.hcl
terraform init -backend-config=prod-backend.hcl
```

---

## State Locking

### How Locking Works

1. **Acquire Lock**: Before state modification
2. **Perform Operation**: Apply/destroy
3. **Release Lock**: After completion

**DynamoDB Lock Entry**:
```json
{
  "LockID": "my-bucket/prod/terraform.tfstate-md5",
  "Info": "{\"ID\":\"abc123\",\"Operation\":\"OperationTypeApply\",\"Who\":\"user@example.com\",\"Version\":\"1.7.0\",\"Created\":\"2025-01-12T10:30:00Z\"}",
  "Digest": "abc123def456"
}
```

### Force Unlock

**When lock is stuck**:
```bash
terraform force-unlock LOCK_ID
```

**Example**:
```bash
# Get lock ID from error message
terraform force-unlock abc123-def456-ghi789
```

⚠️ **Warning**: Only use if you're sure no other process is running!

---

## State Encryption

### Encryption at Rest

**S3 Server-Side Encryption**:
```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true  # AES-256 encryption
  }
}
```

**With KMS**:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abc-def-ghi"
  }
}
```

### Encryption in Transit

**Always use HTTPS** (default for S3 backend).

---

## Backend Migration

### Migrate from Local to S3

**Step 1: Current state (local)**:
```hcl
# No backend block
```

**Step 2: Add S3 backend**:
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Step 3: Migrate**:
```bash
terraform init
# Terraform will detect backend change and prompt to migrate
# Type 'yes' to copy state to S3
```

### Migrate Between S3 Buckets

**Step 1: Update backend config**:
```hcl
terraform {
  backend "s3" {
    bucket = "new-terraform-state-bucket"  # Changed
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Step 2: Reinitialize**:
```bash
terraform init -migrate-state
```

### Migrate to Terraform Cloud

**Step 1: Update backend**:
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

**Step 2: Login and migrate**:
```bash
terraform login
terraform init
```

---

## State File Security

### Best Practices

**1. Restrict S3 Bucket Access**:
```hcl
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "AllowTerraformAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/TerraformRole"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}
```

**2. Enable Versioning**:
```hcl
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

**3. Enable Logging**:
```hcl
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "terraform-state-logs/"
}
```

**4. Lifecycle Policy**:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    id     = "delete-old-versions"
    status = "Enabled"
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
```

---

## Hands-on Lab 6: S3 Backend with Locking

### Objective
Set up production-ready remote state with S3 and DynamoDB.

### Project Structure
```
lab6-remote-state/
├── bootstrap/
│   ├── main.tf
│   ├── dynamodb.tf
│   └── outputs.tf
└── application/
    ├── backend.tf
    ├── main.tf
    └── variables.tf
```

### Step 1: Bootstrap Infrastructure

**bootstrap/main.tf**:
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

# S3 Bucket for State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-lab6-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name        = "Terraform State"
    Environment = "Lab6"
    ManagedBy   = "Terraform"
  }
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock-lab6"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "Terraform State Lock"
    Environment = "Lab6"
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

variable "aws_region" {
  default = "us-east-1"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Backend configuration"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "application/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }
  EOT
}
```

### Step 2: Deploy Bootstrap

```bash
cd bootstrap
terraform init
terraform apply -auto-approve

# Save outputs
terraform output -raw backend_config > ../application/backend.tf
terraform output s3_bucket_name
terraform output dynamodb_table_name
```

### Step 3: Application with Remote State

**application/backend.tf** (generated from bootstrap):
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-lab6-123456789012"
    key            = "application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-lab6"
    encrypt        = true
  }
}
```

**application/main.tf**:
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

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  
  tags = {
    Name        = "Lab6-RemoteState"
    Environment = "Lab"
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "ami_id" {
  default = "ami-0c55b159cbfafe1f0"
}

output "instance_id" {
  value = aws_instance.app.id
}
```

### Step 4: Test Remote State

```bash
cd application

# Initialize with remote backend
terraform init

# Verify state is in S3
aws s3 ls s3://terraform-state-lab6-123456789012/application/

# Apply
terraform apply -auto-approve

# Check DynamoDB lock (in another terminal during apply)
aws dynamodb scan --table-name terraform-state-lock-lab6

# Verify state versioning
aws s3api list-object-versions \
  --bucket terraform-state-lab6-123456789012 \
  --prefix application/terraform.tfstate
```

### Step 5: Test State Locking

**Terminal 1**:
```bash
terraform apply
# Don't confirm yet
```

**Terminal 2** (while Terminal 1 is waiting):
```bash
terraform apply
# Should show: Error acquiring the state lock
```

### Step 6: Cleanup

```bash
# Destroy application
cd application
terraform destroy -auto-approve

# Destroy bootstrap
cd ../bootstrap
terraform destroy -auto-approve
```

---

## Key Takeaways

✅ Remote state enables team collaboration  
✅ S3 + DynamoDB is production-ready backend  
✅ Always enable encryption and versioning  
✅ Use state locking to prevent corruption  
✅ Restrict S3 bucket access  
✅ Use partial configuration for sensitive values  
✅ Test state migration in non-prod first  
✅ Enable logging for audit trail

## Next Section

[07. Security Primer](../07-Security-Primer/)
