# VPC for my project
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
    Environment = var.environment
    Owner = "Imran Shaikh"
  }
}

# Internet gateway for public subnet internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
    Environment = var.environment
    Owner = "Imran Shaikh"
  }
}