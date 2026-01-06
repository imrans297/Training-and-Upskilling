# Deploy ArgoCD on EKS

**Created by:** Imran Shaikh  
**Purpose:** Install and configure ArgoCD for GitOps on EKS cluster

---

## Overview

This directory contains manifests and configurations to deploy ArgoCD on the EKS cluster created in step 1.

## Prerequisites

- EKS cluster running (from 1EKS-infra-setup)
- kubectl configured to access the cluster
- Git repository for application manifests

## What is ArgoCD?

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes:
- Monitors Git repositories for changes
- Automatically syncs desired state to cluster
- Provides UI for visualization
- Supports rollback and health monitoring

## Directory Structure

```
2DeployEKSonARGOCD/
├── argocd-install.yaml       # ArgoCD installation manifest
├── argocd-ingress.yaml       # Ingress for ArgoCD UI
├── applications/             # Sample applications
│   └── sample-app.yaml
└── README.md
```

## Installation Steps

### Step 1: Verify EKS Cluster
```bash
kubectl get nodes
kubectl get pods -A
```

### Step 2: Install ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f argocd-install.yaml
```

### Step 3: Wait for ArgoCD Pods
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 4: Get ArgoCD Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Step 5: Access ArgoCD UI

**Option A: Port Forward (Quick Access)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Access: https://localhost:8080

**Option B: LoadBalancer (Production)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd
```
Access: https://<EXTERNAL-IP>

### Step 6: Login to ArgoCD
- **Username:** admin
- **Password:** (from Step 4)

### Step 7: Deploy Sample Application
```bash
kubectl apply -f applications/sample-app.yaml
```

## ArgoCD CLI (Optional)

### Install ArgoCD CLI
```bash
# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### Login via CLI
```bash
argocd login localhost:8080 --username admin --password <password> --insecure
```

### List Applications
```bash
argocd app list
```

## Common Commands

### Check ArgoCD Status
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

### View ArgoCD Logs
```bash
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller
```

### Sync Application Manually
```bash
argocd app sync <app-name>
```

### Get Application Status
```bash
argocd app get <app-name>
```

## Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod -n argocd <pod-name>
kubectl logs -n argocd <pod-name>
```

### Cannot Access UI
- Check service type: `kubectl get svc -n argocd`
- Verify port-forward is running
- Check security groups allow traffic

### Sync Issues
- Verify Git repository is accessible
- Check application manifest syntax
- Review ArgoCD application controller logs

## Cleanup

### Delete Applications
```bash
kubectl delete -f applications/
```

### Uninstall ArgoCD
```bash
kubectl delete -n argocd -f argocd-install.yaml
kubectl delete namespace argocd
```

---

**Next Step:** Deploy your applications using ArgoCD!
