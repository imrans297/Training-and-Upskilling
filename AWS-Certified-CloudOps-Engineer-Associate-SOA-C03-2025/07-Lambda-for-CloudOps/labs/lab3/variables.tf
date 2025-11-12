variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudops"
}

variable "notification_email" {
  description = "Email address for SNS notifications"
  type        = string
  default     = "admin@example.com"
}

# Standard Tags
locals {
  common_tags = {
    Owner       = "Imran Shaikh"
    Project     = "Internal POC"
    DM          = "Kalpesh Kumal"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}