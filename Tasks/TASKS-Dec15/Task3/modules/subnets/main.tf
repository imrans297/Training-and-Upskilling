

# Public subnets for bastion and NAT gateway
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
    Environment = var.environment
    Tier = "Public"
    CreatedBy = "Terraform"
  }
}

# Private subnets for application servers
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Environment = var.environment
    Tier = "Private"
    CreatedBy = "Terraform"
  }
}

# EIP for NAT Gateway - needed for outbound internet from private subnets
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-gateway-eip"
    Environment = var.environment
    Purpose = "NAT Gateway"
  }
}

# NAT Gateway in public subnet for private subnet internet access
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[1].id  # Using second AZ for HA

  tags = {
    Name = "${var.project_name}-nat-gw"
    Environment = var.environment
  }


}

# Route table for public subnets - routes to IGW
resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = {
    Name = "${var.project_name}-public-routes"
    Environment = var.environment
  }
}

# Route table for private subnets - routes to NAT Gateway
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_name}-private-routes"
    Environment = var.environment
  }
}

# Connect public subnets to public route table
resource "aws_route_table_association" "public_association" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Connect private subnets to private route table
resource "aws_route_table_association" "private_association" {
  count = length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}