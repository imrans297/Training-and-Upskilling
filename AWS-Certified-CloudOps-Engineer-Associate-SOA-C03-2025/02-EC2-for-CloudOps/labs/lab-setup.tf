# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC for EC2 labs
resource "aws_vpc" "ec2_lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-VPC"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "ec2_lab_igw" {
  vpc_id = aws_vpc.ec2_lab_vpc.id
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-IGW"
  })
}

# Public Subnet
resource "aws_subnet" "ec2_lab_public" {
  vpc_id                  = aws_vpc.ec2_lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-Public-Subnet"
  })
}

# Route Table for Public Subnet
resource "aws_route_table" "ec2_lab_public_rt" {
  vpc_id = aws_vpc.ec2_lab_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ec2_lab_igw.id
  }
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-Public-RT"
  })
}

# Route Table Association
resource "aws_route_table_association" "ec2_lab_public_rta" {
  subnet_id      = aws_subnet.ec2_lab_public.id
  route_table_id = aws_route_table.ec2_lab_public_rt.id
}

# Security Group for EC2 instances
resource "aws_security_group" "ec2_lab_sg" {
  name_prefix = "ec2-lab-sg"
  vpc_id      = aws_vpc.ec2_lab_vpc.id
  description = "Security group for EC2 CloudOps labs"
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-SG"
  })
}

# Use existing key pair
data "aws_key_pair" "existing_key" {
  key_name = var.key_name
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_lab_role" {
  name = "EC2-Lab-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-Role"
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_lab_profile" {
  name = "EC2-Lab-Profile"
  role = aws_iam_role.ec2_lab_role.name
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-Profile"
  })
}

# Attach CloudWatch Agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM policy for Systems Manager
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 Instance for CloudOps labs
resource "aws_instance" "ec2_lab_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_lab_sg.id]
  subnet_id             = aws_subnet.ec2_lab_public.id
  iam_instance_profile  = aws_iam_instance_profile.ec2_lab_profile.name
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    region = var.aws_region
  }))
  
  monitoring = true
  
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = merge(local.common_tags, {
      Name = "EC2-Lab-Root-Volume"
    })
  }
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-Instance"
  })
}

# Additional EBS Volume
resource "aws_ebs_volume" "ec2_lab_volume" {
  availability_zone = aws_instance.ec2_lab_instance.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true
  
  tags = merge(local.common_tags, {
    Name = "EC2-Lab-Additional-Volume"
  })
}

# Attach EBS Volume
resource "aws_volume_attachment" "ec2_lab_volume_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ec2_lab_volume.id
  instance_id = aws_instance.ec2_lab_instance.id
}