# EKS Architecture Diagram - Task 4

**Created by:** Imran Shaikh  
**Purpose:** Production-Ready EKS Cluster with Private Nodes + Public ALB

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
│  │                    VPC: imran-eks-vpc (10.0.0.0/16)                      │  │
│  │                                                                           │  │
│  │  ┌─────────────────────────┐    ┌─────────────────────────┐              │  │
│  │  │    Availability Zone A  │    │    Availability Zone B  │              │  │
│  │  │                         │    │                         │              │  │
│  │  │  ┌─────────────────────┐│    │┌─────────────────────┐  │              │  │
│  │  │  │   PUBLIC SUBNET 1   ││    ││   PUBLIC SUBNET 2   │  │              │  │
│  │  │  │   (10.0.1.0/24)     ││    ││   (10.0.2.0/24)     │  │              │  │
│  │  │  │                     ││    ││                     │  │              │  │
│  │  │  │  ┌─────────────────┐││    ││                     │  │              │  │
│  │  │  │  │   NAT GATEWAY   │││    ││                     │  │              │  │
│  │  │  │  │                 │││    ││                     │  │              │  │
│  │  │  │  └─────────────────┘││    ││                     │  │              │  │
│  │  │  │                     ││    ││                     │  │              │  │
│  │  │  │  ┌─────────────────┐││    ││  ┌─────────────────┐│  │              │  │
│  │  │  │  │ APPLICATION     │││    ││  │ APPLICATION     ││  │              │  │
│  │  │  │  │ LOAD BALANCER   │││    ││  │ LOAD BALANCER   ││  │              │  │
│  │  │  │  │ (ALB)           │││    ││  │ (ALB)           ││  │              │  │
│  │  │  │  └─────────────────┘││    ││  └─────────────────┘│  │              │  │
│  │  │  └─────────────────────┘│    │└─────────────────────┘  │              │  │
│  │  │                         │    │                         │              │  │
│  │  │  ┌─────────────────────┐│    │┌─────────────────────┐  │              │  │
│  │  │  │  PRIVATE SUBNET 1   ││    ││  PRIVATE SUBNET 2   │  │              │  │
│  │  │  │  (10.0.10.0/24)     ││    ││  (10.0.11.0/24)     │  │              │  │
│  │  │  │  [Worker Nodes]     ││    ││  [Worker Nodes]     │  │              │  │
│  │  │  │ ┌─────────────────┐ ││    ││ ┌─────────────────┐ │  │              │  │
│  │  │  │ │  EKS WORKER     │ ││    ││ │  EKS WORKER     │ │  │              │  │
│  │  │  │ │  NODE 1         │ ││    ││ │  NODE 2         │ │  │              │  │
│  │  │  │ │  (t3.medium)    │ ││    ││ │  (t3.medium)    │ │  │              │  │
│  │  │  │ │  NO PUBLIC IP   │ ││    ││ │  NO PUBLIC IP   │ │  │              │  │
│  │  │  │ └─────────────────┘ ││    ││ └─────────────────┘ │  │              │  │
│  │  │  └─────────────────────┘│    │└─────────────────────┘  │              │  │
│  │  │                         │    │                         │              │  │
│  │  │  ┌─────────────────────┐│    │┌─────────────────────┐  │              │  │
│  │  │  │   POD SUBNET 1      ││    ││   POD SUBNET 2      │  │              │  │
│  │  │  │   (10.0.50.0/24)    ││    ││   (10.0.51.0/24)    │  │              │  │
│  │  │  │   [VPC CNI Custom]   ││    ││   [VPC CNI Custom]   │  │              │  │
│  │  │  │ ┌─────────────────┐ ││    ││ ┌─────────────────┐ │  │              │  │
│  │  │  │ │ NGINX POD 1     │ ││    ││ │ NGINX POD 2     │ │  │              │  │
│  │  │  │ │ (10.0.50.x)     │ ││    ││ │ (10.0.51.x)     │ │  │              │  │
│  │  │  │ │ NGINX POD 3     │ ││    ││ │                 │ │  │              │  │
│  │  │  │ │ (10.0.50.x)     │ ││    ││ │                 │ │  │              │  │
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
│  │                                                                           │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    INTERNET GATEWAY                                 │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘

                                TRAFFIC FLOW
                                ════════════

    Internet User  →  ALB (Public Subnets)  →  EKS Pods (Pod Subnets)
         ↑                      ↓                         ↓
    HTTP/HTTPS              Target Groups            ClusterIP Service
      Request              Load Balancing              Pod Selection
                                                           ↓
                                               VPC CNI Custom Networking
                                               (Pods: 10.0.50.x/10.0.51.x)
                                               (Nodes: 10.0.10.x/10.0.11.x)
```

## Network Flow Details

### Inbound Traffic (User → Application)
1. **Internet User** makes HTTP/HTTPS request
2. **Application Load Balancer** (in public subnets) receives request
3. **ALB Target Groups** route traffic to healthy worker nodes
4. **Kubernetes Service** (ClusterIP) distributes to NGINX pods
5. **NGINX Pods** (in private subnets) serve the response

### Outbound Traffic (Nodes → Internet)
1. **EKS Worker Nodes** (private subnets) need internet access
2. **NAT Gateway** (in public subnet) provides outbound connectivity
3. **Internet Gateway** routes traffic to/from internet
4. Used for: pulling container images, package updates, etc.

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYERS                          │
├─────────────────────────────────────────────────────────────────┤
│  1. VPC Isolation        │  Network-level isolation            │
│  2. Subnet Segmentation  │  Public/Private separation          │
│  3. Security Groups      │  Instance-level firewall            │
│  4. IAM Roles           │  Service permissions                 │
│  5. OIDC Provider       │  Kubernetes service accounts        │
│  6. Private Endpoints   │  EKS API access control             │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **VPC** | Network isolation | 10.0.0.0/16 CIDR |
| **Public Subnets** | ALB placement | 10.0.1.0/24, 10.0.2.0/24 |
| **Private Subnets** | EKS nodes | 10.0.10.0/24, 10.0.11.0/24 |
| **Pod Subnets** | VPC CNI custom networking | 10.0.50.0/24, 10.0.51.0/24 |
| **NAT Gateway** | Outbound internet | Single NAT in AZ-A |
| **Internet Gateway** | Internet access | Attached to VPC |
| **EKS Cluster** | Kubernetes control plane | Version 1.28 |
| **Worker Nodes** | Application runtime | t3.medium, 2-4 nodes |
| **ALB Controller** | Load balancer management | AWS Load Balancer Controller |
| **NGINX App** | Sample application | 3 replicas, ClusterIP service |

## Key Security Features

-  **No Public IPs on Worker Nodes** - All nodes in private subnets
-  **ALB in Public Subnets Only** - Controlled internet access point
-  **NAT Gateway for Outbound** - Secure internet access for updates
-  **Security Groups** - Network-level access control
-  **IAM Roles** - Least privilege access
-  **VPC CNI Custom Networking** - Pods use separate subnets from nodes
-  **Private EKS Endpoint** - Secure API server access

---

**Note**: This architecture follows AWS best practices for production EKS deployments with proper network segmentation and security controls.