variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudops"
}

variable "db_password" {
  description = "Database password for secrets manager"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!"
}

variable "alert_email" {
  description = "Email for security alerts"
  type        = string
  default     = "security@cloudops.example.com"
}

locals {
  common_tags = {
    Owner       = "Imran Shaikh"
    Project     = "Internal POC"
    DM          = "Kalpesh Kumal"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
