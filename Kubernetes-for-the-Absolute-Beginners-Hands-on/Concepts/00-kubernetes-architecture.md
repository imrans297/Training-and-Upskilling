# Kubernetes Architecture

## Overview
Kubernetes follows a master-worker architecture with control plane managing worker nodes.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         CONTROL PLANE                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  API Server  │  │  Scheduler   │  │  Controller  │          │
│  │              │  │              │  │   Manager    │          │
│  │  - REST API  │  │  - Pod       │  │  - Node      │          │
│  │  - Auth      │  │    Placement │  │  - Replication│         │
│  │  - Validation│  │  - Resource  │  │  - Endpoints │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                   │
│  ┌──────────────────────────────────────────────────┐           │
│  │              etcd (Key-Value Store)              │           │
│  │  - Cluster state                                 │           │
│  │  - Configuration data                            │           │
│  │  - Distributed and consistent                    │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ (Communication)
                              │
┌─────────────────────────────┴───────────────────────────────────┐
│                         WORKER NODES                             │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Worker Node 1                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │   Kubelet    │  │  Kube-proxy  │  │  Container   │    │ │
│  │  │              │  │              │  │   Runtime    │    │ │
│  │  │  - Pod mgmt  │  │  - Network   │  │  (Docker/    │    │ │
│  │  │  - Container │  │    rules     │  │  containerd) │    │ │
│  │  │    health    │  │  - Load      │  │              │    │ │
│  │  └──────────────┘  │    balance   │  └──────────────┘    │ │
│  │                    └──────────────┘                       │ │
│  │                                                            │ │
│  │  ┌────────────────────────────────────────────────────┐  │ │
│  │  │                    PODS                            │  │ │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │  │ │
│  │  │  │Container │  │Container │  │Container │        │  │ │
│  │  │  │    1     │  │    2     │  │    3     │        │  │ │
│  │  │  └──────────┘  └──────────┘  └──────────┘        │  │ │
│  │  └────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Worker Node 2                         │ │
│  │  (Same components as Node 1)                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Worker Node N                         │ │
│  │  (Same components as Node 1)                               │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

## Control Plane Components

### 1. API Server (kube-apiserver)
**Purpose:** Frontend for Kubernetes control plane
- Exposes REST API
- Authenticates and validates requests
- Updates etcd
- Entry point for all administrative tasks

**What it achieves:**
- Central communication hub
- Secure access control
- Request validation

### 2. etcd
**Purpose:** Distributed key-value store
- Stores cluster state
- Stores configuration data
- Provides consistency

**What it achieves:**
- Single source of truth
- Cluster state persistence
- High availability

### 3. Scheduler (kube-scheduler)
**Purpose:** Assigns pods to nodes
- Watches for new pods
- Selects optimal node
- Considers resources, constraints

**What it achieves:**
- Efficient resource utilization
- Workload distribution
- Constraint satisfaction

### 4. Controller Manager (kube-controller-manager)
**Purpose:** Runs controller processes
- Node Controller: Monitors node health
- Replication Controller: Maintains pod count
- Endpoints Controller: Populates endpoints
- Service Account Controller: Creates default accounts

**What it achieves:**
- Desired state maintenance
- Self-healing
- Automated management

## Worker Node Components

### 1. Kubelet
**Purpose:** Agent on each node
- Registers node with API server
- Manages pod lifecycle
- Reports node/pod status
- Executes container operations

**What it achieves:**
- Pod execution
- Health monitoring
- Resource reporting

### 2. Kube-proxy
**Purpose:** Network proxy
- Maintains network rules
- Enables service abstraction
- Load balances traffic

**What it achieves:**
- Service networking
- Traffic routing
- Load distribution

### 3. Container Runtime
**Purpose:** Runs containers
- Docker, containerd, CRI-O
- Pulls images
- Starts/stops containers

**What it achieves:**
- Container execution
- Image management
- Resource isolation

## Communication Flow

### Pod Creation Flow
```
1. kubectl → API Server
2. API Server → etcd (store pod spec)
3. Scheduler watches API Server
4. Scheduler selects node → API Server
5. API Server → etcd (update pod binding)
6. Kubelet watches API Server
7. Kubelet → Container Runtime (create container)
8. Kubelet → API Server (report status)
```

### Service Access Flow
```
1. Client → Service IP
2. Kube-proxy intercepts
3. Kube-proxy → Pod IP (load balanced)
4. Pod processes request
5. Response → Client
```

## Add-ons

### DNS (CoreDNS)
- Service discovery
- DNS-based naming

### Dashboard
- Web UI for cluster management

### Ingress Controller
- HTTP/HTTPS routing
- Load balancing

### Metrics Server
- Resource metrics collection
- HPA support

## High-Level Workflow

```
Developer → kubectl → API Server → etcd
                          ↓
                      Scheduler
                          ↓
                      Kubelet → Container Runtime → Pod
                          ↓
                      Kube-proxy (networking)
```

## Key Concepts

### Desired State
- User declares desired state
- Controllers maintain desired state
- Self-healing when state drifts

### Declarative Configuration
- YAML/JSON manifests
- Describe what you want
- Kubernetes figures out how

### Reconciliation Loop
- Controllers continuously watch
- Compare current vs desired state
- Take action to reconcile
