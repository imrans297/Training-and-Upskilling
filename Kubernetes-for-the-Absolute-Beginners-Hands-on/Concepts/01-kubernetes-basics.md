# Kubernetes Basics

## What is Kubernetes?
Open-source container orchestration platform for automating deployment, scaling, and management of containerized applications.

## Why Kubernetes?
- Automatic scaling
- Self-healing
- Load balancing
- Automated rollouts/rollbacks
- Service discovery

## Architecture

### Control Plane Components
- **API Server** - Entry point for all REST commands
- **etcd** - Distributed key-value store
- **Scheduler** - Assigns pods to nodes
- **Controller Manager** - Maintains desired state

### Node Components
- **Kubelet** - Agent on each node
- **Kube-proxy** - Network rules
- **Container Runtime** - Docker/containerd

## Basic Objects
- **Pod** - Smallest unit
- **Service** - Network abstraction
- **Volume** - Storage
- **Namespace** - Virtual cluster
