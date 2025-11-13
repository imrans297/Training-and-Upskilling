output "primary_backup_vault_arn" {
  description = "Primary backup vault ARN"
  value       = aws_backup_vault.primary.arn
}

output "dr_backup_vault_arn" {
  description = "DR backup vault ARN"
  value       = aws_backup_vault.dr.arn
}

output "backup_plan_id" {
  description = "Backup plan ID"
  value       = aws_backup_plan.cloudops.id
}

output "primary_s3_bucket" {
  description = "Primary S3 bucket name"
  value       = aws_s3_bucket.primary.id
}

output "dr_s3_bucket" {
  description = "DR S3 bucket name"
  value       = aws_s3_bucket.dr.id
}

output "replication_role_arn" {
  description = "S3 replication role ARN"
  value       = aws_iam_role.replication.arn
}
