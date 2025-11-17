# 04. Kubernetes Fundamentals - Imperative Approach

## Overview
This section covers Kubernetes fundamentals using imperative commands - the direct command-line approach to managing Kubernetes resources. You'll learn core concepts through hands-on practice with kubectl commands.

## What You'll Learn
- Kubernetes core objects (Pods, ReplicaSets, Deployments, Services)
- Imperative vs Declarative approaches
- kubectl command mastery
- Resource management and troubleshooting
- Networking basics in Kubernetes
- Storage concepts

## Prerequisites
- Shared training cluster running (from section 00)
- kubectl configured with training-cluster context
- Basic understanding of containers
- Namespace: `k8s-imperative` (auto-created)

## Directory Structure
```
04-Kubernetes-Fundamentals-Imperative/
├── CLI-Commands/           # Pure kubectl commands approach
├── Terraform/             # Infrastructure as Code setup
├── Labs/                  # Hands-on lab exercises
│   ├── Lab1/             # Pods and Basic Operations
│   ├── Lab2/             # ReplicaSets and Scaling
│   ├── Lab3/             # Deployments and Updates
│   ├── Lab4/             # Services and Networking
│   └── Lab5/             # Troubleshooting and Best Practices
└── README.md             # This file
```

## Learning Path
1. **Start with CLI-Commands** - Learn pure kubectl approach
2. **Practice with Labs** - Hands-on exercises (Lab1 → Lab5)
3. **Use Terraform** - Infrastructure as Code approach (optional)

## Cost Estimation
- **EKS Cluster**: ~$0.10/hour ($72/month)
- **Worker Nodes**: 2x t3.medium ~$0.08/hour ($58/month)
- **Total**: ~$130/month (delete resources after practice)

## Quick Start
```bash
# Switch to this section's namespace
kubectl config set-context --current --namespace=k8s-imperative

# Verify cluster access
kubectl get nodes

# Start with Lab1
cd Labs/Lab1
cat README.md
```

## Key Concepts Covered
- **Pods**: Smallest deployable units
- **ReplicaSets**: Pod replication and scaling
- **Deployments**: Declarative updates and rollbacks
- **Services**: Network access to applications
- **Namespaces**: Resource isolation
- **Labels & Selectors**: Resource organization
- **ConfigMaps & Secrets**: Configuration management