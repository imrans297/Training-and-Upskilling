# Multi-Tenant EKS Setup (Namespaces, RBAC, NetworkPolicies, Prometheus, Grafana)

**Created by:** Imran Shaikh  
**Date:** December 2024  
**Purpose:** Complete multi-tenant EKS implementation with isolation between Team-A and Team-B

This repository contains a production-ready multi-tenant Kubernetes environment on Amazon EKS with complete isolation between teams using a single shared cluster.

## 📋 Documentation

- **[README.md](../README.md)** - Main overview
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Detailed architecture diagrams
- **[DOCUMENTATION.md](../DOCUMENTATION.md)** - Step-by-step implementation guide

## 🏗️ Directory Structure

```
multi-tenant-eks/
├── 0-iam-setup/              # IAM users and policies
├── 1-vpc-eksctl/             # EKS cluster configuration
├── 2-namespaces/             # Team namespaces
├── 3-rbac/                   # Role-based access control
├── 4-networkpolicies/        # Network isolation
├── 5-monitoring/             # Prometheus + Grafana
├── 6-grafana/                # Grafana multi-tenancy setup
├── 7-sample-apps/            # Team applications
├── 8-resource-quotas/        # Resource limits per team
└── 9-ingress-access/         # ALB Ingress for external access
```

## 🚀 Quick Start

### 1. Create IAM Users
```bash
./0-iam-setup/create-iam-users.sh
```

### 2. Create EKS Cluster
```bash
eksctl create cluster -f 1-vpc-eksctl/cluster.yaml
```

### 3. Install Calico for NetworkPolicies
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### 4. Deploy Multi-Tenant Components
```bash
# Create namespaces
kubectl apply -f 2-namespaces/

# Configure RBAC
kubectl apply -f 3-rbac/

# Apply network policies
kubectl apply -f 4-networkpolicies/

# Create resource quotas
kubectl apply -f 8-resource-quotas/
```

### 5. Install Monitoring Stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f 5-monitoring/prometheus-values.yaml \
  -f 5-monitoring/grafana-values.yaml

# Deploy ServiceMonitors
kubectl apply -f 5-monitoring/team-a-servicemonitor.yaml
kubectl apply -f 5-monitoring/team-b-servicemonitor.yaml
```

### 6. Setup External Access
```bash
# Install AWS Load Balancer Controller
./9-ingress-access/alb-controller-setup.sh

# Deploy Ingress resources
kubectl apply -f 9-ingress-access/multi-tenant-ingress.yaml
```

### 7. Deploy Sample Applications
```bash
kubectl apply -f 7-sample-apps/
```

## 🔒 Multi-Tenant Isolation

| Isolation Layer | Team-A | Team-B | Method |
|-----------------|--------|--------|--------|
| **Namespace** | `team-a` | `team-b` | Kubernetes Namespaces |
| **RBAC** | `team-a-user` | `team-b-user` | Role + RoleBinding |
| **Network** | NetworkPolicy | NetworkPolicy | Calico CNI |
| **Resources** | ResourceQuota | ResourceQuota | CPU/Memory limits |
| **Monitoring** | ServiceMonitor | ServiceMonitor | Label selectors |
| **Access** | team-a.*.local | team-b.*.local | ALB Ingress |

## 🌐 Access URLs

After deployment, access applications via:

- **Team-A**: `http://team-a.multi-tenant.local`
- **Team-B**: `http://team-b.multi-tenant.local`  
- **Grafana**: `http://grafana.multi-tenant.local`

## 📊 Resource Specifications

- **Cluster**: 2 × t3.small nodes (2 vCPU, 2 GiB each)
- **Team-A Quota**: 800m CPU, 1 GiB memory
- **Team-B Quota**: 800m CPU, 1 GiB memory
- **Monitoring**: ~600m CPU, ~1.2 GiB memory

## ✅ Verification

### RBAC Isolation
```bash
kubectl --as team-a-user get pods -n team-b   # Should be forbidden
kubectl --as team-b-user get pods -n team-a   # Should be forbidden
```

### Network Isolation
```bash
kubectl exec -n team-a <pod> -- curl team-b-service.team-b.svc --timeout 5  # Should timeout
```

### Monitoring Isolation
- Check Prometheus targets: `up{team="a"}` vs `up{team="b"}`
- Verify Grafana folder permissions per team

## 🧹 Cleanup

```bash
# Delete applications and monitoring
kubectl delete -f 7-sample-apps/
helm uninstall monitoring -n monitoring

# Delete cluster
eksctl delete cluster -f 1-vpc-eksctl/cluster.yaml
```

---

**Note**: This setup provides enterprise-grade multi-tenancy with complete isolation suitable for production environments.