# 10. EKS LoadBalancers - CLB & NLB

## Overview
Master AWS Classic Load Balancer (CLB) and Network Load Balancer (NLB) integration with EKS for high-performance, scalable application access.

## What You'll Learn
- CLB vs NLB differences and use cases
- Service type LoadBalancer configuration
- AWS Load Balancer Controller setup
- Performance optimization and troubleshooting
- Cost optimization strategies
- SSL/TLS termination patterns

## Prerequisites
- EKS cluster running
- AWS Load Balancer Controller installed
- Understanding of Kubernetes Services
- kubectl configured

## Directory Structure
```
10-EKS-LoadBalancers-CLB-NLB/
├── CLI-Commands/           # kubectl and AWS CLI commands
├── Terraform/             # Load balancer infrastructure
├── Labs/                  # Hands-on exercises
│   ├── Lab1/             # CLB Setup and Configuration
│   ├── Lab2/             # NLB Implementation
│   └── Lab3/             # Performance and Optimization
└── README.md             # This file
```

## Learning Path
1. Understand load balancer types and use cases
2. Practice with CLI commands
3. Work through progressive labs
4. Implement with Terraform automation

## Cost Estimation
- **Classic Load Balancer**: $0.025/hour (~$18/month)
- **Network Load Balancer**: $0.0225/hour (~$16/month)
- **Data Processing**: $0.008/GB processed
- **Example**: Basic setup ~$25/month

## Key Concepts Covered
- **CLB Features**: Layer 4/7 load balancing, SSL termination
- **NLB Features**: Ultra-high performance, static IPs
- **Service Integration**: LoadBalancer service type
- **Health Checks**: Target group configuration
- **SSL/TLS**: Certificate management and termination
- **Performance Tuning**: Connection handling optimization