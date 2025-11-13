# Primary Region Provider
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

# DR Region Provider
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# Backup Vault - Primary
resource "aws_backup_vault" "primary" {
  provider    = aws.primary
  name        = "cloudops-backup-vault"
  kms_key_arn = aws_kms_key.backup_primary.arn
}

# Backup Vault - DR
resource "aws_backup_vault" "dr" {
  provider    = aws.dr
  name        = "cloudops-dr-vault"
  kms_key_arn = aws_kms_key.backup_dr.arn
}

# KMS Keys
resource "aws_kms_key" "backup_primary" {
  provider    = aws.primary
  description = "KMS key for backup encryption"
}

resource "aws_kms_key" "backup_dr" {
  provider    = aws.dr
  description = "KMS key for DR backup encryption"
}

# Backup Plan
resource "aws_backup_plan" "cloudops" {
  provider = aws.primary
  name     = "CloudOps-DR-Plan"

  rule {
    rule_name         = "DailyBackups"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 5 ? * * *)"

    lifecycle {
      delete_after                = 30
      move_to_cold_storage_after = 7
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = 90
      }
    }
  }
}

# Backup Selection
resource "aws_backup_selection" "cloudops" {
  provider     = aws.primary
  iam_role_arn = aws_iam_role.backup.arn
  name         = "CloudOps-Resources"
  plan_id      = aws_backup_plan.cloudops.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

# IAM Role for Backup
resource "aws_iam_role" "backup" {
  provider = aws.primary
  name     = "aws-backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  provider   = aws.primary
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# S3 Buckets for Replication
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "cloudops-primary-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  bucket   = "cloudops-dr-${random_string.suffix.result}"
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.primary
  role     = aws_iam_role.replication.arn
  bucket   = aws_s3_bucket.primary.id

  rule {
    id     = "ReplicateAll"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD_IA"
    }
  }

  depends_on = [aws_s3_bucket_versioning.primary]
}

# IAM Role for S3 Replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  role     = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.dr.arn}/*"
      }
    ]
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
