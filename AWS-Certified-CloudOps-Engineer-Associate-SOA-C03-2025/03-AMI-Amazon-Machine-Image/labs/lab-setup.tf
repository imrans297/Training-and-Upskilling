# Data source for latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Use existing key pair
data "aws_key_pair" "existing_key" {
  key_name = var.key_name
}

# VPC for AMI labs
resource "aws_vpc" "ami_lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "AMI-Lab-VPC"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "ami_lab_igw" {
  vpc_id = aws_vpc.ami_lab_vpc.id
  
  tags = merge(local.common_tags, {
    Name = "AMI-Lab-IGW"
  })
}

# Public Subnet
resource "aws_subnet" "ami_lab_public" {
  vpc_id                  = aws_vpc.ami_lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "AMI-Lab-Public-Subnet"
  })
}

# Route Table
resource "aws_route_table" "ami_lab_public_rt" {
  vpc_id = aws_vpc.ami_lab_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ami_lab_igw.id
  }
  
  tags = merge(local.common_tags, {
    Name = "AMI-Lab-Public-RT"
  })
}

# Route Table Association
resource "aws_route_table_association" "ami_lab_public_rta" {
  subnet_id      = aws_subnet.ami_lab_public.id
  route_table_id = aws_route_table.ami_lab_public_rt.id
}

# Security Group
resource "aws_security_group" "ami_lab_sg" {
  name_prefix = "ami-lab-sg"
  vpc_id      = aws_vpc.ami_lab_vpc.id
  description = "Security group for AMI CloudOps labs"
  
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
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "AMI-Lab-SG"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ami_lab_role" {
  name = "AMI-Lab-Role"
  
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
    Name = "AMI-Lab-Role"
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ami_lab_profile" {
  name = "AMI-Lab-Profile"
  role = aws_iam_role.ami_lab_role.name
  
  tags = merge(local.common_tags, {
    Name = "AMI-Lab-Profile"
  })
}

# Attach policies
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ami_lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ami_lab_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Golden AMI Builder Instance
resource "aws_instance" "golden_ami_builder" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.ami_lab_sg.id]
  subnet_id             = aws_subnet.ami_lab_public.id
  iam_instance_profile  = aws_iam_instance_profile.ami_lab_profile.name
  
  user_data = base64encode(file("${path.module}/ubuntu-golden-ami-setup.sh"))
  
  tags = merge(local.common_tags, {
    Name = "Golden-AMI-Builder"
    Type = "AMI-Builder"
  })
}

# KMS Key for AMI encryption
resource "aws_kms_key" "ami_encryption_key" {
  description = "KMS key for AMI encryption"
  
  tags = merge(local.common_tags, {
    Name = "AMI-Encryption-Key"
  })
}

resource "aws_kms_alias" "ami_encryption_key_alias" {
  name          = "alias/ami-encryption-key"
  target_key_id = aws_kms_key.ami_encryption_key.key_id
}

# Check if user data completed successfully
resource "null_resource" "check_user_data" {
  depends_on = [aws_instance.golden_ami_builder]
  
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo systemctl is-active nginx",
      "test -f /var/www/html/index.html"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("/home/einfochips/backup/Keys/dmoUser1Key.pem")
      host        = aws_instance.golden_ami_builder.public_ip
    }
  }
}

# Wait for user data to complete before creating AMI
resource "time_sleep" "wait_for_user_data" {
  depends_on = [null_resource.check_user_data]
  create_duration = "2m"
}

# Create Custom AMI from Golden AMI Builder (after user data completes)
resource "aws_ami_from_instance" "golden_ami" {
  name               = "golden-ami-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  source_instance_id = aws_instance.golden_ami_builder.id
  description        = "Golden AMI with pre-configured CloudOps tools"
  
  tags = merge(local.common_tags, {
    Name = "Golden-AMI"
    Type = "Base-Image"
  })
  
  # Wait for user data to complete
  depends_on = [time_sleep.wait_for_user_data]
}

# Launch instance from custom AMI
resource "aws_instance" "from_golden_ami" {
  ami                    = aws_ami_from_instance.golden_ami.id
  instance_type          = var.instance_type
  key_name              = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.ami_lab_sg.id]
  subnet_id             = aws_subnet.ami_lab_public.id
  iam_instance_profile  = aws_iam_instance_profile.ami_lab_profile.name
  
  tags = merge(local.common_tags, {
    Name = "Instance-From-Golden-AMI"
    Type = "Production"
  })
}