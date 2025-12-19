# Main Terraform Configuration
# Created by: Imran Shaikh
# Purpose: EKS cluster with private nodes and public ALB

# This file serves as the main entry point
# All resources are organized in separate files:
# - provider.tf: Terraform and AWS provider configuration
# - networking.tf: VPC, subnets, routing, and security groups
# - eks.tf: EKS cluster and node group configuration
# - alb-controller.tf: ALB controller IAM setup