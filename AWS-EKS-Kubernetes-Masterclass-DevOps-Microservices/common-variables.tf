# Common Variables for All Sections
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "my_ip" {
  description = "Your IP address for security group access (CIDR format)"
  type        = string
  validation {
    condition     = can(cidrhost(var.my_ip, 0))
    error_message = "The my_ip value must be a valid CIDR block (e.g., 203.0.113.0/32)."
  }
}

variable "key_pair_name" {
  description = "AWS Key Pair name for EC2 access"
  type        = string
}

# Common tags for all resources
locals {
  common_tags = {
    Owner       = "imran.shaikh@einfochips.com"
    Project     = "Internal POC"
    DM          = "Shahid Raza"
    Department  = "PES-Digital"
    Environment = var.environment
    ENDDate     = "30-11-2025"
    ManagedBy   = "Terraform"
  }
}