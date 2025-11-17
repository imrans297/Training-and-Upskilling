variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eksdemo1"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "my_ip" {
  description = "Your public IP for security group access"
  type        = string
  default     = "106.215.176.143/32"
}

locals {
  common_tags = {
    Name        = "${var.cluster_name}-cluster"
    Owner       = "imran.shaikh@einfochips.com"
    Project     = "Internal POC"
    DM          = "Shahid Raza"
    Department  = "PES-Digital"
    Environment = var.environment
    ENDDate     = "30-11-2025"
    ManagedBy   = "Terraform"
  }
}
