terraform {
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

# Data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security Group
resource "aws_security_group" "gdp_web_sg" {
  name        = "gdp-web-terraform-sg"
  description = "Security group for GDP-Web instances"
  vpc_id      = data.aws_vpc.default.id

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

  tags = {
    Name = "gdp-web-terraform-sg"
  }
}

# Key Pair
resource "aws_key_pair" "gdp_web_key" {
  key_name   = "gdp-web-terraform-key"
  public_key = file("${path.module}/gdp-web-key.pub")
}

# GDP-Web Instances
resource "aws_instance" "gdp_web" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.gdp_web_key.key_name
  vpc_security_group_ids = [aws_security_group.gdp_web_sg.id]
  subnet_id             = data.aws_subnets.default.ids[0]
  
  user_data = templatefile("${path.module}/user_data.sh", {
    app_id = count.index + 1
  })

  tags = {
    Name        = "gdp-web-${count.index + 1}-instance"
    Application = "gdp-web-${count.index + 1}"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "gdp-web-terraform-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy" "lambda_ec2" {
  name = "lambda-ec2-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "latest_ami" {
  filename         = "lambda_function.zip"
  function_name    = "gdp-web-terraform-latest-ami"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"
  timeout         = 30

  depends_on = [data.archive_file.lambda_zip]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}