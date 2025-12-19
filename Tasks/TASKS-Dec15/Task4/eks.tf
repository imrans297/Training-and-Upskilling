# EKS Cluster Configuration
# Created by: Imran Shaikh
# Purpose: EKS cluster with private worker nodes

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "imran-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name  = "imran-eks-cluster-role"
    Owner = "Imran Shaikh"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_role" {
  name = "imran-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name  = "imran-eks-node-role"
    Owner = "Imran Shaikh"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "imran_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name  = var.cluster_name
    Owner = "Imran Shaikh"
  }
}

# EKS Node Group
resource "aws_eks_node_group" "imran_nodes" {
  cluster_name    = aws_eks_cluster.imran_cluster.name
  node_group_name = "imran-worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type = "AL2023_x86_64_STANDARD"

  # Ensure nodes have no public IP
  remote_access {
    ec2_ssh_key = var.key_pair_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_registry_policy,
  ]

  tags = {
    Name  = "imran-worker-nodes"
    Owner = "Imran Shaikh"
  }
}

# OIDC provider is defined in alb-controller.tf