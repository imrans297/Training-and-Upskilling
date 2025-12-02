variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "AWS_EKS-cluster"
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

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access to worker nodes"
  type        = string
  default     = "eks-demo-1_keyIMR"
}

variable "custom_ami_id" {
  description = "Custom AMI ID with MDATP pre-installed (leave empty to use default EKS AMI)"
  type        = string
  default     = ""
}

variable "my_ip" {
  description = "Your IP address for security group restrictions"
  type        = string
  default     = "106.215.176.143/32"
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