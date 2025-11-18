# 07. EKS Storage - AWS EBS Integration

## Overview
Master persistent storage in EKS using AWS Elastic Block Store (EBS). Learn to provide durable, high-performance storage for stateful applications in Kubernetes.

## What You'll Learn
- EBS CSI driver installation and configuration
- Persistent Volumes and Persistent Volume Claims
- Storage Classes and dynamic provisioning
- StatefulSets with persistent storage
- Backup and snapshot management
- Performance optimization and troubleshooting

## Prerequisites
- EKS cluster running
- Understanding of Kubernetes storage concepts
- AWS EBS knowledge
- kubectl configured

## Directory Structure
```
07-EKS-Storage-AWS-EBS/
├── CLI-Commands/           # kubectl and AWS CLI commands
├── Terraform/             # EBS CSI driver and storage infrastructure
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # EBS CSI Driver Setup
│   ├── Lab2/             # Persistent Volumes and Claims
│   └── Lab3/             # StatefulSets and Advanced Storage
└── README.md             # This file
```

## Learning Path
1. **Install EBS CSI driver**
2. **Learn storage concepts**
3. **Practice with Labs**
4. **Automate with Terraform**

## Cost Estimation
- **EBS Volumes**: $0.10/GB/month (gp3)
- **Snapshots**: $0.05/GB/month
- **IOPS**: Additional cost for high performance
- **Example**: 100GB = ~$10/month

## Key Concepts Covered
- **Container Storage Interface (CSI)**: Modern storage architecture
- **Persistent Volumes**: Durable storage abstraction
- **Storage Classes**: Dynamic provisioning templates
- **StatefulSets**: Ordered, persistent pod deployments
- **Volume Snapshots**: Backup and restore capabilities
- **Performance Tuning**: IOPS and throughput optimization