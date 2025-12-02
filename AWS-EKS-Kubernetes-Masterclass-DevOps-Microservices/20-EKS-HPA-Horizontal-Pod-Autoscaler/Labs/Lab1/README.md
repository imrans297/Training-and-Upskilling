# Lab 1: HPA Setup and CPU-based Scaling

## What We're Achieving
Set up Horizontal Pod Autoscaler (HPA) to automatically scale applications based on CPU utilization and other metrics.

## What We're Doing
- Install and configure Metrics Server
- Create deployments with resource requests/limits
- Configure HPA for CPU-based scaling
- Test scaling behavior under load
- Monitor scaling events and metrics

## Prerequisites
- Shared training cluster running
- kubectl configured
- Understanding of resource requests/limits

## Lab Exercises

### Exercise 1: Verify Metrics Server Installation
```bash
# Switch to HPA namespace
kubectl config set-context --current --namespace=hpa-autoscaler

# Check if Metrics Server is installed
kubectl get deployment metrics-server -n kube-system

# If not installed, install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait for Metrics Server to be ready
kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=120s

# Verify metrics are available
kubectl top nodes
kubectl top pods -A
```

### Exercise 2: Deploy Application with Resource Specifications
```bash
# Create deployment with proper resource requests and limits
cat > cpu-demo-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-demo-app
  namespace: hpa-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-demo-app
  template:
    metadata:
      labels:
        app: cpu-demo-app
    spec:
      containers:
      - name: cpu-demo
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: cpu-demo-service
  namespace: hpa-autoscaler
spec:
  selector:
    app: cpu-demo-app
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
EOF

kubectl apply -f cpu-demo-app.yaml

# Wait for deployment to be ready
kubectl wait --for=condition=Available deployment/cpu-demo-app -n hpa-autoscaler --timeout=120s

# Check resource usage
kubectl top pods -n hpa-autoscaler
```

### Exercise 3: Create Basic HPA
```bash
# Create HPA using kubectl
kubectl autoscale deployment cpu-demo-app \
  --cpu-percent=50 \
  --min=1 \
  --max=10 \
  -n hpa-autoscaler

# Check HPA status
kubectl get hpa -n hpa-autoscaler
kubectl describe hpa cpu-demo-app -n hpa-autoscaler

# View HPA in YAML format
kubectl get hpa cpu-demo-app -n hpa-autoscaler -o yaml
```

### Exercise 4: Create Advanced HPA with YAML
```bash
# Delete the basic HPA
kubectl delete hpa cpu-demo-app -n hpa-autoscaler

# Create advanced HPA with more configuration
cat > advanced-hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-demo-app-hpa
  namespace: hpa-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cpu-demo-app
  minReplicas: 2
  maxReplicas: 15
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
EOF

kubectl apply -f advanced-hpa.yaml

# Check the advanced HPA
kubectl get hpa -n hpa-autoscaler
kubectl describe hpa cpu-demo-app-hpa -n hpa-autoscaler
```

### Exercise 5: Generate Load and Test Scaling
```bash
# Create load generator pod
cat > load-generator.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: load-generator
  namespace: hpa-autoscaler
spec:
  containers:
  - name: load-generator
    image: busybox
    command: ["/bin/sh"]
    args:
    - -c
    - |
      while true; do
        wget -q -O- http://cpu-demo-service.hpa-autoscaler.svc.cluster.local
        sleep 0.01
      done
  restartPolicy: Never
EOF

kubectl apply -f load-generator.yaml

# Monitor HPA scaling in real-time
kubectl get hpa cpu-demo-app-hpa -n hpa-autoscaler -w &

# In another terminal, watch pods scaling
kubectl get pods -n hpa-autoscaler -w &

# Check CPU usage
watch -n 5 'kubectl top pods -n hpa-autoscaler'
```

