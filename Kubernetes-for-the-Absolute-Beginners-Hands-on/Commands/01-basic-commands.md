# Basic Kubernetes Commands

## Purpose
Learn fundamental kubectl commands to interact with Kubernetes cluster and understand cluster configuration.

## What You'll Achieve
- View cluster information and health
- Understand cluster configuration
- Navigate between contexts
- Access help and documentation

---

## Cluster Information
```bash
# Cluster info - Shows cluster master and services URLs
# Purpose: Verify cluster is running and accessible
kubectl cluster-info

# View nodes - Lists all nodes in cluster
# Purpose: Check node status, roles, and versions
kubectl get nodes
kubectl get nodes -o wide  # Shows IPs, OS, kernel version

# Node details - Detailed node information
# Purpose: View node capacity, conditions, allocated resources
kubectl describe node <node-name>
```

## Kubectl Configuration
```bash
# View config - Shows kubeconfig file content
# Purpose: See clusters, contexts, users configured
kubectl config view

# Current context - Shows active context
# Purpose: Know which cluster you're working with
kubectl config current-context

# List contexts - Shows all available contexts
# Purpose: See all configured clusters and switch between them
kubectl config get-contexts

# Switch context - Change active cluster
# Purpose: Work with different clusters (dev/staging/prod)
kubectl config use-context <context-name>

# Set namespace - Change default namespace for commands
# Purpose: Avoid typing -n flag repeatedly
kubectl config set-context --current --namespace=<namespace>
```

## Help and Documentation
```bash
# General help - Shows all kubectl commands
# Purpose: Discover available commands and options
kubectl --help

# Command help - Shows specific command usage
# Purpose: Learn command syntax and options
kubectl get --help

# API resources - Lists all resource types
# Purpose: Discover available Kubernetes objects
kubectl api-resources

# Explain resource - Shows resource documentation
# Purpose: Understand resource fields and structure
kubectl explain pod
kubectl explain pod.spec  # Drill down into specific fields
```

## Version
```bash
# Client and server version - Shows kubectl and cluster versions
# Purpose: Verify version compatibility
kubectl version

# Short version - Concise version output
# Purpose: Quick version check
kubectl version --short
```
