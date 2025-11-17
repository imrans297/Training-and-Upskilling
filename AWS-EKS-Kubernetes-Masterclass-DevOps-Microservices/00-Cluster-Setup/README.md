# 00. Shared EKS Cluster Setup

## Overview
Create a single, shared EKS cluster that will be used throughout the entire training program. This approach is cost-effective and mirrors real-world scenarios.

## What We're Creating
- **One EKS cluster** for all 23 sections
- **Namespace-based isolation** for different exercises
- **Scalable node groups** that can handle various workloads
- **Cost-optimized setup** (~$130/month total)

## Architecture
```
┌─────────────────────────────────────┐
│     EKS Control Plane (Shared)     │
│  - API Server                       │
│  - etcd                             │
│  - Scheduler                        │
└─────────────────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼────┐         ┌───▼────┐
│ Node 1 │         │ Node 2 │
│t3.medium│        │t3.medium│
│ (All    │        │ (All    │
│Sections)│        │Sections)│
└────────┘         └────────┘
```

## Namespace Strategy
```bash
# Each section gets its own namespace
kubectl create namespace docker-fundamentals          # Section 03
kubectl create namespace k8s-imperative              # Section 04
kubectl create namespace k8s-declarative             # Section 05
kubectl create namespace pod-identity                 # Section 06
kubectl create namespace storage-ebs                  # Section 07
kubectl create namespace secrets-probes               # Section 08
kubectl create namespace storage-rds                  # Section 09
kubectl create namespace loadbalancers                # Section 10
kubectl create namespace alb-controller               # Section 11
kubectl create namespace ingress-basics               # Section 12
# ... and so on
```

## Quick Setup
```bash
# 1. Create cluster (one time)
cd 00-Cluster-Setup/Terraform
terraform apply

# 2. Configure kubectl (one time)
aws eks update-kubeconfig --region ap-south-1 --name training-cluster

# 3. Create namespaces for all sections
kubectl apply -f namespaces.yaml

# 4. Verify setup
kubectl get nodes
kubectl get namespaces
```

## Cost Benefits
- **Single cluster**: $72/month (vs $1,656 for 23 clusters)
- **Shared nodes**: $58/month (vs $1,334 for 23 node groups)
- **Total savings**: ~$2,860/month (95% cost reduction)

## Section Usage Pattern
```bash
# Each section works in its own namespace
kubectl config set-context --current --namespace=k8s-imperative

# Run section exercises
kubectl apply -f lab-resources.yaml

# Clean up section (keep cluster)
kubectl delete all --all -n k8s-imperative
```