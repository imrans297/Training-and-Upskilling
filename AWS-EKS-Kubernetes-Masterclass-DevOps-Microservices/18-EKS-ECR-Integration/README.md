# 18. EKS ECR Integration

## Overview
Master AWS Elastic Container Registry (ECR) integration with EKS for secure, scalable container image management and deployment.

## What You'll Learn
- ECR repository creation and management
- Docker image building and pushing to ECR
- EKS authentication with ECR
- Image pull secrets and automation
- Security scanning and vulnerability management
- CI/CD integration patterns

## Prerequisites
- EKS cluster running
- Docker installed locally
- AWS CLI configured
- kubectl configured
- Understanding of container images

## Directory Structure
```
18-EKS-ECR-Integration/
├── CLI-Commands/           # Docker, AWS CLI, kubectl commands
├── Terraform/             # ECR and IAM infrastructure
├── Labs/                  # Hands-on exercises
│   ├── Lab1/             # ECR Setup and Image Management
│   ├── Lab2/             # EKS ECR Integration
│   └── Lab3/             # CI/CD and Security
└── README.md             # This file
```

## Learning Path
1. Setup ECR repositories
2. Build and push container images
3. Configure EKS ECR authentication
4. Implement automated workflows

## Cost Estimation
- **ECR Storage**: $0.10/GB/month
- **Data Transfer**: $0.09/GB (out to internet)
- **Image Scanning**: $0.09/image scan
- **Example**: 10GB storage ~$1/month

## Key Concepts Covered
- **ECR Repositories**: Public and private registries
- **Image Lifecycle**: Build, tag, push, pull workflows
- **Authentication**: IAM roles and image pull secrets
- **Security**: Vulnerability scanning and policies
- **Automation**: CI/CD pipeline integration
- **Multi-Architecture**: ARM64 and AMD64 support