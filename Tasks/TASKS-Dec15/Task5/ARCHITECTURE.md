# Multi-Tenant EKS Architecture - Task 5

**Created by:** Imran Shaikh  
**Purpose:** Multi-Tenant EKS Setup with Complete Isolation

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  INTERNET                                        │
└─────────────────────────────────┬───────────────────────────────────────────────┘
                                  │
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            AWS REGION (us-east-1)                               │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                    VPC: multi-tenant-eks (Auto-created)                   │  │
│  │                                                                           │  │
│  │  ┌─────────────────────────┐    ┌─────────────────────────┐              │  │
│  │  │    Availability Zone A  │    │    Availability Zone B  │              │  │
│  │  │                         │    │                         │              │  │
│  │  │  ┌─────────────────────┐│    │┌─────────────────────┐  │              │  │
│  │  │  │   PUBLIC SUBNET     ││    ││   PUBLIC SUBNET     │  │              │  │
│  │  │  │   (Auto-created)    ││    ││   (Auto-created)    │  │              │  │
│  │  │  │                     ││    ││                     │  │              │  │
│  │  │  │  ┌─────────────────┐││    ││  ┌─────────────────┐│  │              │  │
│  │  │  │  │   NAT GATEWAY   │││    ││  │   NAT GATEWAY   ││  │              │  │
│  │  │  │  └─────────────────┘││    ││  └─────────────────┘│  │              │  │
│  │  │  └─────────────────────┘│    │└─────────────────────┘  │              │  │
│  │  │                         │    │                         │              │  │
│  │  │  ┌─────────────────────┐│    │┌─────────────────────┐  │              │  │
│  │  │  │  PRIVATE SUBNET     ││    ││  PRIVATE SUBNET     │  │              │  │
│  │  │  │  (Auto-created)     ││    ││  (Auto-created)     │  │              │  │
│  │  │  │                     ││    ││                     │  │              │  │
│  │  │  │ ┌─────────────────┐ ││    ││ ┌─────────────────┐ │  │              │  │
│  │  │  │ │  EKS WORKER     │ ││    ││ │  EKS WORKER     │ │  │              │  │
│  │  │  │ │  NODE 1         │ ││    ││ │  NODE 2         │ │  │              │  │
│  │  │  │ │  (t3.small)     │ ││    ││ │  (t3.small)     │ │  │              │  │
│  │  │  │ │  NO PUBLIC IP   │ ││    ││ │  NO PUBLIC IP   │ │  │              │  │
│  │  │  │ └─────────────────┘ ││    ││ └─────────────────┘ │  │              │  │
│  │  │  └─────────────────────┘│    │└─────────────────────┘  │              │  │
│  │  └─────────────────────────┘    └─────────────────────────┘              │  │
│  │                                                                           │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    EKS CONTROL PLANE                                │  │  │
│  │  │                  (Managed by AWS)                                   │  │  │
│  │  │                 Kubernetes API Server                               │  │  │
│  │  │                      etcd, Scheduler                                │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘

                            MULTI-TENANT NAMESPACE ISOLATION
                            ═══════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────────┐
