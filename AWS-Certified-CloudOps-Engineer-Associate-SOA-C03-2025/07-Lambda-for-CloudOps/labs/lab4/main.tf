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

# Create layer directory and install dependencies
resource "null_resource" "create_layer" {
  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p layer/python/lib/python3.9/site-packages
      pip install requests boto3 -t layer/python/lib/python3.9/site-packages/
      cd layer && zip -r ../cloudops-layer.zip .
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# Lambda Layer
resource "aws_lambda_layer_version" "cloudops_layer" {
  depends_on = [null_resource.create_layer]
  
  filename   = "cloudops-layer.zip"
  layer_name = "${var.project_name}-common-layer"
  
  compatible_runtimes = ["python3.9"]
  description         = "Common utilities and dependencies for CloudOps functions"

  tags = merge(local.common_tags, {
    Name = "CloudOps Common Layer"
  })
}

# Create ZIP file for Lambda function 1
data "archive_file" "lambda1_zip" {
  type        = "zip"
  source_file = "lambda1_function.py"
  output_path = "function1.zip"
}

# Create ZIP file for Lambda function 2
data "archive_file" "lambda2_zip" {
  type        = "zip"
  source_file = "lambda2_function.py"
  output_path = "function2.zip"
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-layer-lambda-role"

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

  tags = merge(local.common_tags, {
    Name = "Layer Lambda Role"
  })
}

# IAM policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-layer-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function 1 - Instance Manager
resource "aws_lambda_function" "instance_manager" {
  filename         = data.archive_file.lambda1_zip.output_path
  function_name    = "${var.project_name}-instance-manager"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda1_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.lambda1_zip.output_base64sha256

  layers = [aws_lambda_layer_version.cloudops_layer.arn]

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project_name
    }
  }

  tags = merge(local.common_tags, {
    Name = "Instance Manager Function"
  })
}

# Lambda function 2 - Resource Reporter
resource "aws_lambda_function" "resource_reporter" {
  filename         = data.archive_file.lambda2_zip.output_path
  function_name    = "${var.project_name}-resource-reporter"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda2_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.lambda2_zip.output_base64sha256

  layers = [aws_lambda_layer_version.cloudops_layer.arn]

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project_name
    }
  }

  tags = merge(local.common_tags, {
    Name = "Resource Reporter Function"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "instance_manager_logs" {
  name              = "/aws/lambda/${aws_lambda_function.instance_manager.function_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "Instance Manager Logs"
  })
}

resource "aws_cloudwatch_log_group" "resource_reporter_logs" {
  name              = "/aws/lambda/${aws_lambda_function.resource_reporter.function_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "Resource Reporter Logs"
  })
}