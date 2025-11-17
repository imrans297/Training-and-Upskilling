variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "training-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "training"
}

locals {
  common_tags = {
    Name        = var.cluster_name
    Owner       = "imran.shaikh@einfochips.com"
    Project     = "Internal POC"
    DM          = "Shahid Raza"
    Department  = "PES-Digital"
    Environment = var.environment
    ENDDate     = "30-11-2025"
    ManagedBy   = "Terraform"
    Purpose     = "EKS Training Cluster"
  }
}