variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "imran-eks-cluster"
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for node access"
  type        = string
  default     = "jayimrankey"
}