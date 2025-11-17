# 03. Docker Fundamentals

## Overview
Master Docker containerization technology - the foundation of Kubernetes. Learn to build, run, and manage containers effectively before diving into orchestration.

## What You'll Learn
- Docker architecture and concepts
- Container lifecycle management
- Image building and optimization
- Docker networking and storage
- Multi-container applications
- Container security best practices

## Prerequisites
- Basic Linux command knowledge
- Understanding of applications and processes
- AWS account (for ECR integration)

## Directory Structure
```
03-Docker-Fundamentals/
├── CLI-Commands/           # Docker command reference
├── Terraform/             # ECR and infrastructure setup
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # Docker Basics and Images
│   ├── Lab2/             # Container Operations
│   ├── Lab3/             # Dockerfile and Image Building
│   ├── Lab4/             # Networking and Volumes
│   └── Lab5/             # Multi-container Apps and ECR
└── README.md             # This file
```

## Learning Path
1. **Start with CLI-Commands** - Learn Docker commands
2. **Practice with Labs** - Progressive hands-on exercises
3. **Use Terraform** - ECR and infrastructure automation

## Cost Estimation
- **EC2 Instance**: t3.medium ~$35/month (for Docker practice)
- **ECR Storage**: ~$0.10/GB/month
- **Data Transfer**: Minimal for learning
- **Total**: ~$40/month

## Key Concepts Covered
- **Containers vs VMs**: Understanding the differences
- **Docker Images**: Building and managing images
- **Container Runtime**: Running and managing containers
- **Networking**: Container communication
- **Storage**: Volumes and bind mounts
- **Security**: Container isolation and best practices
- **Registry**: Image storage and distribution