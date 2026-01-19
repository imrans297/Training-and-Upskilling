terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Key Pair (create manually or use existing)
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-lab4"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "lab4-web-sg"
  description = "Allow HTTP and SSH"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with Provisioners
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  tags = {
    Name = "Lab4-WebServer"
  }
  
  # Connection for remote provisioners
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  
  # 1. local-exec: Log instance creation
  provisioner "local-exec" {
    command = "echo Instance ${self.id} created at $(date) >> creation.log"
  }
  
  # 2. file: Upload installation script
  provisioner "file" {
    source      = "scripts/install.sh"
    destination = "/tmp/install.sh"
  }
  
  # 3. file: Upload custom index.html
  provisioner "file" {
    source      = "files/index.html"
    destination = "/tmp/index.html"
  }
  
  # 4. remote-exec: Run installation
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh",
      "sudo mv /tmp/index.html /var/www/html/index.html"
    ]
  }
  
  # 5. local-exec: Test website
  provisioner "local-exec" {
    command = "sleep 30 && curl -s http://${self.public_ip} > test_output.html"
  }
  
  # 6. Destroy-time provisioner
  provisioner "local-exec" {
    when    = destroy
    command = "echo Instance ${self.id} destroyed at $(date) >> destruction.log"
  }
}

# null_resource: Post-deployment tasks
resource "null_resource" "post_deploy" {
  depends_on = [aws_instance.web]
  
  triggers = {
    instance_id = aws_instance.web.id
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Deployment Summary" > deployment_summary.txt
      echo "Instance ID: ${aws_instance.web.id}" >> deployment_summary.txt
      echo "Public IP: ${aws_instance.web.public_ip}" >> deployment_summary.txt
      echo "URL: http://${aws_instance.web.public_ip}" >> deployment_summary.txt
    EOT
  }
}