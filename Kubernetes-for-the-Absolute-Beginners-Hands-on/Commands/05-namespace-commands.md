# Namespace Commands

## Purpose
Organize and isolate resources using virtual clusters.

## What You'll Achieve
- Create isolated environments
- Organize resources by team/project
- Apply resource quotas
- Manage multi-tenant clusters

---

## Create Namespaces
```bash
# Create namespace - Create virtual cluster
# Purpose: Isolate resources for different environments
kubectl create namespace dev
kubectl create ns staging  # Short form

# From YAML
kubectl create -f namespace.yaml
kubectl apply -f namespace.yaml
```

## List Namespaces
```bash
# All namespaces
kubectl get namespaces
kubectl get ns
```

## Namespace Details
```bash
# Describe namespace
kubectl describe namespace <namespace-name>
kubectl describe ns <namespace-name>
```

## Work with Namespaces
```bash
# Set default namespace - Change working namespace
# Purpose: Avoid typing -n flag in every command
kubectl config set-context --current --namespace=dev

# Get resources in namespace - View namespace resources
# Purpose: See what's running in specific namespace
kubectl get pods -n dev
kubectl get all -n dev  # All resource types

# Create resource in namespace
kubectl create -f pod.yaml -n dev
kubectl run nginx --image=nginx -n dev
```

## Delete Namespaces
```bash
# Delete namespace - Remove namespace and all resources
# Purpose: Clean up entire environment at once
kubectl delete namespace dev
kubectl delete ns staging
```

## Resource Quotas
```bash
# Create quota - Limit namespace resources
# Purpose: Prevent resource exhaustion, enforce limits
kubectl create quota dev-quota --hard=cpu=10,memory=10Gi,pods=10 -n dev

# Get quotas - View resource usage vs limits
# Purpose: Monitor quota consumption
kubectl get quota -n dev
kubectl describe quota dev-quota -n dev  # Detailed usage
```

## Limit Ranges
```bash
# Get limit ranges
kubectl get limitrange -n dev
kubectl describe limitrange <name> -n dev
```
