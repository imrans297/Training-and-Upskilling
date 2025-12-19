output "bastion_host_id" {
  description = "ID of the bastion host"
  value       = aws_instance.bastion_host.id
}

output "bastion_host_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion_host.public_ip
}

output "bastion_host_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion_host.private_ip
}

output "private_instance_id" {
  description = "ID of the private instance"
  value       = aws_instance.app_server.id
}

output "private_instance_ip" {
  description = "Private IP of the private instance"
  value       = aws_instance.app_server.private_ip
}

output "bastion_host_dns" {
  description = "Public DNS of the bastion host"
  value       = aws_instance.bastion_host.public_dns
}

output "ami_id" {
  description = "AMI ID used for instances"
  value       = data.aws_ami.latest_amazon_linux.id
}