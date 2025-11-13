resource "aws_kms_key" "cloudops" {
  description             = "CloudOps encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cloudops" {
  name          = "alias/cloudops-key"
  target_key_id = aws_kms_key.cloudops.key_id
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "cloudops/database/credentials"
  description = "Database credentials for CloudOps application"
  kms_key_id  = aws_kms_key.cloudops.arn
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = var.db_password
    host     = "db.cloudops.example.com"
    port     = 3306
    engine   = "mysql"
  })
}

resource "aws_secretsmanager_secret" "api_key" {
  name        = "cloudops/api/key"
  description = "API key for external service"
  kms_key_id  = aws_kms_key.cloudops.arn
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = var.api_key
}

data "aws_caller_identity" "current" {}
