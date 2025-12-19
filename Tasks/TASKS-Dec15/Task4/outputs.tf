output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.imran_cluster.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.imran_cluster.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.imran_cluster.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.imran_eks_vpc.id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "pod_subnets" {
  description = "Pod subnet IDs for custom networking"
  value       = [aws_subnet.pod_subnet_1.id, aws_subnet.pod_subnet_2.id]
}

output "pod_subnet_1_id" {
  description = "Pod subnet 1 ID"
  value       = aws_subnet.pod_subnet_1.id
}

output "pod_subnet_2_id" {
  description = "Pod subnet 2 ID"
  value       = aws_subnet.pod_subnet_2.id
}

output "availability_zones" {
  description = "Availability zones"
  value       = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
}