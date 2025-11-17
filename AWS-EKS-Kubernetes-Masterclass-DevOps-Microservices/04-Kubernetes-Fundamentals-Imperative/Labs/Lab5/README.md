# Lab 5: Troubleshooting and Best Practices

## What We're Achieving
Master Kubernetes troubleshooting techniques, implement best practices, and develop skills for production-ready cluster management.

## What We're Doing
- Diagnosing common Kubernetes issues
- Implementing monitoring and observability
- Learning debugging techniques and tools
- Applying security and performance best practices
- Preparing for production deployments

## Prerequisites
- Completed Labs 1-4 (Pods, ReplicaSets, Deployments, Services)
- EKS cluster running
- kubectl configured

## Definitions

### Observability
The ability to understand the internal state of a system based on external outputs (logs, metrics, traces).

### Health Checks
- **Liveness Probe**: Determines if container is running
- **Readiness Probe**: Determines if container is ready to serve traffic
- **Startup Probe**: Determines if container has started successfully

### Resource Management
- **Requests**: Minimum resources guaranteed to container
- **Limits**: Maximum resources container can use
- **QoS Classes**: Guaranteed, Burstable, BestEffort

## Lab Exercises

### Exercise 1: Pod Troubleshooting Scenarios
```bash
# Scenario 1: ImagePullBackOff
kubectl run broken-image --image=nginx:nonexistent-tag

# Troubleshoot
kubectl get pods
kubectl describe pod broken-image
kubectl get events --sort-by=.metadata.creationTimestamp

# Fix the issue
kubectl delete pod broken-image
kubectl run fixed-image --image=nginx

# Scenario 2: CrashLoopBackOff
kubectl run crash-pod --image=busybox --command -- sh -c "exit 1"

# Troubleshoot
kubectl get pods
kubectl describe pod crash-pod
kubectl logs crash-pod
kubectl logs crash-pod --previous

# Fix the issue
kubectl delete pod crash-pod
kubectl run working-pod --image=busybox --command -- sh -c "sleep 3600"
```

### Exercise 2: Resource Issues and OOMKilled
```bash
# Create pod with insufficient memory
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memory-stress
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
    resources:
      limits:
        memory: "100Mi"
      requests:
        memory: "50Mi"
EOF

# Monitor the pod
kubectl get pods -w
kubectl describe pod memory-stress
kubectl top pod memory-stress
```

### Exercise 3: Network Connectivity Issues
```bash
# Create deployment and service with port mismatch
kubectl create deployment web-app --image=nginx --replicas=2
kubectl expose deployment web-app --port=8080 --target-port=80 --name=web-service

# Test connectivity issue
kubectl run test-client --image=busybox --rm -it -- sh
# Inside pod: wget -qO- web-service:8080
# This should work

# Create service with wrong target port
kubectl expose deployment web-app --port=80 --target-port=8080 --name=broken-service

# Test broken connectivity
kubectl run test-client --image=busybox --rm -it -- sh
# Inside pod: wget -qO- broken-service
# This will fail

# Debug the issue
kubectl get endpoints broken-service
kubectl describe service broken-service
```

### Exercise 4: Health Checks Implementation
```bash
# Create deployment with health checks
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthy-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: healthy-app
  template:
    metadata:
      labels:
        app: healthy-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
EOF

# Monitor health check status
kubectl get pods
kubectl describe pod <pod-name>
```

### Exercise 5: Resource Management Best Practices
```bash
# Create deployment with proper resource management
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-managed-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: resource-managed-app
  template:
    metadata:
      labels:
        app: resource-managed-app
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
        ports:
        - containerPort: 80
EOF

# Check resource allocation
kubectl describe nodes
kubectl top nodes
kubectl top pods
kubectl describe pod <pod-name>
```

### Exercise 6: Logging and Monitoring Setup
```bash
# Create application with structured logging
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logging-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: logging-app
  template:
    metadata:
      labels:
        app: logging-app
    spec:
      containers:
      - name: logger
        image: busybox
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo $(date) - INFO - Application running; sleep 10; done"]
EOF

# View logs
kubectl logs -l app=logging-app
kubectl logs -l app=logging-app -f --tail=10
kubectl logs -l app=logging-app --since=1h
```

### Exercise 7: Security Best Practices
```bash
# Create deployment with security context
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: nginx
        image: nginx
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp-volume
          mountPath: /tmp
        - name: var-cache-nginx
          mountPath: /var/cache/nginx
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp-volume
        emptyDir: {}
      - name: var-cache-nginx
        emptyDir: {}
      - name: var-run
        emptyDir: {}
EOF

# Check security context
kubectl describe pod <pod-name>
```

