# Data source for latest Ubuntu AMI
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

# VPC for SSM labs
resource "aws_vpc" "ssm_lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-VPC"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "ssm_lab_igw" {
  vpc_id = aws_vpc.ssm_lab_vpc.id
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-IGW"
  })
}

# Public Subnet
resource "aws_subnet" "ssm_lab_public" {
  vpc_id                  = aws_vpc.ssm_lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-Public-Subnet"
  })
}

# Private Subnet
resource "aws_subnet" "ssm_lab_private" {
  vpc_id            = aws_vpc.ssm_lab_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-Private-Subnet"
  })
}

# Route Table for Public Subnet
resource "aws_route_table" "ssm_lab_public_rt" {
  vpc_id = aws_vpc.ssm_lab_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ssm_lab_igw.id
  }
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-Public-RT"
  })
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "ssm_lab_public_rta" {
  subnet_id      = aws_subnet.ssm_lab_public.id
  route_table_id = aws_route_table.ssm_lab_public_rt.id
}

# NAT Gateway for Private Subnet
resource "aws_eip" "ssm_lab_nat_eip" {
  domain = "vpc"
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-NAT-EIP"
  })
}

resource "aws_nat_gateway" "ssm_lab_nat" {
  allocation_id = aws_eip.ssm_lab_nat_eip.id
  subnet_id     = aws_subnet.ssm_lab_public.id
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-NAT-Gateway"
  })
  
  depends_on = [aws_internet_gateway.ssm_lab_igw]
}

# Route Table for Private Subnet
resource "aws_route_table" "ssm_lab_private_rt" {
  vpc_id = aws_vpc.ssm_lab_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ssm_lab_nat.id
  }
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-Private-RT"
  })
}

# Route Table Association for Private Subnet
resource "aws_route_table_association" "ssm_lab_private_rta" {
  subnet_id      = aws_subnet.ssm_lab_private.id
  route_table_id = aws_route_table.ssm_lab_private_rt.id
}

# Security Group for Public Instances
resource "aws_security_group" "ssm_lab_public_sg" {
  name_prefix = "ssm-lab-public-sg"
  vpc_id      = aws_vpc.ssm_lab_vpc.id
  description = "Security group for public SSM instances"
  
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
    Name = "SSM-Lab-Public-SG"
  })
}

# Security Group for Private Instances
resource "aws_security_group" "ssm_lab_private_sg" {
  name_prefix = "ssm-lab-private-sg"
  vpc_id      = aws_vpc.ssm_lab_vpc.id
  description = "Security group for private SSM instances"
  
  ingress {
    description     = "SSH from Public"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ssm_lab_public_sg.id]
  }
  
  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ssm_lab_vpc.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-Private-SG"
  })
}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "SSM-Lab-Role"
  
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
    Name = "SSM-Lab-Role"
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSM-Lab-Profile"
  role = aws_iam_role.ssm_role.name
  
  tags = merge(local.common_tags, {
    Name = "SSM-Lab-Profile"
  })
}

# Attach SSM policies
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Public EC2 Instance with SSM
resource "aws_instance" "ssm_public_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.ssm_lab_public_sg.id]
  subnet_id             = aws_subnet.ssm_lab_public.id
  iam_instance_profile  = aws_iam_instance_profile.ssm_profile.name
  
  user_data = base64encode(file("${path.module}/ssm-setup.sh"))
  
  tags = merge(local.common_tags, {
    Name        = "SSM-Public-Instance"
    Environment = "Production"
    Role        = "WebServer"
  })
}

# Private EC2 Instance with SSM (Session Manager only)
resource "aws_instance" "ssm_private_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = data.aws_key_pair.existing_key.key_name
  vpc_security_group_ids = [aws_security_group.ssm_lab_private_sg.id]
  subnet_id             = aws_subnet.ssm_lab_private.id
  iam_instance_profile  = aws_iam_instance_profile.ssm_profile.name
  
  user_data = base64encode(file("${path.module}/ssm-setup.sh"))
  
  tags = merge(local.common_tags, {
    Name        = "SSM-Private-Instance"
    Environment = "Production"
    Role        = "Database"
  })
}

# SSM Parameter Store
resource "aws_ssm_parameter" "db_host" {
  name        = "/cloudops/database/host"
  type        = "String"
  value       = "db.example.com"
  description = "Database host"
  
  tags = merge(local.common_tags, {
    Name = "DB-Host-Parameter"
  })
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/cloudops/database/password"
  type        = "SecureString"
  value       = "MySecurePassword123!"
  description = "Database password"
  
  tags = merge(local.common_tags, {
    Name = "DB-Password-Parameter"
  })
}

# SSM Document for Custom Commands
resource "aws_ssm_document" "cloudops_maintenance" {
  name          = "CloudOps-Maintenance"
  document_type = "Command"
  document_format = "JSON"
  
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Custom CloudOps maintenance script"
    parameters = {
      action = {
        type        = "String"
        description = "Action to perform"
        allowedValues = ["update", "restart", "status", "install"]
      }
    }
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "performAction"
        inputs = {
          runCommand = [
            "#!/bin/bash",
            "case {{action}} in",
            "  update) apt-get update -y && apt-get upgrade -y ;;",
            "  restart) systemctl restart nginx ;;",
            "  status) systemctl status nginx ;;",
            "  install) apt-get install -y htop curl wget ;;",
            "  *) echo 'Invalid action' ;;",
            "esac"
          ]
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Maintenance-Document"
  })
}

# Patch Baseline
resource "aws_ssm_patch_baseline" "cloudops_baseline" {
  name             = "CloudOps-Patch-Baseline"
  description      = "Patch baseline for CloudOps Ubuntu instances"
  operating_system = "UBUNTU"
  
  approval_rule {
    approve_after_days  = 7
    enable_non_security = false
    
    patch_filter {
      key    = "PRIORITY"
      values = ["Required", "Important", "Standard"]
    }
    
    patch_filter {
      key    = "SECTION"
      values = ["*"]
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Patch-Baseline"
  })
}

# Maintenance Window
resource "aws_ssm_maintenance_window" "cloudops_window" {
  name     = "CloudOps-Maintenance-Window"
  schedule = "cron(0 2 ? * SUN *)"
  duration = 4
  cutoff   = 1
  
  tags = merge(local.common_tags, {
    Name = "CloudOps-Maintenance-Window"
  })
}

# Maintenance Window Target
resource "aws_ssm_maintenance_window_target" "cloudops_target" {
  window_id     = aws_ssm_maintenance_window.cloudops_window.id
  name          = "CloudOps-Targets"
  description   = "Production instances for maintenance"
  resource_type = "INSTANCE"
  
  targets {
    key    = "tag:Environment"
    values = ["Production"]
  }
  
  targets {
    key    = "tag:Role"
    values = ["WebServer", "Database"]
  }
}

# Maintenance Window Task
resource "aws_ssm_maintenance_window_task" "patch_task" {
  window_id        = aws_ssm_maintenance_window.cloudops_window.id
  name             = "Patch-Task"
  description      = "Apply patches to instances"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = 1
  service_role_arn = aws_iam_role.maintenance_role.arn
  max_concurrency  = "2"
  max_errors       = "1"
  
  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.cloudops_target.id]
  }
  
  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = ["Scan"]
      }
    }
  }
}

# IAM Role for Maintenance Window
resource "aws_iam_role" "maintenance_role" {
  name = "SSM-Maintenance-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Name = "SSM-Maintenance-Role"
  })
}

resource "aws_iam_role_policy_attachment" "maintenance_policy" {
  role       = aws_iam_role.maintenance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}