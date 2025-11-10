output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.ssm_lab_vpc.id
}

output "public_instance_id" {
  description = "ID of the public SSM instance"
  value       = aws_instance.ssm_public_instance.id
}

output "private_instance_id" {
  description = "ID of the private SSM instance"
  value       = aws_instance.ssm_private_instance.id
}

output "public_instance_ip" {
  description = "Public IP of the public SSM instance"
  value       = aws_instance.ssm_public_instance.public_ip
}

output "private_instance_ip" {
  description = "Private IP of the private SSM instance"
  value       = aws_instance.ssm_private_instance.private_ip
}

output "ssh_command_public" {
  description = "SSH command to connect to public instance"
  value       = "ssh -i /home/einfochips/backup/Keys/dmoUser1Key.pem ubuntu@${aws_instance.ssm_public_instance.public_ip}"
}

output "web_url_public" {
  description = "URL to access public instance web interface"
  value       = "http://${aws_instance.ssm_public_instance.public_ip}"
}

output "ssm_session_public" {
  description = "SSM Session Manager command for public instance"
  value       = "aws ssm start-session --target ${aws_instance.ssm_public_instance.id}"
}

output "ssm_session_private" {
  description = "SSM Session Manager command for private instance"
  value       = "aws ssm start-session --target ${aws_instance.ssm_private_instance.id}"
}

output "ssm_run_command_example" {
  description = "Example SSM Run Command"
  value       = "aws ssm send-command --document-name 'AWS-RunShellScript' --targets 'Key=tag:Environment,Values=Production' --parameters 'commands=[\"uptime\",\"df -h\"]'"
}

output "ssm_custom_document" {
  description = "Custom SSM document name"
  value       = aws_ssm_document.cloudops_maintenance.name
}

output "parameter_store_examples" {
  description = "Parameter Store examples"
  value = {
    get_db_host     = "aws ssm get-parameter --name '/cloudops/database/host'"
    get_db_password = "aws ssm get-parameter --name '/cloudops/database/password' --with-decryption"
    list_parameters = "aws ssm get-parameters-by-path --path '/cloudops' --recursive"
  }
}

output "maintenance_window_id" {
  description = "ID of the maintenance window"
  value       = aws_ssm_maintenance_window.cloudops_window.id
}

output "patch_baseline_id" {
  description = "ID of the patch baseline"
  value       = aws_ssm_patch_baseline.cloudops_baseline.id
}