# Amazon Linux AMI
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion host (Public Subnet)
resource "aws_instance" "bastion_host" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_security_group_id]

  user_data = base64encode(templatefile("${path.module}/../../scripts/user-data.sh", {
    hostname = "bastion-host"
  }))

  tags = {
    Name = "${var.project_name}-bastion"
    Environment = var.environment
    Owner = "Imran Shaikh"
  }
}

# Private server in private subnet
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.private_security_group_id]

  user_data = base64encode(templatefile("${path.module}/../../scripts/user-data.sh", {
    hostname = "app-server"
  }))

  tags = {
    Name = "${var.project_name}-private-server"
    Environment = var.environment
    Owner = "Imran Shaikh"
  }
}