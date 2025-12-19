# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.subnets.private_subnet_ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.subnets.internet_gateway_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.subnets.nat_gateway_id
}

# Security Group Outputs
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = module.security_groups.bastion_security_group_id
}

output "private_security_group_id" {
  description = "ID of the private security group"
  value       = module.security_groups.private_security_group_id
}

# Instance Outputs
output "bastion_host_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.ec2_instances.bastion_host_public_ip
}

output "bastion_host_private_ip" {
  description = "Private IP of the bastion host"
  value       = module.ec2_instances.bastion_host_private_ip
}

output "private_instance_ip" {
  description = "Private IP of the private instance"
  value       = module.ec2_instances.private_instance_ip
}

# SSH Connection Information
output "ssh_connection_commands" {
  description = "SSH commands to connect to instances"
  value = {
    bastion_host = "ssh -i ${var.local_key_path} ec2-user@${module.ec2_instances.bastion_host_public_ip}"
    private_instance = "ssh -i ${var.local_key_path} ec2-user@${module.ec2_instances.private_instance_ip}"
  }
}

# Key Pair Information
output "key_pair_name" {
  description = "Name of the existing key pair"
  value       = data.aws_key_pair.existing_key.key_name
}

output "private_key_file" {
  description = "Path to the private key file"
  value       = var.local_key_path
}