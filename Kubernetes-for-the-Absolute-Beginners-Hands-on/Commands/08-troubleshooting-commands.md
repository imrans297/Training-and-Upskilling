# Troubleshooting Commands

## Purpose
Diagnose and resolve issues in Kubernetes clusters and applications.

## What You'll Achieve
- Debug pod failures and crashes
- Troubleshoot network connectivity
- Identify resource issues
- Analyze cluster health
- Resolve common problems

---

## Debug Pods
```bash
# Pod logs - View application output
# Purpose: Debug application errors, trace issues
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # Follow logs
kubectl logs <pod-name> --previous  # Crashed container logs
kubectl logs <pod-name> -c <container-name>  # Multi-container

# Describe pod - Detailed pod information
# Purpose: View events, errors, resource issues
kubectl describe pod <pod-name>

# Events - Cluster-wide events
# Purpose: See what's happening in cluster
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp  # Chronological
kubectl get events -w  # Watch events

# Pod shell
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- /bin/sh

# Debug with ephemeral container
kubectl debug <pod-name> -it --image=busybox
```

## Resource Status
```bash
# Get all resources
kubectl get all
kubectl get all -A

# Wide output
kubectl get pods -o wide
kubectl get nodes -o wide

# YAML output
kubectl get pod <pod-name> -o yaml
kubectl get deployment <name> -o yaml

# JSON output
kubectl get pod <pod-name> -o json
```

## Network Debugging
```bash
# Port forward - Access pod locally
# Purpose: Test pod without service
kubectl port-forward <pod-name> 8080:80

# Run test pod - Temporary debug pod
# Purpose: Test network, DNS, connectivity
kubectl run test --image=busybox -it --rm -- /bin/sh

# DNS test - Verify DNS resolution
# Purpose: Debug service discovery issues
kubectl run test --image=busybox -it --rm -- nslookup kubernetes.default

# Curl test
kubectl run curl --image=curlimages/curl -it --rm -- curl http://service-name

# Network connectivity
kubectl exec <pod-name> -- ping <ip-address>
kubectl exec <pod-name> -- curl http://service-name
```

## Node Debugging
```bash
# Node status - Check node health
# Purpose: Identify node issues, capacity problems
kubectl get nodes
kubectl describe node <node-name>

# Node conditions
kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}'

# Node resources
kubectl top nodes
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
```

## Cluster Debugging
```bash
# Cluster info - Cluster status and details
# Purpose: Verify cluster health, get diagnostics
kubectl cluster-info
kubectl cluster-info dump  # Full diagnostic dump

# Component status
kubectl get componentstatuses
kubectl get cs

# API resources
kubectl api-resources
kubectl api-versions
```

## Performance
```bash
# Resource usage
kubectl top nodes
kubectl top pods
kubectl top pods -A

# Metrics
kubectl get --raw /metrics
```

## Logs
```bash
# Container logs
kubectl logs <pod-name>
kubectl logs <pod-name> --all-containers=true
kubectl logs -l app=nginx

# Previous container logs
kubectl logs <pod-name> --previous

# Tail logs
kubectl logs <pod-name> --tail=100
kubectl logs <pod-name> --since=1h
```

## Common Issues

### Pod Not Starting
```bash
# Check pod status
kubectl get pod <pod-name>
kubectl describe pod <pod-name>

# Check events
kubectl get events --field-selector involvedObject.name=<pod-name>

# Check logs
kubectl logs <pod-name>
```

### Image Pull Errors
```bash
# Check image name
kubectl describe pod <pod-name> | grep Image

# Check secrets
kubectl get secrets
kubectl describe secret <secret-name>
```

### CrashLoopBackOff
```bash
# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Check liveness/readiness probes
kubectl describe pod <pod-name> | grep -A 10 Liveness
```

### Service Not Accessible
```bash
# Check service
kubectl get svc <service-name>
kubectl describe svc <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Check pod labels
kubectl get pods --show-labels
```

## Cleanup
```bash
# Delete failed pods - Clean up failed pods
# Purpose: Remove clutter, free resources
kubectl delete pods --field-selector status.phase=Failed

# Delete evicted pods
kubectl get pods -A | grep Evicted | awk '{print $2 " -n " $1}' | xargs kubectl delete pod

# Force delete pod
kubectl delete pod <pod-name> --force --grace-period=0
```
