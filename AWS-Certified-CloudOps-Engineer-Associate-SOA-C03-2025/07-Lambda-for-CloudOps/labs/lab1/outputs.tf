output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.cloudops_automation.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.cloudops_automation.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_invoke_command" {
  description = "AWS CLI command to invoke the Lambda function"
  value       = "aws lambda invoke --function-name ${aws_lambda_function.cloudops_automation.function_name} --payload '{\"action\":\"list_instances\",\"tag\":\"Environment=Dev\"}' response.json"
}