│                           KUBERNETES CLUSTER LAYER                              │
│                                                                                 │
│  ┌─────────────────────────┐  ┌─────────────────────────┐  ┌─────────────────┐  │
│  │     TEAM-A NAMESPACE    │  │     TEAM-B NAMESPACE    │  │   MONITORING    │  │
│  │                         │  │                         │  │   NAMESPACE     │  │
│  │  ┌─────────────────────┐│  │┌─────────────────────┐  │  │                 │  │
│  │  │    NGINX PODS       ││  ││    APACHE PODS      │  │  │ ┌─────────────┐ │  │
│  │  │    (team=a)         ││  ││    (team=b)         │  │  │ │ PROMETHEUS  │ │  │
│  │  │                     ││  ││                     │  │  │ │             │ │  │
│  │  │ ┌─────────────────┐ ││  ││ ┌─────────────────┐ │  │  │ │ ┌─────────┐ │ │  │
│  │  │ │ nginx-pod-1     │ ││  ││ │ apache-pod-1    │ │  │  │ │ │Team-A   │ │ │  │
│  │  │ │ nginx-pod-2     │ ││  ││ │ apache-pod-2    │ │  │  │ │ │Metrics  │ │ │  │
│  │  │ └─────────────────┘ ││  ││ └─────────────────┘ │  │  │ │ └─────────┘ │ │  │
│  │  └─────────────────────┘│  │└─────────────────────┘  │  │ │ ┌─────────┐ │ │  │
│  │                         │  │                         │  │ │ │Team-B   │ │ │  │
│  │  ┌─────────────────────┐│  │┌─────────────────────┐  │  │ │ │Metrics  │ │ │  │
│  │  │    SERVICES         ││  ││    SERVICES         │  │  │ │ └─────────┘ │ │  │
│  │  │                     ││  ││                     │  │  │ └─────────────┘ │  │
│  │  │ ┌─────────────────┐ ││  ││ ┌─────────────────┐ │  │  │                 │  │
│  │  │ │ team-a-service  │ ││  ││ │ team-b-service  │ │  │  │ ┌─────────────┐ │  │
│  │  │ │ (ClusterIP)     │ ││  ││ │ (ClusterIP)     │ │  │  │ │  GRAFANA    │ │  │
│  │  │ └─────────────────┘ ││  ││ └─────────────────┘ │  │  │ │             │ │  │
│  │  └─────────────────────┘│  │└─────────────────────┘  │  │ │ ┌─────────┐ │ │  │
│  │                         │  │                         │  │ │ │Team-A   │ │ │  │
│  │  ┌─────────────────────┐│  │┌─────────────────────┐  │  │ │ │Folder   │ │ │  │
│  │  │   NETWORK POLICY    ││  ││   NETWORK POLICY    │  │  │ │ └─────────┘ │ │  │
│  │  │                     ││  ││                     │  │  │ │ ┌─────────┐ │ │  │
│  │  │ ┌─────────────────┐ ││  ││ ┌─────────────────┐ │  │  │ │ │Team-B   │ │ │  │
│  │  │ │ DENY ALL        │ ││  ││ │ DENY ALL        │ │  │  │ │ │Folder   │ │ │  │
│  │  │ │ FROM OTHER      │ ││  ││ │ FROM OTHER      │ │  │  │ │ └─────────┘ │ │  │
│  │  │ │ NAMESPACES      │ ││  ││ │ NAMESPACES      │ │  │  │ └─────────────┘ │  │
│  │  │ └─────────────────┘ ││  ││ └─────────────────┘ │  │  └─────────────────┘  │
│  │  └─────────────────────┘│  │└─────────────────────┘  │                       │
│  └─────────────────────────┘  └─────────────────────────┘                       │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                              RBAC LAYER                                 │  │
│  │                                                                         │  │
│  │  ┌─────────────────────┐              ┌─────────────────────┐          │  │
│  │  │    TEAM-A RBAC      │              │    TEAM-B RBAC      │          │  │
│  │  │                     │              │                     │          │  │
│  │  │ ┌─────────────────┐ │              │ ┌─────────────────┐ │          │  │
│  │  │ │ team-a-user     │ │              │ │ team-b-user     │ │          │  │
│  │  │ │ (IAM User)      │ │              │ │ (IAM User)      │ │          │  │
│  │  │ └─────────────────┘ │              │ └─────────────────┘ │          │  │
│  │  │         │           │              │         │           │          │  │
│  │  │         ▼           │              │         ▼           │          │  │
│  │  │ ┌─────────────────┐ │              │ ┌─────────────────┐ │          │  │
│  │  │ │ team-a-role     │ │              │ │ team-b-role     │ │          │  │
│  │  │ │ (Namespace      │ │              │ │ (Namespace      │ │          │  │
│  │  │ │  Scoped)        │ │              │ │  Scoped)        │ │          │  │
│  │  │ └─────────────────┘ │              │ └─────────────────┘ │          │  │
│  │  └─────────────────────┘              └─────────────────────┘          │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘

                                ISOLATION BOUNDARIES
                                ═══════════════════

    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │   NAMESPACE     │    │    NETWORK      │    │     RBAC        │
    │   ISOLATION     │    │   ISOLATION     │    │   ISOLATION     │
    │                 │    │                 │    │                 │
    │ team-a ≠ team-b │    │ Calico Policies │    │ Role Bindings   │
    │                 │    │ Block Cross-NS  │    │ Per Namespace   │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
            │                        │                        │
            └────────────────────────┼────────────────────────┘
                                     │
                            ┌─────────────────┐
                            │   MONITORING    │
                            │   ISOLATION     │
                            │                 │
                            │ ServiceMonitors │
                            │ Label Selectors │
                            │ Grafana Teams   │
                            └─────────────────┘
