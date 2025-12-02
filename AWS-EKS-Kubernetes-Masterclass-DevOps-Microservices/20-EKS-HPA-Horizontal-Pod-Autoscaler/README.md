# 20. EKS HPA - Horizontal Pod Autoscaler

## Overview
Master Horizontal Pod Autoscaling in EKS for automatic application scaling based on metrics. Learn to implement responsive, cost-effective scaling strategies.

## What You'll Learn
- HPA concepts and architecture
- Metrics server installation and configuration
- CPU and memory-based scaling
- Custom metrics scaling (SQS, CloudWatch)
- Scaling policies and behaviors
- Performance optimization and troubleshooting

## Prerequisites
- EKS cluster running
- Understanding of resource requests/limits
- Metrics server installed
- kubectl configured

## Directory Structure
```
20-EKS-HPA-Horizontal-Pod-Autoscaler/
├── CLI-Commands/           # HPA management commands
├── Terraform/             # HPA and metrics infrastructure
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # Basic HPA Setup
│   ├── Lab2/             # Custom Metrics Scaling
│   └── Lab3/             # Advanced Scaling Strategies
└── README.md             # This file
```

## Cost Estimation
- **Additional Pods**: Variable based on scaling
- **Metrics Server**: Minimal overhead
- **CloudWatch Metrics**: $0.30/metric/month
- **Example**: 2-10 pods scaling ~$50-250/month

## Key Concepts Covered
- **Scaling Metrics**: CPU, memory, custom metrics
- **Scaling Policies**: Scale-up/down behaviors
- **Target Utilization**: Optimal resource usage
- **Custom Metrics**: Application-specific scaling
- **Integration**: VPA and Cluster Autoscaler
- **Best Practices**: Avoiding scaling thrashing