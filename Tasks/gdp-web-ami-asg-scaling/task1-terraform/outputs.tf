output "instance_public_ips" {
  description = "Public IP addresses of GDP-Web instances"
  value       = aws_instance.gdp_web[*].public_ip
}

output "instance_ids" {
  description = "Instance IDs of GDP-Web instances"
  value       = aws_instance.gdp_web[*].id
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.latest_ami.function_name
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.gdp_web_sg.id
}

output "gdp_web_urls" {
  description = "URLs for GDP-Web applications"
  value = [
    for i, ip in aws_instance.gdp_web[*].public_ip : 
    "GDP-Web-${i + 1}: http://${ip}"
  ]
}