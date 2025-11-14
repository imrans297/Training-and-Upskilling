# Getting Started with Kubernetes

## What is Kubernetes?
Container orchestration platform for automating deployment, scaling, and management of containerized applications.

## Key Benefits
- Automated rollouts and rollbacks
- Self-healing
- Horizontal scaling
- Service discovery and load balancing
- Storage orchestration

## Architecture Components

### Master Node (Control Plane)
- **API Server** - Frontend for Kubernetes control plane
- **etcd** - Key-value store for cluster data
- **Scheduler** - Assigns pods to nodes
- **Controller Manager** - Runs controller processes

### Worker Nodes
- **Kubelet** - Agent running on each node
- **Kube-proxy** - Network proxy
- **Container Runtime** - Docker, containerd, etc.

## Basic Concepts

### Pod
Smallest deployable unit in Kubernetes. Contains one or more containers.

### Service
Exposes pods to network traffic.

### Deployment
Manages ReplicaSets and provides declarative updates.

### Namespace
Virtual clusters for resource isolation.
