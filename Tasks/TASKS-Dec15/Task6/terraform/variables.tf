variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address for SNS alerts"
  type        = string
  default     = "imradev29@gmail.com"
}