# VPC and Networking Configuration
# Created by: Imran Shaikh
# Purpose: Network setup for EKS with private nodes and public ALB

# VPC for EKS cluster
resource "aws_vpc" "imran_eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                        = "imran-eks-vpc"
    Owner                                       = "Imran Shaikh"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "imran_igw" {
  vpc_id = aws_vpc.imran_eks_vpc.id

  tags = {
    Name  = "imran-eks-igw"
    Owner = "Imran Shaikh"
  }
}

# Public subnets for ALB only
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.imran_eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "imran-public-subnet-1"
    Owner                    = "Imran Shaikh"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.imran_eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "imran-public-subnet-2"
    Owner                    = "Imran Shaikh"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets for EKS nodes
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.imran_eks_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                              = "imran-private-subnet-1"
    Owner                             = "Imran Shaikh"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.imran_eks_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                              = "imran-private-subnet-2"
    Owner                             = "Imran Shaikh"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Pod subnets for VPC CNI custom networking
resource "aws_subnet" "pod_subnet_1" {
  vpc_id            = aws_vpc.imran_eks_vpc.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name                              = "imran-pod-subnet-1"
    Owner                             = "Imran Shaikh"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "pod_subnet_2" {
  vpc_id            = aws_vpc.imran_eks_vpc.id
  cidr_block        = "10.0.51.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name                              = "imran-pod-subnet-2"
    Owner                             = "Imran Shaikh"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# NAT Gateway for private subnet internet access
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name  = "imran-nat-eip"
    Owner = "Imran Shaikh"
  }
}

resource "aws_nat_gateway" "imran_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name  = "imran-nat-gateway"
    Owner = "Imran Shaikh"
  }
}

# Route tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.imran_eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.imran_igw.id
  }

  tags = {
    Name  = "imran-public-rt"
    Owner = "Imran Shaikh"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.imran_eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.imran_nat.id
  }

  tags = {
    Name  = "imran-private-rt"
    Owner = "Imran Shaikh"
  }
}

# Route table associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "pod_1" {
  subnet_id      = aws_subnet.pod_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "pod_2" {
  subnet_id      = aws_subnet.pod_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster_sg" {
  name        = "imran-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.imran_eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "imran-eks-cluster-sg"
    Owner = "Imran Shaikh"
  }
}