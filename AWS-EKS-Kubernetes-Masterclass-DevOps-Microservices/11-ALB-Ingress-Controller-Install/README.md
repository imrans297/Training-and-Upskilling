# 11. ALB Ingress Controller Installation

## Overview
Master AWS Load Balancer Controller installation and configuration for EKS. Enable advanced load balancing capabilities with Application Load Balancer (ALB) integration.

## What You'll Learn
- AWS Load Balancer Controller architecture
- Installation methods and best practices
- IAM roles and permissions setup
- Integration with AWS ALB and NLB
- Ingress resource configuration
- Troubleshooting and monitoring

## Prerequisites
- EKS cluster with OIDC provider
- Understanding of Kubernetes Services
- AWS ALB/NLB knowledge
- kubectl and Helm installed

## Directory Structure
```
11-ALB-Ingress-Controller-Install/
├── CLI-Commands/           # Installation commands and scripts
├── Terraform/             # Automated controller deployment
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # Controller Installation
│   ├── Lab2/             # Basic Ingress Configuration
│   └── Lab3/             # Advanced Features and Troubleshooting
└── README.md             # This file
```

## Cost Estimation
- **ALB**: $0.0225/hour (~$16/month)
- **Target Groups**: $0.008/hour per target group
- **Data Processing**: $0.008/GB
- **Example**: Basic setup ~$20/month

## Key Concepts Covered
- **Controller Architecture**: How ALB controller works
- **Installation Methods**: Helm, kubectl, Terraform
- **IAM Integration**: Service accounts and permissions
- **Ingress Resources**: ALB-specific annotations
- **SSL/TLS Termination**: Certificate management
- **Health Checks**: Target group configuration