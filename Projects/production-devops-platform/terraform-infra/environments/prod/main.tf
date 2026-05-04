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
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "devops-platform"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  environment = "prod"
  cluster_name = "devops-platform-${local.environment}"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  vpc_name           = "devops-platform-${local.environment}"
  vpc_cidr           = "10.0.0.0/16"
  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
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
    production = {
      desired_size   = 3
      min_size       = 3
      max_size       = 10
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  
  tags = {
    Environment = local.environment
  }
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"
  
  repository_name      = "devops-platform-app"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  
  tags = {
    Environment = local.environment
  }
}

# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  jenkins_role_name    = "jenkins-${local.environment}"
  eks_cluster_name     = local.cluster_name
  ecr_repository_arn   = module.ecr.repository_arn
  
  tags = {
    Environment = local.environment
  }
}

# Jenkins Module
module "jenkins" {
  source = "../../modules/jenkins"
  
  instance_name        = "jenkins-${local.environment}"
  instance_type        = "t3.large"
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.public_subnets[0]
  key_name             = var.key_name
  iam_instance_profile = module.iam.jenkins_instance_profile
  
  tags = {
    Environment = local.environment
  }
}

# SonarQube Module
module "sonarqube" {
  source = "../../modules/sonarqube"
  
  instance_name = "sonarqube-${local.environment}"
  instance_type = "t3.medium"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnets[0]
  key_name      = var.key_name
  
  tags = {
    Environment = local.environment
  }
}

# Lambda for AI Remediation
module "lambda" {
  source = "../../modules/lambda"
  
  function_name    = "ai-remediation-${local.environment}"
  eks_cluster_name = local.cluster_name
  
  tags = {
    Environment = local.environment
  }
}
