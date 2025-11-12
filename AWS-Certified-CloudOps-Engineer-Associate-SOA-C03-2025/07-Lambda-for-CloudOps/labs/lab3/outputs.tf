output "lambda_function_name" {
  description = "Name of the SNS Lambda function"
  value       = aws_lambda_function.sns_automation.function_name
}

output "lambda_function_arn" {
  description = "ARN of the SNS Lambda function"
  value       = aws_lambda_function.sns_automation.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.cloudops_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.cloudops_alerts.name
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
}

output "test_commands" {
  description = "Commands to test the Lambda function"
  value = {
    direct_invoke = "aws lambda invoke --function-name ${aws_lambda_function.sns_automation.function_name} --payload '{\"action\":\"list_instances\",\"tag\":\"Environment=Dev\"}' response.json"
    sns_publish = "aws sns publish --topic-arn ${aws_sns_topic.cloudops_alerts.arn} --message 'Test message' --subject 'Test Alert'"
    test_alarm = "aws cloudwatch set-alarm-state --alarm-name ${aws_cloudwatch_metric_alarm.high_cpu.alarm_name} --state-value ALARM --state-reason 'Testing alarm'"
  }
}

output "email_subscription_note" {
  description = "Note about email subscription confirmation"
  value       = "Check your email (${var.notification_email}) and confirm the SNS subscription to receive notifications"
}