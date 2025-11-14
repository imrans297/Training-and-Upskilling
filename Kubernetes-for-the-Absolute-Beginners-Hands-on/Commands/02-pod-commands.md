# Pod Commands

## Purpose
Master pod lifecycle management - create, monitor, debug, and troubleshoot pods.

## What You'll Achieve
- Create and manage pods
- Access pod logs and shell
- Debug running containers
- Copy files to/from pods
- Monitor pod health and status

---

## Create Pods
```bash
# From YAML - Create pod from manifest file
# Purpose: Declarative pod creation with full configuration
kubectl create -f pod.yaml  # Create only, fails if exists
kubectl apply -f pod.yaml   # Create or update

# Run pod directly - Quick pod creation
# Purpose: Fast pod creation for testing without YAML
kubectl run nginx --image=nginx
kubectl run nginx --image=nginx --port=80  # Expose container port

# Dry run - Generate YAML without creating
# Purpose: Create YAML templates quickly
kubectl run nginx --image=nginx --dry-run=client -o yaml
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml  # Save to file
```

## List Pods
```bash
# All pods - List pods in current namespace
# Purpose: View pod status, restarts, age
kubectl get pods
kubectl get pods -o wide  # Shows node, IP, nominated node

# All namespaces - List pods across all namespaces
# Purpose: See system pods and all applications
kubectl get pods --all-namespaces
kubectl get pods -A  # Short form

# Specific namespace
kubectl get pods -n <namespace>

# Watch pods - Real-time pod status updates
# Purpose: Monitor pod state changes live
kubectl get pods -w

# Show labels - Display pod labels
# Purpose: See pod categorization and selectors
kubectl get pods --show-labels

# Filter by label - Select pods by label
# Purpose: Find specific pods using labels
kubectl get pods -l app=nginx
```

## Pod Details
```bash
# Describe pod - Detailed pod information
# Purpose: View events, conditions, volumes, containers
kubectl describe pod <pod-name>

# Pod logs - View container output
# Purpose: Debug application issues, view stdout/stderr
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # Follow logs in real-time
kubectl logs <pod-name> --tail=50  # Last 50 lines
kubectl logs <pod-name> -c <container-name>  # Specific container

# Previous logs - Logs from crashed container
# Purpose: Debug why container crashed
kubectl logs <pod-name> --previous
```

## Execute Commands
```bash
# Execute command - Run command in container
# Purpose: Debug, inspect files, test connectivity
kubectl exec <pod-name> -- ls /

# Interactive shell - Access container shell
# Purpose: Interactive debugging and troubleshooting
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh  # For Alpine images

# Multi-container
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
```

## Delete Pods
```bash
# Delete pod - Remove pod
# Purpose: Clean up or force pod recreation
kubectl delete pod <pod-name>

# Delete from file
kubectl delete -f pod.yaml

# Delete all pods
kubectl delete pods --all

# Force delete - Immediate pod termination
# Purpose: Remove stuck pods
kubectl delete pod <pod-name> --force --grace-period=0
```

## Edit Pods
```bash
# Edit pod
kubectl edit pod <pod-name>

# Replace pod
kubectl replace -f pod.yaml --force
```

## Port Forwarding
```bash
# Forward port - Access pod from localhost
# Purpose: Test pod without service, local development
kubectl port-forward <pod-name> 8080:80
kubectl port-forward <pod-name> 8080:80 --address 0.0.0.0  # Allow external access
```

## Copy Files
```bash
# Copy to pod - Upload files to container
# Purpose: Add config files, test data
kubectl cp /local/file <pod-name>:/remote/path

# Copy from pod - Download files from container
# Purpose: Extract logs, retrieve generated files
kubectl cp <pod-name>:/remote/file /local/path
```
