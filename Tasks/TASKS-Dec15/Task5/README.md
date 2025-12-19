# Task 5: Multi-Tenant EKS Setup

**Purpose:** Implement fully isolated multi-tenant architecture within a single AWS EKS cluster

## Overview

This task implements a production-ready multi-tenant EKS cluster with complete isolation between Team-A and Team-B, including:

- **Namespace Isolation**: Separate namespaces for each team
- **RBAC Security**: Role-based access control per team
- **Network Isolation**: NetworkPolicies preventing cross-namespace communication
- **Monitoring Isolation**: Team-specific Prometheus scraping and Grafana dashboards
- **Resource Isolation**: Separate workloads and resource quotas

## Architecture

**📋 Detailed Architecture:** See [ARCHITECTURE.md](ARCHITECTURE.md) for complete diagram and component details

## Multi-Tenant Components

### Team Isolation Matrix

| Component | Team-A | Team-B | Isolation Method |
|-----------|--------|--------|------------------|
| **Namespace** | `team-a` | `team-b` | Kubernetes Namespaces |
| **RBAC** | `team-a-user` | `team-b-user` | Role + RoleBinding |
| **Network** | Calico NetworkPolicy | Calico NetworkPolicy | Deny cross-namespace |
| **Monitoring** | Team-A ServiceMonitor | Team-B ServiceMonitor | Label selectors |
| **Dashboards** | Team-A Grafana Folder | Team-B Grafana Folder | Grafana Teams |
| **Applications** | NGINX Demo | Apache Demo | Namespace + Labels |

## Prerequisites

- AWS CLI configured with appropriate permissions
- eksctl >= 0.215.0 installed
- kubectl installed
- Helm 3.x installed

## Implementation Steps

### Phase 1: Infrastructure Setup
1. Create EKS cluster with private nodes
2. Install Calico for NetworkPolicy support
3. Configure kubectl access

### Phase 2: Multi-Tenant Configuration
4. Create team namespaces
5. Configure RBAC for each team
6. Apply NetworkPolicies for isolation
7. Deploy monitoring stack (Prometheus + Grafana)

### Phase 3: Team-Specific Setup
8. Configure team-specific ServiceMonitors
9. Setup Grafana multi-tenancy
10. Deploy sample applications
11. Verify complete isolation

## Key Features

 **Complete Namespace Isolation**  
 **RBAC-based Access Control**  
 **Network-level Traffic Isolation**  
 **Monitoring and Alerting Separation**  
 **Dashboard Access Control**  
 **Resource Quota Management**  
 **Audit Trail per Team**

## Security Architecture

- **Identity**: IAM users mapped to Kubernetes users
- **Authorization**: RBAC with least privilege access
- **Network**: Calico NetworkPolicies for micro-segmentation
- **Monitoring**: Isolated metrics collection and visualization
- **Audit**: Separate logging per team namespace

## Resource Requirements

- **EKS Cluster**: 1 cluster (multi-tenant)
- **Worker Nodes**: 2 x t3.small (private subnets)
- **Namespaces**: 3 (team-a, team-b, monitoring)
- **Network Policies**: 2 (one per team)
- **RBAC Objects**: 4 (2 roles + 2 bindings)
- **Monitoring**: Prometheus + Grafana stack

## Verification Methods

### RBAC Verification
```bash
kubectl --as team-a-user get pods -n team-b   # Should be forbidden
kubectl --as team-b-user get pods -n team-a   # Should be forbidden
```

### Network Isolation Verification
```bash
kubectl exec -n team-a <pod> -- curl team-b-service.team-b.svc  # Should timeout
kubectl exec -n team-b <pod> -- curl team-a-service.team-a.svc  # Should timeout
```

### Monitoring Isolation Verification
- Check Prometheus targets: `up{team="a"}` vs `up{team="b"}`
- Verify Grafana dashboard access per team

## Cleanup

```bash
# Delete applications
kubectl delete -f 7-sample-apps/

# Delete monitoring
helm uninstall monitoring -n monitoring

# Delete cluster
eksctl delete cluster -f 1-vpc-eksctl/cluster.yaml
```

---

**Note**: This implementation demonstrates enterprise-grade multi-tenancy patterns suitable for production environments with strict isolation requirements.