output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.ec2_lab_vpc.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.ec2_lab_public.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_lab_sg.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_lab_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.ec2_lab_instance.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.ec2_lab_instance.public_dns
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = data.aws_key_pair.existing_key.key_name
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${aws_instance.ec2_lab_instance.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /home/einfochips/backup/Keys/dmoUser1Key.pem ec2-user@${aws_instance.ec2_lab_instance.public_ip}"
}