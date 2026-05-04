terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "devops-platform-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "development"
      Project     = "devops-platform"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  environment = "dev"
  cluster_name = "devops-platform-${local.environment}"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_name           = "devops-platform-${local.environment}"
  vpc_cidr           = "10.1.0.0/16"
  azs                = ["us-east-1a", "us-east-1b"]
  private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets     = ["10.1.101.0/24", "10.1.102.0/24"]
  enable_nat_gateway = true
  
  tags = {
    Environment = local.environment
  }
}

# EKS Module
module "eks" {
  source = "../../modules/eks"
  
  cluster_name    = local.cluster_name
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  
  node_groups = {
    development = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }
  
  tags = {
    Environment = local.environment
  }
}

# ECR Module (shared across environments)
# Use same ECR repository as prod

# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  jenkins_role_name    = "jenkins-${local.environment}"
  eks_cluster_name     = local.cluster_name
  ecr_repository_arn   = "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/devops-platform-app"
  
  tags = {
    Environment = local.environment
  }
}

data "aws_caller_identity" "current" {}
