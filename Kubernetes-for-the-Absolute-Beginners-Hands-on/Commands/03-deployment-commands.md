# Deployment Commands

## Purpose
Manage application deployments with scaling, updates, and rollbacks.

## What You'll Achieve
- Deploy applications with replicas
- Scale applications up/down
- Perform rolling updates
- Rollback failed deployments
- Monitor deployment status

---

## Create Deployments
```bash
# From YAML - Create deployment from manifest
# Purpose: Deploy application with full configuration
kubectl create -f deployment.yaml
kubectl apply -f deployment.yaml  # Preferred for updates

# Create directly - Quick deployment creation
# Purpose: Fast deployment without YAML
kubectl create deployment nginx --image=nginx
kubectl create deployment nginx --image=nginx --replicas=3  # With replicas

# Dry run
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
```

## List Deployments
```bash
# All deployments
kubectl get deployments
kubectl get deploy

# Wide output
kubectl get deployments -o wide

# All namespaces
kubectl get deployments -A
```

## Deployment Details
```bash
# Describe deployment
kubectl describe deployment <deployment-name>

# Deployment status
kubectl rollout status deployment/<deployment-name>

# Deployment history
kubectl rollout history deployment/<deployment-name>
```

## Scale Deployments
```bash
# Scale replicas - Change pod count
# Purpose: Handle more/less traffic, save resources
kubectl scale deployment <deployment-name> --replicas=5

# Autoscale - Automatic scaling based on metrics
# Purpose: Dynamic scaling based on load
kubectl autoscale deployment <deployment-name> --min=2 --max=10 --cpu-percent=80
```

## Update Deployments
```bash
# Update image - Change container image
# Purpose: Deploy new version, rolling update
kubectl set image deployment/<deployment-name> nginx=nginx:1.19

# Edit deployment
kubectl edit deployment <deployment-name>

# Apply changes
kubectl apply -f deployment.yaml

# Record change
kubectl apply -f deployment.yaml --record
```

## Rollback Deployments
```bash
# Rollback to previous - Revert to last version
# Purpose: Recover from bad deployment
kubectl rollout undo deployment/<deployment-name>

# Rollback to specific revision - Revert to specific version
# Purpose: Go back to known good state
kubectl rollout undo deployment/<deployment-name> --to-revision=2

# Pause rollout - Stop deployment update
# Purpose: Make multiple changes before resuming
kubectl rollout pause deployment/<deployment-name>

# Resume rollout
kubectl rollout resume deployment/<deployment-name>
```

## Delete Deployments
```bash
# Delete deployment
kubectl delete deployment <deployment-name>

# Delete from file
kubectl delete -f deployment.yaml

# Delete all
kubectl delete deployments --all
```

## Restart Deployment
```bash
# Restart deployment - Recreate all pods
# Purpose: Apply config changes, refresh pods
kubectl rollout restart deployment/<deployment-name>
```
