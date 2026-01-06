# Outputs for EKS Infrastructure
# Created by: Imran Shaikh

output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.eks_cluster.id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks_vpc.id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
