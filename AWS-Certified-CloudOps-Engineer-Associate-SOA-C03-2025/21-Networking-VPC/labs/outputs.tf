output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.cloudops_vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.cloudops_vpc.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.cloudops_nat[*].id
}

output "web_security_group_id" {
  description = "Web security group ID"
  value       = aws_security_group.web_sg.id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.database_sg.id
}
