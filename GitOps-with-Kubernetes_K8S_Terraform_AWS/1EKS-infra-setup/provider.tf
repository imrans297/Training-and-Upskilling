# Provider Configuration
# Created by: Imran Shaikh
# Region: us-east-1

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "GitOps-EKS"
      ManagedBy   = "Terraform"
      Owner       = "Imran Shaikh"
      Environment = "dev"
    }
  }
}
