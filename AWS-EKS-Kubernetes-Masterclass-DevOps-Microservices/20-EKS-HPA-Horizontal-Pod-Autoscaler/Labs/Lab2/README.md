# Lab 2: Memory-based and Custom Metrics Scaling

## What We're Achieving
Implement advanced HPA configurations using memory metrics, custom metrics, and multiple scaling criteria for production-ready autoscaling.

## What We're Doing
- Configure memory-based HPA scaling
- Set up custom metrics with Prometheus
- Implement multi-metric HPA policies
- Create advanced scaling behaviors and policies

## Prerequisites
- Completed Lab 1 (CPU-based HPA)
- Metrics Server running
- Understanding of Prometheus metrics (optional)

## Lab Exercises

### Exercise 1: Memory-based HPA
```bash
# Switch to HPA namespace
kubectl config set-context --current --namespace=hpa-autoscaler

# Create memory-intensive application
cat > memory-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-demo-app
  namespace: hpa-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-demo-app
  template:
    metadata:
      labels:
        app: memory-demo-app
    spec:
      containers:
      - name: memory-app
        image: polinux/stress
        command: ["stress"]
        args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
          limits:
            cpu: 200m
            memory: 400Mi
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: memory-demo-service
  namespace: hpa-autoscaler
spec:
  selector:
    app: memory-demo-app
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
EOF

kubectl apply -f memory-app.yaml

# Create memory-based HPA
cat > memory-hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hpa
  namespace: hpa-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: memory-demo-app
  minReplicas: 1
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
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
      - type: Percent
        value: 50
        periodSeconds: 60
EOF

kubectl apply -f memory-hpa.yaml

# Monitor memory usage and scaling
kubectl get hpa memory-hpa -w &
kubectl top pods -n hpa-autoscaler
```

### Exercise 2: Combined CPU and Memory HPA
```bash
# Create application with both CPU and memory workload
cat > combined-workload-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: combined-workload-app
  namespace: hpa-autoscaler
spec:
  replicas: 2
  selector:
    matchLabels:
      app: combined-workload-app
  template:
    metadata:
      labels:
        app: combined-workload-app
    spec:
      containers:
      - name: workload-app
        image: nginx:alpine
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        ports:
        - containerPort: 80
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                # Start background CPU and memory load
                (while true; do dd if=/dev/zero of=/tmp/test bs=1M count=100; rm /tmp/test; sleep 1; done) &
                (while true; do for i in {1..1000}; do echo $i > /dev/null; done; sleep 0.1; done) &
---
apiVersion: v1
kind: Service
metadata:
  name: combined-workload-service
  namespace: hpa-autoscaler
spec:
  selector:
    app: combined-workload-app
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl apply -f combined-workload-app.yaml

# Create HPA with both CPU and memory metrics
cat > combined-metrics-hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: combined-metrics-hpa
  namespace: hpa-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: combined-workload-app
  minReplicas: 2
  maxReplicas: 12
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
        averageUtilization: 75
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 3
        periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 25
        periodSeconds: 60
      selectPolicy: Min
EOF

kubectl apply -f combined-metrics-hpa.yaml

# Monitor combined metrics scaling
kubectl get hpa combined-metrics-hpa -w
```

### Exercise 3: Custom Metrics Setup (Prometheus-based)
```bash
# Install Prometheus (simplified setup for demo)
cat > prometheus-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: hpa-autoscaler
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
          - hpa-autoscaler
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: hpa-autoscaler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus/'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
        - '--web.enable-lifecycle'
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus-service
  namespace: hpa-autoscaler
spec:
  selector:
    app: prometheus
  ports:
    - port: 9090
      targetPort: 9090
EOF

kubectl apply -f prometheus-config.yaml

# Create application with custom metrics
cat > custom-metrics-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-metrics-app
  namespace: hpa-autoscaler
spec:
  replicas: 2
  selector:
    matchLabels:
      app: custom-metrics-app
  template:
    metadata:
      labels:
        app: custom-metrics-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: metrics-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        - containerPort: 8080
        volumeMounts:
        - name: metrics-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: metrics-config
        configMap:
          name: metrics-nginx-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metrics-nginx-config
  namespace: hpa-autoscaler
data:
  default.conf: |
    server {
        listen 80;
        location / {
            return 200 'Custom Metrics App Running';
            add_header Content-Type text/plain;
        }
    }
    server {
        listen 8080;
        location /metrics {
            return 200 '# HELP http_requests_total Total HTTP requests
    # TYPE http_requests_total counter
    http_requests_total{method="GET",status="200"} 1000
    # HELP http_request_duration_seconds HTTP request duration
    # TYPE http_request_duration_seconds histogram
    http_request_duration_seconds_bucket{le="0.1"} 100
    http_request_duration_seconds_bucket{le="0.5"} 200
    http_request_duration_seconds_bucket{le="1.0"} 300
    http_request_duration_seconds_bucket{le="+Inf"} 400
    http_request_duration_seconds_sum 150.5
    http_request_duration_seconds_count 400';
            add_header Content-Type text/plain;
        }
    }
EOF

kubectl apply -f custom-metrics-app.yaml
```

