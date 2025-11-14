# Kubectl Cheat Sheet

## Quick Reference

### Cluster Info
```bash
kubectl cluster-info
kubectl get nodes
kubectl version
```

### Resources
```bash
kubectl get all
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get namespaces
```

### Create/Apply
```bash
kubectl create -f file.yaml
kubectl apply -f file.yaml
kubectl run pod-name --image=nginx
kubectl create deployment name --image=nginx
```

### Describe/Logs
```bash
kubectl describe pod <name>
kubectl logs <pod-name>
kubectl logs -f <pod-name>
kubectl exec -it <pod-name> -- /bin/bash
```

### Scale/Update
```bash
kubectl scale deployment <name> --replicas=5
kubectl set image deployment/<name> container=image:tag
kubectl rollout status deployment/<name>
kubectl rollout undo deployment/<name>
```

### Delete
```bash
kubectl delete pod <name>
kubectl delete -f file.yaml
kubectl delete deployment <name>
```

### Namespace
```bash
kubectl get pods -n <namespace>
kubectl create namespace <name>
kubectl config set-context --current --namespace=<name>
```

### Labels
```bash
kubectl get pods -l app=nginx
kubectl label pod <name> env=prod
kubectl get pods --show-labels
```

### Output Formats
```bash
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
```

### Port Forward
```bash
kubectl port-forward <pod-name> 8080:80
kubectl port-forward service/<svc-name> 8080:80
```

### Troubleshooting
```bash
kubectl get events
kubectl top nodes
kubectl top pods
kubectl describe pod <name>
kubectl logs <pod-name> --previous
```
