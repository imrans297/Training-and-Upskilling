output "lambda_layer_arn" {
  description = "ARN of the CloudOps Lambda Layer"
  value       = aws_lambda_layer_version.cloudops_layer.arn
}

output "lambda_layer_version" {
  description = "Version of the CloudOps Lambda Layer"
  value       = aws_lambda_layer_version.cloudops_layer.version
}

output "instance_manager_function_name" {
  description = "Name of the Instance Manager Lambda function"
  value       = aws_lambda_function.instance_manager.function_name
}

output "resource_reporter_function_name" {
  description = "Name of the Resource Reporter Lambda function"
  value       = aws_lambda_function.resource_reporter.function_name
}

output "test_commands" {
  description = "Commands to test the Lambda functions"
  value = {
    # Instance Manager tests
    list_instances = "aws lambda invoke --function-name ${aws_lambda_function.instance_manager.function_name} --payload '{\"action\":\"list\",\"tag_key\":\"Environment\",\"tag_value\":\"Dev\"}' response.json"
    
    list_running = "aws lambda invoke --function-name ${aws_lambda_function.instance_manager.function_name} --payload '{\"action\":\"list_by_state\",\"tag_key\":\"Environment\",\"tag_value\":\"Dev\",\"states\":[\"running\"]}' response.json"
    
    stop_instances = "aws lambda invoke --function-name ${aws_lambda_function.instance_manager.function_name} --payload '{\"action\":\"stop\",\"tag_key\":\"Environment\",\"tag_value\":\"Dev\"}' response.json"
    
    # Resource Reporter tests
    resource_summary = "aws lambda invoke --function-name ${aws_lambda_function.resource_reporter.function_name} --payload '{\"report_type\":\"summary\"}' response.json"
    
    detailed_report = "aws lambda invoke --function-name ${aws_lambda_function.resource_reporter.function_name} --payload '{\"report_type\":\"detailed\",\"tag_key\":\"Environment\",\"tag_value\":\"Dev\"}' response.json"
    
    cost_analysis = "aws lambda invoke --function-name ${aws_lambda_function.resource_reporter.function_name} --payload '{\"report_type\":\"cost_analysis\",\"tag_key\":\"Environment\",\"tag_value\":\"Dev\"}' response.json"
  }
}

output "layer_benefits" {
  description = "Benefits of using Lambda Layers"
  value = {
    code_reuse = "Common utilities shared between multiple functions"
    smaller_packages = "Function packages are smaller without dependencies"
    faster_deployments = "Layer cached separately from function code"
    version_management = "Layer versions can be managed independently"
    cost_optimization = "Reduced storage and transfer costs"
  }
}