```

## Multi-Tenant Security Model

### 1. Identity & Access Management
```
IAM User → Kubernetes User → Namespace Role → Resource Access
    │              │               │              │
team-a-user → team-a-user → team-a-role → team-a namespace only
team-b-user → team-b-user → team-b-role → team-b namespace only
```

### 2. Network Isolation Matrix
| Source Namespace | Target Namespace | Access | Policy |
|------------------|------------------|--------|--------|
| team-a | team-a | ✅ Allow | Default |
| team-a | team-b | ❌ Deny | NetworkPolicy |
| team-b | team-a | ❌ Deny | NetworkPolicy |
| team-b | team-b | ✅ Allow | Default |
| monitoring | team-a | ✅ Allow | ServiceMonitor |
| monitoring | team-b | ✅ Allow | ServiceMonitor |

### 3. Monitoring Isolation
```
Prometheus
├── Team-A Metrics (team=a label)
│   ├── nginx_requests_total{team="a"}
│   └── up{team="a"}
└── Team-B Metrics (team=b label)
    ├── apache_requests_total{team="b"}
    └── up{team="b"}

Grafana
├── Team-A Folder (Team-A access only)
│   └── Team-A Dashboards
└── Team-B Folder (Team-B access only)
    └── Team-B Dashboards
```

## Component Architecture

| Component | Purpose | Isolation Method |
|-----------|---------|------------------|
| **EKS Cluster** | Shared Kubernetes platform | Single cluster, multi-tenant |
| **Namespaces** | Logical resource isolation | Kubernetes namespaces |
| **RBAC** | Access control | Role-based permissions |
| **NetworkPolicies** | Network micro-segmentation | Calico CNI policies |
| **ServiceMonitors** | Metrics collection | Label-based targeting |
| **Grafana Teams** | Dashboard access control | Folder permissions |
| **Resource Quotas** | Resource limits | Per-namespace quotas |

## Traffic Flow

### Allowed Traffic
```
Team-A Pod → Team-A Service → Team-A Pod ✅
Team-B Pod → Team-B Service → Team-B Pod ✅
Prometheus → Team-A Pods (metrics) ✅
Prometheus → Team-B Pods (metrics) ✅
```

### Blocked Traffic
```
Team-A Pod → Team-B Service ❌ (NetworkPolicy)
Team-B Pod → Team-A Service ❌ (NetworkPolicy)
team-a-user → team-b namespace ❌ (RBAC)
team-b-user → team-a namespace ❌ (RBAC)
```

## Security Features

- ✅ **Namespace Isolation** - Logical separation of resources
- ✅ **RBAC Enforcement** - Identity-based access control
- ✅ **Network Segmentation** - Calico NetworkPolicies
- ✅ **Monitoring Isolation** - Team-specific metrics and dashboards
- ✅ **Resource Quotas** - Prevent resource exhaustion
- ✅ **Audit Logging** - Track all API access per team
- ✅ **Secret Isolation** - Namespace-scoped secrets
- ✅ **Service Account Isolation** - Per-team service accounts

---

**Note**: This architecture provides enterprise-grade multi-tenancy with defense-in-depth security controls suitable for production environments.