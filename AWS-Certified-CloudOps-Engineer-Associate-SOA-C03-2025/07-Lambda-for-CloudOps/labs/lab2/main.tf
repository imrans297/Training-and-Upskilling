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

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-scheduled-lambda-role"

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
    Name = "Scheduled Lambda Role"
  })
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-scheduled-lambda-policy"
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
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "scheduled_automation" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-scheduled-automation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project_name
    }
  }

  tags = merge(local.common_tags, {
    Name = "Scheduled CloudOps Automation"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.scheduled_automation.function_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "Scheduled Lambda Logs"
  })
}

# EventBridge Rule for daily stop
resource "aws_cloudwatch_event_rule" "daily_stop" {
  name                = "${var.project_name}-daily-stop"
  description         = "Stop development instances daily"
  schedule_expression = var.schedule_expression

  tags = merge(local.common_tags, {
    Name = "Daily Instance Stop Rule"
  })
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_stop.name
  target_id = "TriggerScheduledLambda"
  arn       = aws_lambda_function.scheduled_automation.arn

  input = jsonencode({
    action = "stop_instances"
    tag    = "Environment=Dev"
    source = "scheduled"
  })
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_stop.arn
}

# EventBridge Rule for morning start (optional)
resource "aws_cloudwatch_event_rule" "morning_start" {
  name                = "${var.project_name}-morning-start"
  description         = "Start development instances in the morning"
  schedule_expression = "cron(0 8 ? * MON-FRI *)"  # 8 AM weekdays

  tags = merge(local.common_tags, {
    Name = "Morning Instance Start Rule"
  })
}

# EventBridge Target for morning start
resource "aws_cloudwatch_event_target" "morning_lambda_target" {
  rule      = aws_cloudwatch_event_rule.morning_start.name
  target_id = "TriggerMorningLambda"
  arn       = aws_lambda_function.scheduled_automation.arn

  input = jsonencode({
    action = "start_instances"
    tag    = "Environment=Dev"
    source = "scheduled"
  })
}

# Lambda permission for morning EventBridge
resource "aws_lambda_permission" "allow_morning_eventbridge" {
  statement_id  = "AllowExecutionFromMorningEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_automation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.morning_start.arn
}