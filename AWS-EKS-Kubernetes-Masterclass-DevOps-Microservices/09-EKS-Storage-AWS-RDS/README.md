# 09. EKS Storage - AWS RDS Integration

## Overview
Master database integration with EKS using AWS RDS. Learn to connect Kubernetes applications to managed relational databases securely and efficiently.

## What You'll Learn
- RDS database provisioning and configuration
- Kubernetes database connectivity patterns
- Secret management for database credentials
- Connection pooling and performance optimization
- Database migration and backup strategies
- Security best practices for database access

## Prerequisites
- EKS cluster running
- Understanding of databases (MySQL, PostgreSQL)
- Completed storage fundamentals
- kubectl configured

## Directory Structure
```
09-EKS-Storage-AWS-RDS/
├── CLI-Commands/           # AWS CLI and kubectl commands
├── Terraform/             # RDS and networking infrastructure
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # RDS Setup and Configuration
│   ├── Lab2/             # Application Database Integration
│   └── Lab3/             # Performance and Security
└── README.md             # This file
```

## Cost Estimation
- **RDS Instance**: db.t3.micro ~$15/month
- **Storage**: $0.20/GB/month
- **Backup**: $0.095/GB/month
- **Example**: Small DB ~$20/month

## Key Concepts Covered
- **RDS vs Self-managed**: Managed database benefits
- **VPC Integration**: Secure network connectivity
- **Connection Management**: Pooling and optimization
- **Credential Management**: Secure secret handling
- **High Availability**: Multi-AZ deployments
- **Monitoring**: Performance and health tracking