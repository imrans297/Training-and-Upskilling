terraform {
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

# Random suffix for unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket for general storage
resource "aws_s3_bucket" "cloudops_bucket" {
  bucket = "${var.project_name}-${var.environment}-bucket-${random_string.bucket_suffix.result}"

  tags = merge(local.common_tags, {
    Name = "CloudOps Main Bucket"
    Type = "General Storage"
  })
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "cloudops_versioning" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudops_encryption" {
  bucket = aws_s3_bucket.cloudops_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "cloudops_pab" {
  bucket = aws_s3_bucket.cloudops_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for logs
resource "aws_s3_bucket" "cloudops_logs" {
  bucket = "${var.project_name}-${var.environment}-logs-${random_string.bucket_suffix.result}"

  tags = merge(local.common_tags, {
    Name = "CloudOps Logs Bucket"
    Type = "Log Storage"
  })
}

# Logs bucket versioning
resource "aws_s3_bucket_versioning" "logs_versioning" {
  bucket = aws_s3_bucket.cloudops_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Logs bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs_encryption" {
  bucket = aws_s3_bucket.cloudops_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket lifecycle configuration - Commented out due to validation issues
# resource "aws_s3_bucket_lifecycle_configuration" "cloudops_lifecycle" {
#   bucket = aws_s3_bucket.cloudops_bucket.id
#
#   rule {
#     id     = "transition_to_ia"
#     status = "Enabled"
#
#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }
#
#     transition {
#       days          = 90
#       storage_class = "GLACIER"
#     }
#
#     transition {
#       days          = 365
#       storage_class = "DEEP_ARCHIVE"
#     }
#
#     expiration {
#       days = 2555  # 7 years
#     }
#
#     noncurrent_version_expiration {
#       noncurrent_days = 90
#     }
#   }
# }

# S3 Bucket notification configuration
resource "aws_s3_bucket_notification" "cloudops_notification" {
  bucket = aws_s3_bucket.cloudops_bucket.id

  # We'll add SNS/SQS/Lambda targets in advanced labs
}

# Sample objects for testing
resource "aws_s3_object" "sample_file" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  key    = "samples/readme.txt"
  content = <<-EOT
    CloudOps S3 Lab - Sample File
    
    This is a sample file created by Terraform for testing S3 operations.
    
    Created: ${timestamp()}
    Environment: ${var.environment}
    Project: ${var.project_name}
    
    You can use this file to test:
    - S3 object operations
    - Versioning
    - Lifecycle policies
    - Access controls
  EOT

  tags = merge(local.common_tags, {
    Name = "Sample README"
    Type = "Documentation"
  })
}

resource "aws_s3_object" "config_file" {
  bucket = aws_s3_bucket.cloudops_bucket.id
  key    = "config/app-config.json"
  content = jsonencode({
    application = "cloudops"
    environment = var.environment
    version     = "1.0.0"
    settings = {
      debug   = var.environment == "dev" ? true : false
      logging = "enabled"
      region  = var.aws_region
    }
  })

  tags = merge(local.common_tags, {
    Name = "App Configuration"
    Type = "Configuration"
  })
}