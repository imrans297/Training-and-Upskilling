# Advanced Kubernetes Commands

## Purpose
Master advanced workloads, RBAC, resource management, and cluster operations.

## What You'll Achieve
- Deploy stateful applications
- Run background tasks and scheduled jobs
- Implement security with RBAC
- Manage node operations
- Control resource allocation

---

## StatefulSet Commands
```bash
# Create StatefulSet - Deploy stateful application
# Purpose: Ordered deployment with stable identities
kubectl create -f statefulset.yaml
kubectl apply -f statefulset.yaml

# List StatefulSets
kubectl get statefulsets
kubectl get sts

# Scale StatefulSet - Change replica count
# Purpose: Scale databases, stateful apps with order
kubectl scale statefulset <name> --replicas=5

# Delete StatefulSet
kubectl delete statefulset <name>
```

## DaemonSet Commands
```bash
# Create DaemonSet - Deploy pod on every node
# Purpose: Run logging, monitoring agents cluster-wide
kubectl create -f daemonset.yaml
kubectl apply -f daemonset.yaml

# List DaemonSets
kubectl get daemonsets
kubectl get ds

# Describe DaemonSet
kubectl describe daemonset <name>
```

## Job Commands
```bash
# Create Job - Run task to completion
# Purpose: Batch processing, one-time tasks
kubectl create job hello --image=busybox -- echo "Hello World"
kubectl create -f job.yaml

# List Jobs
kubectl get jobs

# View Job logs
kubectl logs job/<job-name>

# Delete Job
kubectl delete job <job-name>
```

## CronJob Commands
```bash
# Create CronJob - Schedule recurring jobs
# Purpose: Periodic tasks, backups, cleanup
kubectl create cronjob hello --image=busybox --schedule="*/5 * * * *" -- echo "Hello"
kubectl create -f cronjob.yaml

# List CronJobs
kubectl get cronjobs
kubectl get cj

# Suspend CronJob - Pause scheduled execution
# Purpose: Temporarily disable scheduled jobs
kubectl patch cronjob <name> -p '{"spec":{"suspend":true}}'

# Delete CronJob
kubectl delete cronjob <name>
```

## Ingress Commands
```bash
# Create Ingress
kubectl create -f ingress.yaml
kubectl apply -f ingress.yaml

# List Ingress
kubectl get ingress
kubectl get ing

# Describe Ingress
kubectl describe ingress <name>
```

## PersistentVolume Commands
```bash
# Create PV
kubectl create -f pv.yaml
kubectl apply -f pv.yaml

# List PVs
kubectl get pv

# Describe PV
kubectl describe pv <pv-name>

# Delete PV
kubectl delete pv <pv-name>
```

## PersistentVolumeClaim Commands
```bash
# Create PVC
kubectl create -f pvc.yaml
kubectl apply -f pvc.yaml

# List PVCs
kubectl get pvc

# Describe PVC
kubectl describe pvc <pvc-name>

# Delete PVC
kubectl delete pvc <pvc-name>
```

## Resource Management
```bash
# Top nodes - View node resource usage
# Purpose: Monitor CPU/memory consumption per node
kubectl top nodes

# Top pods - View pod resource usage
# Purpose: Identify resource-hungry pods
kubectl top pods
kubectl top pods -A  # All namespaces

# Resource usage
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
```

## Labels and Selectors
```bash
# Add label - Tag resource with label
# Purpose: Organize, select, filter resources
kubectl label pod <pod-name> env=prod

# Remove label
kubectl label pod <pod-name> env-

# Update label
kubectl label pod <pod-name> env=dev --overwrite

# Get by label - Filter resources by labels
# Purpose: Select specific resources for operations
kubectl get pods -l env=prod
kubectl get pods -l 'env in (prod,dev)'  # Multiple values
kubectl get pods -l env!=prod  # Exclude
```

## Annotations
```bash
# Add annotation
kubectl annotate pod <pod-name> description="My pod"

# Remove annotation
kubectl annotate pod <pod-name> description-
```

## Taints and Tolerations
```bash
# Add taint to node - Prevent pod scheduling
# Purpose: Reserve nodes for specific workloads
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node-name> key:NoSchedule-

# View taints
kubectl describe node <node-name> | grep Taints
```

## Drain and Cordon
```bash
# Drain node - Safely evict all pods
# Purpose: Prepare node for maintenance
kubectl drain <node-name> --ignore-daemonsets

# Cordon node - Mark node as unschedulable
# Purpose: Prevent new pods, keep existing ones
kubectl cordon <node-name>

# Uncordon node - Allow pod scheduling again
# Purpose: Return node to service after maintenance
kubectl uncordon <node-name>
```

## RBAC Commands
```bash
# Create ServiceAccount - Identity for pods
# Purpose: Give pods specific permissions
kubectl create serviceaccount <sa-name>

# Create Role - Define permissions in namespace
# Purpose: Grant specific resource access
kubectl create role <role-name> --verb=get,list --resource=pods

# Create RoleBinding
kubectl create rolebinding <binding-name> --role=<role-name> --serviceaccount=default:<sa-name>

# Create ClusterRole
kubectl create clusterrole <role-name> --verb=get,list --resource=pods

# Create ClusterRoleBinding
kubectl create clusterrolebinding <binding-name> --clusterrole=<role-name> --serviceaccount=default:<sa-name>

# Check permissions - Verify access rights
# Purpose: Test RBAC configuration
kubectl auth can-i create pods
kubectl auth can-i create pods --as=<user>  # Check for other user
```

## Network Policy
```bash
# Create NetworkPolicy
kubectl create -f networkpolicy.yaml

# List NetworkPolicies
kubectl get networkpolicies
kubectl get netpol

# Describe NetworkPolicy
kubectl describe networkpolicy <name>
```
