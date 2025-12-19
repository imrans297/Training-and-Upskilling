output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "bastion_security_group_name" {
  description = "Name of the bastion security group"
  value       = aws_security_group.bastion_sg.name
}

output "private_security_group_name" {
  description = "Name of the private security group"
  value       = aws_security_group.private_sg.name
}

output "web_security_group_name" {
  description = "Name of the web security group"
  value       = aws_security_group.web.name
}