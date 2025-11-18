# 05. Kubernetes Fundamentals - Declarative YAML Approach

## Overview
This section covers Kubernetes fundamentals using declarative YAML manifests - the production-ready approach to managing Kubernetes resources. Learn to define desired state through configuration files.

## What You'll Learn
- YAML manifest creation and management
- Declarative vs Imperative approaches
- GitOps and Infrastructure as Code principles
- Advanced resource configurations
- Multi-resource deployments
- Configuration management best practices

## Prerequisites
- Completed section 04 (Imperative approach)
- EKS cluster running
- kubectl configured
- Basic YAML understanding

## Directory Structure
```
05-Kubernetes-Fundamentals-Declarative-YAML/
├── CLI-Commands/           # kubectl apply/delete commands
├── Terraform/             # Infrastructure as Code setup
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # Basic YAML Manifests
│   ├── Lab2/             # Multi-Resource Applications
│   ├── Lab3/             # ConfigMaps and Secrets
│   ├── Lab4/             # Advanced Configurations
│   └── Lab5/             # GitOps and CI/CD Integration
└── README.md             # This file
```

## Learning Path
1. **Start with CLI-Commands** - Learn kubectl apply/delete
2. **Practice with Labs** - Progressive YAML exercises
3. **Use Terraform** - Infrastructure automation

## Cost Estimation
- **Same as previous section**: ~$130/month
- **Additional storage**: ConfigMaps/Secrets (~$1/month)
- **Total**: ~$131/month

## Key Concepts Covered
- **YAML Syntax**: Proper formatting and structure
- **Resource Definitions**: Complete manifest specifications
- **Multi-Resource Files**: Organizing related resources
- **Configuration Management**: ConfigMaps and Secrets
- **Resource Relationships**: Dependencies and references
- **Version Control**: Git-based configuration management
- **GitOps Workflows**: Automated deployments