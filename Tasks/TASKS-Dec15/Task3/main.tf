# Terraform configuration for VPC infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "VPC-Demo"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Imran Shaikh"
    }
  }
}

# Use existing key pair for EC2 instances
data "aws_key_pair" "existing_key" {
  key_name = "jayimrankey"
}

# Create VPC and Internet Gateway
module "networking" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# Create subnets, NAT gateway, and route tables
module "subnets" {
  source = "./modules/subnets"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
  internet_gateway_id = module.networking.internet_gateway_id
  
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Create security groups for instances
module "security_groups" {
  source = "./modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
  
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# Create EC2 instances (bastion and private)
module "ec2_instances" {
  source = "./modules/compute"
  
  project_name = var.project_name
  environment  = var.environment
  
  key_name = data.aws_key_pair.existing_key.key_name
  
  public_subnet_id  = module.subnets.public_subnet_ids[0]
  private_subnet_id = module.subnets.private_subnet_ids[0]
  
  bastion_security_group_id = module.security_groups.bastion_security_group_id
  private_security_group_id = module.security_groups.private_security_group_id
  
  instance_type = var.instance_type
}