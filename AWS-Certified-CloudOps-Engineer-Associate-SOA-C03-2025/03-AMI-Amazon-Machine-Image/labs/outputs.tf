output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.ami_lab_vpc.id
}

output "golden_ami_builder_id" {
  description = "ID of the Golden AMI builder instance"
  value       = aws_instance.golden_ami_builder.id
}

output "golden_ami_builder_ip" {
  description = "Public IP of the Golden AMI builder instance"
  value       = aws_instance.golden_ami_builder.public_ip
}

output "golden_ami_id" {
  description = "ID of the created Golden AMI"
  value       = aws_ami_from_instance.golden_ami.id
}

output "instance_from_ami_id" {
  description = "ID of instance launched from Golden AMI"
  value       = aws_instance.from_golden_ami.id
}

output "instance_from_ami_ip" {
  description = "Public IP of instance launched from Golden AMI"
  value       = aws_instance.from_golden_ami.public_ip
}

output "kms_key_id" {
  description = "ID of the KMS key for AMI encryption"
  value       = aws_kms_key.ami_encryption_key.id
}

output "ssh_command_builder" {
  description = "SSH command to connect to the Golden AMI builder"
  value       = "ssh -i /home/einfochips/backup/Keys/dmoUser1Key.pem ubuntu@${aws_instance.golden_ami_builder.public_ip}"
}

output "ssh_command_from_ami" {
  description = "SSH command to connect to instance from Golden AMI"
  value       = "ssh -i /home/einfochips/backup/Keys/dmoUser1Key.pem ubuntu@${aws_instance.from_golden_ami.public_ip}"
}

output "web_url_builder" {
  description = "URL to access Golden AMI builder web interface"
  value       = "http://${aws_instance.golden_ami_builder.public_ip}"
}

output "web_url_from_ami" {
  description = "URL to access instance from Golden AMI web interface"
  value       = "http://${aws_instance.from_golden_ami.public_ip}"
}