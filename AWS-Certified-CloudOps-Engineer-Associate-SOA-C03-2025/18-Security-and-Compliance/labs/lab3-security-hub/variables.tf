variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email for Security Hub alerts"
  type        = string
  default     = "security@example.com"
}
