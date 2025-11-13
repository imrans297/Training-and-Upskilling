output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.cloudops.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.cloudops.arn
}

output "kms_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.cloudops.name
}

output "db_secret_arn" {
  description = "Database credentials secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "api_secret_arn" {
  description = "API key secret ARN"
  value       = aws_secretsmanager_secret.api_key.arn
}
