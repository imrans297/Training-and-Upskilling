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

# DynamoDB Table
resource "aws_dynamodb_table" "inventory" {
  name           = "aws-inventory"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "resource_id"
  range_key      = "timestamp"

  attribute {
    name = "resource_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "scan_date"
    type = "S"
  }

  global_secondary_index {
    name            = "ScanDateIndex"
    hash_key        = "scan_date"
    projection_type = "ALL"
  }

  tags = {
    Name        = "AWS Inventory Table"
    Environment = "production"
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "inventory_alerts" {
  name = "inventory-alerts"

  tags = {
    Name = "Inventory Alerts"
  }
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.inventory_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# IAM Role for Collector Lambda
resource "aws_iam_role" "collector_role" {
  name = "inventory-collector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "collector_policy" {
  name = "inventory-collector-policy"
  role = aws_iam_role.collector_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "rds:Describe*",
          "s3:List*",
          "s3:GetBucket*",
          "lambda:List*",
          "eks:List*",
          "eks:Describe*",
          "cloudwatch:GetMetricStatistics",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for Analyzer Lambda
resource "aws_iam_role" "analyzer_role" {
  name = "inventory-analyzer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "analyzer_policy" {
  name = "inventory-analyzer-policy"
  role = aws_iam_role.analyzer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "sns:Publish",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Function - Collector
resource "aws_lambda_function" "collector" {
  filename      = "collector.zip"
  function_name = "inventory-collector"
  role          = aws_iam_role.collector_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 300
  memory_size   = 512

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.inventory.name
    }
  }

  tags = {
    Name = "Inventory Collector"
  }
}

# Lambda Function - Analyzer
resource "aws_lambda_function" "analyzer" {
  filename      = "analyzer.zip"
  function_name = "inventory-analyzer"
  role          = aws_iam_role.analyzer_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.inventory.name
      SNS_TOPIC_ARN = aws_sns_topic.inventory_alerts.arn
    }
  }

  tags = {
    Name = "AI Inventory Analyzer"
  }
}

# EventBridge Rule - Daily Scan
resource "aws_cloudwatch_event_rule" "daily_scan" {
  name                = "inventory-daily-scan"
  description         = "Trigger inventory collection daily at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "collector_target" {
  rule      = aws_cloudwatch_event_rule.daily_scan.name
  target_id = "CollectorLambda"
  arn       = aws_lambda_function.collector.arn
}

resource "aws_lambda_permission" "allow_eventbridge_collector" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_scan.arn
}

# EventBridge Rule - Trigger Analyzer after Collector
resource "aws_cloudwatch_event_rule" "trigger_analyzer" {
  name        = "inventory-trigger-analyzer"
  description = "Trigger analyzer after collector completes"

  event_pattern = jsonencode({
    source      = ["aws.lambda"]
    detail-type = ["Lambda Function Invocation Result - Success"]
    detail = {
      functionName = [aws_lambda_function.collector.function_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "analyzer_target" {
  rule      = aws_cloudwatch_event_rule.trigger_analyzer.name
  target_id = "AnalyzerLambda"
  arn       = aws_lambda_function.analyzer.arn
}

resource "aws_lambda_permission" "allow_eventbridge_analyzer" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_analyzer.arn
}

# Outputs
output "dynamodb_table" {
  value = aws_dynamodb_table.inventory.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.inventory_alerts.arn
}

output "collector_function" {
  value = aws_lambda_function.collector.function_name
}

output "analyzer_function" {
  value = aws_lambda_function.analyzer.function_name
}
