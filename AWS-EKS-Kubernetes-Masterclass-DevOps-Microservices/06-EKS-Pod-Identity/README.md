# 06. EKS Pod Identity

## Overview
Master EKS Pod Identity for secure AWS service access from Kubernetes pods. Learn modern IAM integration replacing traditional IRSA (IAM Roles for Service Accounts).

## What You'll Learn
- EKS Pod Identity concepts and architecture
- IAM integration with Kubernetes workloads
- Secure AWS service access from pods
- Migration from IRSA to Pod Identity
- Security best practices and troubleshooting

## Prerequisites
- EKS cluster running
- Understanding of IAM roles and policies
- Completed Kubernetes fundamentals sections
- kubectl configured

## Directory Structure
```
06-EKS-Pod-Identity/
├── CLI-Commands/           # AWS CLI and kubectl commands
├── Terraform/             # Pod Identity infrastructure
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # Pod Identity Setup
│   ├── Lab2/             # AWS Service Integration
│   └── Lab3/             # Security and Troubleshooting
└── README.md             # This file
```

## Learning Path
1. **Understand Pod Identity concepts**
2. **Setup with CLI-Commands**
3. **Practice with Labs**
4. **Automate with Terraform**

## Cost Estimation
- **EKS Cluster**: Existing (~$72/month)
- **IAM Operations**: Free
- **AWS Service Usage**: Variable (S3, DynamoDB, etc.)
- **Total**: Minimal additional cost

## Key Concepts Covered
- **Pod Identity vs IRSA**: Modern approach comparison
- **IAM Integration**: Seamless AWS service access
- **Security Boundaries**: Least privilege principles
- **Service Account Mapping**: Kubernetes to AWS IAM
- **Troubleshooting**: Common issues and solutions