### Exercise 4: Advanced Scaling Behaviors
```bash
# Create HPA with advanced scaling behaviors
cat > advanced-behavior-hpa.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: advanced-behavior-hpa
  namespace: hpa-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: combined-workload-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      - type: Percent
        value: 50
        periodSeconds: 60
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 1
        periodSeconds: 60
      selectPolicy: Min
EOF

kubectl apply -f advanced-behavior-hpa.yaml

# Test rapid scaling scenarios
kubectl get hpa advanced-behavior-hpa -w
```

### Exercise 5: External Metrics HPA (Conceptual)
```bash
# Example of external metrics HPA (requires external metrics adapter)
cat > external-metrics-hpa-example.yaml << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: external-metrics-hpa
  namespace: hpa-autoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: custom-metrics-app
  minReplicas: 2
  maxReplicas: 15
  metrics:
  - type: External
    external:
      metric:
        name: sqs_queue_length
        selector:
          matchLabels:
            queue: "processing-queue"
      target:
        type: AverageValue
        averageValue: "10"
  - type: External
    external:
      metric:
        name: cloudwatch_custom_metric
        selector:
          matchLabels:
            dimension: "application"
      target:
        type: Value
        value: "100"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 120
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 600
      policies:
      - type: Pods
        value: 1
        periodSeconds: 120
EOF

echo "External metrics HPA example created (requires external metrics adapter)"
# kubectl apply -f external-metrics-hpa-example.yaml
```

### Exercise 6: HPA Performance Testing
```bash
# Create load testing job
cat > hpa-load-test.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: hpa-load-test
  namespace: hpa-autoscaler
spec:
  parallelism: 5
  completions: 5
  template:
    spec:
      containers:
      - name: load-generator
        image: busybox
        command: ["/bin/sh"]
        args:
        - -c
        - |
          echo "Starting load test..."
          for i in {1..300}; do
            # Generate CPU load
            (for j in {1..1000}; do echo $j > /dev/null; done) &
            
            # Generate memory load
            dd if=/dev/zero of=/tmp/load-$i bs=1M count=50 2>/dev/null &
            
            sleep 1
          done
          
          echo "Load test completed"
          wait
      restartPolicy: Never
  backoffLimit: 3
EOF

kubectl apply -f hpa-load-test.yaml

# Monitor HPA during load test
kubectl get hpa -w
kubectl get pods -w
kubectl top pods
```

### Exercise 7: HPA Monitoring and Alerting
```bash
# Create HPA monitoring dashboard (conceptual)
cat > hpa-monitoring.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: hpa-monitoring-queries
  namespace: hpa-autoscaler
data:
  queries.txt: |
    # Prometheus queries for HPA monitoring
    
    # Current replica count
    kube_horizontalpodautoscaler_status_current_replicas
    
    # Desired replica count
    kube_horizontalpodautoscaler_status_desired_replicas
    
    # HPA scaling events
    increase(kube_horizontalpodautoscaler_status_desired_replicas[5m])
    
    # CPU utilization vs target
    (kube_horizontalpodautoscaler_status_current_replicas / kube_horizontalpodautoscaler_spec_target_metric) * 100
    
    # Memory utilization vs target
    (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100
    
    # Scaling frequency
    rate(kube_horizontalpodautoscaler_status_desired_replicas[1h])
---
apiVersion: v1
kind: Pod
metadata:
  name: hpa-monitor
  namespace: hpa-autoscaler
spec:
  containers:
  - name: monitor
    image: busybox
    command: ["/bin/sh"]
    args:
    - -c
    - |
      while true; do
        echo "=== HPA Monitoring Report ==="
        echo "Timestamp: $(date)"
        echo "Active HPAs:"
        # In real scenario, this would query Prometheus
        echo "- memory-hpa: Current=X, Desired=Y, Target=70%"
        echo "- combined-metrics-hpa: Current=A, Desired=B"
        echo "- advanced-behavior-hpa: Current=C, Desired=D"
        echo "=========================="
        sleep 60
      done
    volumeMounts:
    - name: monitoring-queries
      mountPath: /queries
  volumes:
  - name: monitoring-queries
    configMap:
      name: hpa-monitoring-queries
EOF

kubectl apply -f hpa-monitoring.yaml
```

## Cleanup
```bash
# Delete HPAs
kubectl delete hpa memory-hpa combined-metrics-hpa advanced-behavior-hpa -n hpa-autoscaler

# Delete applications
kubectl delete -f memory-app.yaml
kubectl delete -f combined-workload-app.yaml
kubectl delete -f custom-metrics-app.yaml
kubectl delete -f prometheus-config.yaml
kubectl delete -f hpa-load-test.yaml
kubectl delete -f hpa-monitoring.yaml

# Clean up files
rm -f memory-app.yaml memory-hpa.yaml combined-workload-app.yaml combined-metrics-hpa.yaml prometheus-config.yaml custom-metrics-app.yaml advanced-behavior-hpa.yaml external-metrics-hpa-example.yaml hpa-load-test.yaml hpa-monitoring.yaml
```

## Key Takeaways
1. Memory-based scaling requires proper resource requests
2. Multiple metrics can be combined for comprehensive scaling
3. Advanced behaviors provide fine-grained control over scaling
4. Custom metrics require additional infrastructure (Prometheus)
5. External metrics enable scaling based on external systems
6. Proper monitoring is essential for HPA optimization
7. Load testing helps validate HPA configurations
8. Stabilization windows prevent scaling oscillations

## Next Steps
- Move to Lab 3: Production HPA Patterns and Optimization
- Practice with real application workloads
- Learn about VPA integration and cluster autoscaling