### Exercise 8: ConfigMaps and Secrets Management
```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=database_url=postgresql://localhost:5432/mydb \
  --from-literal=debug_mode=true

# Create Secret
kubectl create secret generic app-secrets \
  --from-literal=db_password=supersecret \
  --from-literal=api_key=abc123xyz

# Create deployment using ConfigMap and Secret
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
      - name: app
        image: busybox
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo 'App running with config'; sleep 30; done"]
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_url
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db_password
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: app-config
      - name: secret-volume
        secret:
          secretName: app-secrets
EOF

# Verify configuration
kubectl exec -it <pod-name> -- env | grep -E "(DATABASE_URL|DB_PASSWORD)"
kubectl exec -it <pod-name> -- ls /etc/config
kubectl exec -it <pod-name> -- ls /etc/secrets
```

## Advanced Troubleshooting

### Exercise 9: Cluster-Level Debugging
```bash
# Check cluster components
kubectl get componentstatuses
kubectl get nodes
kubectl describe nodes

# Check system pods
kubectl get pods -n kube-system
kubectl logs -n kube-system <system-pod-name>

# Check cluster events
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp

# Check API server logs (if accessible)
kubectl logs -n kube-system -l component=kube-apiserver
```

### Exercise 10: Performance Troubleshooting
```bash
# Create resource-intensive workload
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-intensive
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cpu-intensive
  template:
    metadata:
      labels:
        app: cpu-intensive
    spec:
      containers:
      - name: stress
        image: polinux/stress
        command: ["stress"]
        args: ["--cpu", "1", "--timeout", "300s"]
        resources:
          requests:
            cpu: "100m"
          limits:
            cpu: "200m"
EOF

# Monitor performance
kubectl top nodes
kubectl top pods
kubectl describe nodes
```

## Troubleshooting Toolkit

### Essential Commands
```bash
# Pod debugging
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl exec -it <pod-name> -- /bin/bash

# Service debugging
kubectl get services
kubectl get endpoints
kubectl describe service <service-name>

# Network debugging
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- bash

# Resource debugging
kubectl top nodes
kubectl top pods
kubectl describe nodes

# Event debugging
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector type=Warning
```

### Debugging Tools
```bash
# Install debugging tools in cluster
kubectl apply -f https://raw.githubusercontent.com/nicolaka/netshoot/master/netshoot-daemonset.yaml

# Use debug container (Kubernetes 1.23+)
kubectl debug <pod-name> -it --image=busybox --target=<container-name>
```

## Best Practices Checklist

### Resource Management
- [ ] Set resource requests and limits
- [ ] Use appropriate QoS classes
- [ ] Monitor resource utilization
- [ ] Implement horizontal pod autoscaling

### Health and Monitoring
- [ ] Configure liveness probes
- [ ] Configure readiness probes
- [ ] Implement structured logging
- [ ] Set up monitoring and alerting

### Security
- [ ] Use non-root containers
- [ ] Implement security contexts
- [ ] Use secrets for sensitive data
- [ ] Apply network policies

### Reliability
- [ ] Use multiple replicas
- [ ] Implement graceful shutdown
- [ ] Configure pod disruption budgets
- [ ] Use anti-affinity rules

## Cleanup
```bash
# Delete all resources created in this lab
kubectl delete deployment broken-image crash-pod healthy-app resource-managed-app logging-app secure-app config-app cpu-intensive
kubectl delete pod memory-stress working-pod
kubectl delete service web-service broken-service
kubectl delete configmap app-config
kubectl delete secret app-secrets

# Verify cleanup
kubectl get all
```

## Cost Optimization Tips
1. Right-size resource requests and limits
2. Use spot instances for non-critical workloads
3. Implement cluster autoscaling
4. Monitor and eliminate unused resources
5. Use namespace resource quotas
6. Schedule workloads efficiently

## Production Readiness Checklist
- [ ] Resource limits configured
- [ ] Health checks implemented
- [ ] Logging and monitoring setup
- [ ] Security policies applied
- [ ] Backup and disaster recovery planned
- [ ] CI/CD pipeline integrated
- [ ] Documentation updated

## Key Takeaways
1. Proactive monitoring prevents issues
2. Resource management is crucial for stability
3. Health checks enable self-healing
4. Security should be built-in, not bolted-on
5. Structured logging aids troubleshooting
6. Regular cluster maintenance is essential
7. Documentation and runbooks save time

## Next Steps
- Implement monitoring solutions (Prometheus, Grafana)
- Learn about Kubernetes operators
- Explore service mesh technologies
- Study advanced networking concepts
- Practice disaster recovery scenarios
- Prepare for CKA/CKAD certifications