### Exercise 6: Multiple Load Generators for Stress Testing
```bash
# Create multiple load generators
for i in {1..3}; do
cat > load-generator-$i.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: load-generator-$i
  namespace: hpa-autoscaler
spec:
  containers:
  - name: load-generator
    image: busybox
    command: ["/bin/sh"]
    args:
    - -c
    - |
      while true; do
        for j in {1..10}; do
          wget -q -O- http://cpu-demo-service.hpa-autoscaler.svc.cluster.local &
        done
        sleep 1
      done
  restartPolicy: Never
EOF
kubectl apply -f load-generator-$i.yaml
done

# Monitor scaling behavior
kubectl get hpa cpu-demo-app-hpa -n hpa-autoscaler
kubectl get pods -n hpa-autoscaler | grep cpu-demo-app
kubectl top pods -n hpa-autoscaler
```

### Exercise 7: Monitor Scaling Events
```bash
# Check HPA events
kubectl describe hpa cpu-demo-app-hpa -n hpa-autoscaler

# Check deployment events
kubectl describe deployment cpu-demo-app -n hpa-autoscaler

# View scaling events
kubectl get events -n hpa-autoscaler --sort-by=.metadata.creationTimestamp

# Check HPA metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/hpa-autoscaler/pods | jq .

# View HPA status in detail
kubectl get hpa cpu-demo-app-hpa -n hpa-autoscaler -o yaml
```

### Exercise 8: Test Scale Down Behavior
```bash
# Stop load generators
kubectl delete pod load-generator load-generator-1 load-generator-2 load-generator-3 -n hpa-autoscaler

# Monitor scale down (takes several minutes due to stabilization window)
kubectl get hpa cpu-demo-app-hpa -n hpa-autoscaler -w

# Check current CPU usage
kubectl top pods -n hpa-autoscaler

# Watch pods scaling down
kubectl get pods -n hpa-autoscaler -w
```

### Exercise 9: Custom Metrics HPA (Advanced)
```bash
# Create HPA with custom metrics (example with requests per second)
cat > custom-metrics-hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: custom-metrics-hpa
  namespace: hpa-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cpu-demo-app
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "100"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Pods
        value: 1
        periodSeconds: 60
EOF

# Note: This requires custom metrics server (like Prometheus Adapter)
# kubectl apply -f custom-metrics-hpa.yaml
echo "Custom metrics HPA example created (requires custom metrics server)"
```

### Exercise 10: HPA Troubleshooting
```bash
# Common troubleshooting commands
echo "=== HPA Status ==="
kubectl get hpa -n hpa-autoscaler

echo "=== HPA Details ==="
kubectl describe hpa cpu-demo-app-hpa -n hpa-autoscaler

echo "=== Pod Resource Usage ==="
kubectl top pods -n hpa-autoscaler

echo "=== Deployment Status ==="
kubectl get deployment cpu-demo-app -n hpa-autoscaler

echo "=== Recent Events ==="
kubectl get events -n hpa-autoscaler --sort-by=.metadata.creationTimestamp | tail -10

echo "=== Metrics Server Status ==="
kubectl get pods -n kube-system | grep metrics-server

echo "=== HPA Controller Logs ==="
kubectl logs -n kube-system -l k8s-app=metrics-server --tail=20
```

## Cleanup
```bash
# Delete HPA
kubectl delete hpa cpu-demo-app-hpa -n hpa-autoscaler

# Delete load generators
kubectl delete pod --all -n hpa-autoscaler

# Delete application
kubectl delete -f cpu-demo-app.yaml

# Clean up files
rm -f cpu-demo-app.yaml advanced-hpa.yaml load-generator.yaml custom-metrics-hpa.yaml
for i in {1..3}; do rm -f load-generator-$i.yaml; done
```

## Key Takeaways
1. HPA requires Metrics Server for CPU/memory-based scaling
2. Resource requests are mandatory for HPA to work
3. Scaling decisions are based on average utilization across all pods
4. Stabilization windows prevent rapid scaling oscillations
5. Scale-up is typically faster than scale-down for stability
6. Multiple metrics can be used for scaling decisions
7. Custom metrics require additional components (Prometheus Adapter)
8. Proper monitoring is essential for HPA troubleshooting

## Next Steps
- Move to Lab 2: Memory-based and Custom Metrics Scaling
- Practice with different scaling policies
- Learn about Vertical Pod Autoscaler (VPA) integration