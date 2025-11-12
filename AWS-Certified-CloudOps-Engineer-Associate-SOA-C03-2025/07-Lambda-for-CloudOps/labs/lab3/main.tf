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

# Create ZIP file for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "function.zip"
}

# SNS Topic for CloudOps alerts
resource "aws_sns_topic" "cloudops_alerts" {
  name = "${var.project_name}-alerts"

  tags = merge(local.common_tags, {
    Name = "CloudOps Alerts Topic"
  })
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email_notification" {
  topic_arn = aws_sns_topic.cloudops_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-sns-lambda-role"

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
    Name = "SNS Lambda Role"
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-sns-lambda-policy"
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
          "ec2:StopInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.cloudops_alerts.arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "sns_automation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-sns-automation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project_name
      SNS_TOPIC_ARN = aws_sns_topic.cloudops_alerts.arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "SNS CloudOps Automation"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.sns_automation.function_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "SNS Lambda Logs"
  })
}

# CloudWatch Alarm for high CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.cloudops_alerts.arn]

  dimensions = {
    InstanceId = "i-1234567890abcdef0"  # Replace with actual instance ID
  }

  tags = merge(local.common_tags, {
    Name = "High CPU Alarm"
  })
}

# SNS Topic subscription for Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.cloudops_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_automation.arn
}

# Lambda permission for SNS
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_automation.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudops_alerts.arn
}