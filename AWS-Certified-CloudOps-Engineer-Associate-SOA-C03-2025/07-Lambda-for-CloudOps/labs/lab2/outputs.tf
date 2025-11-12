output "lambda_function_name" {
  description = "Name of the scheduled Lambda function"
  value       = aws_lambda_function.scheduled_automation.function_name
}

output "lambda_function_arn" {
  description = "ARN of the scheduled Lambda function"
  value       = aws_lambda_function.scheduled_automation.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "daily_stop_rule_name" {
  description = "Name of the daily stop EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_stop.name
}

output "morning_start_rule_name" {
  description = "Name of the morning start EventBridge rule"
  value       = aws_cloudwatch_event_rule.morning_start.name
}

output "schedule_expressions" {
  description = "Cron expressions for the scheduled rules"
  value = {
    daily_stop    = aws_cloudwatch_event_rule.daily_stop.schedule_expression
    morning_start = aws_cloudwatch_event_rule.morning_start.schedule_expression
  }
}

output "test_commands" {
  description = "Commands to test the Lambda function manually"
  value = {
    list_instances = "aws lambda invoke --function-name ${aws_lambda_function.scheduled_automation.function_name} --payload '{\"action\":\"list_instances\",\"tag\":\"Environment=Dev\"}' response.json"
    stop_instances = "aws lambda invoke --function-name ${aws_lambda_function.scheduled_automation.function_name} --payload '{\"action\":\"stop_instances\",\"tag\":\"Environment=Dev\"}' response.json"
    start_instances = "aws lambda invoke --function-name ${aws_lambda_function.scheduled_automation.function_name} --payload '{\"action\":\"start_instances\",\"tag\":\"Environment=Dev\"}' response.json"
  }
}