variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!SecurePassword"
}

variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
  default     = "sk-1234567890abcdef"
}
