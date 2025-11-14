# Exercise 3: Advanced Kubernetes Operations

## Challenge 1: StatefulSet with Persistent Storage
1. Create StatefulSet for MongoDB with:
   - 3 replicas
   - Headless service
   - PersistentVolumeClaim template
   - Resource limits
2. Verify ordered pod creation
3. Test pod DNS resolution
4. Scale StatefulSet
5. Verify data persistence after pod deletion

## Challenge 2: DaemonSet for Logging
1. Create DaemonSet for Fluentd logging agent
2. Mount host log directory
3. Verify pod on each node
4. Add node selector to run only on specific nodes
5. Update DaemonSet image

## Challenge 3: CronJob for Backup
1. Create CronJob that runs every 5 minutes
2. Job should backup data from PVC
3. Configure job history limits
4. Test manual job creation
5. Suspend and resume CronJob

## Challenge 4: Network Policy
1. Create three namespaces: frontend, backend, database
2. Deploy apps in each namespace
3. Create NetworkPolicy:
   - Frontend can access backend
   - Backend can access database
   - Frontend cannot access database
4. Test connectivity between pods

## Challenge 5: Resource Quotas and Limits
1. Create namespace with ResourceQuota:
   - Max 10 pods
   - Max 4 CPU
   - Max 8Gi memory
2. Create LimitRange:
   - Default CPU: 500m
   - Default memory: 256Mi
   - Max CPU: 2
   - Max memory: 2Gi
3. Deploy applications and test limits
4. Try exceeding quota

## Challenge 6: Horizontal Pod Autoscaler
1. Deploy metrics-server
2. Create deployment with resource requests
3. Create HPA with:
   - Min replicas: 2
   - Max replicas: 10
   - Target CPU: 50%
4. Generate load and observe scaling
5. Remove load and observe scale down

## Challenge 7: Init Containers
1. Create deployment with init container that:
   - Downloads configuration
   - Waits for service availability
2. Main container uses downloaded config
3. Verify init container completes before main

## Challenge 8: Liveness and Readiness Probes
1. Create deployment with:
   - Liveness probe (HTTP)
   - Readiness probe (TCP)
   - Startup probe
2. Simulate failure and observe restart
3. Test readiness probe by blocking port

## Solutions
<details>
<summary>Click to reveal solutions</summary>

### Challenge 1
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo-headless
spec:
  clusterIP: None
  selector:
    app: mongo
  ports:
  - port: 27017
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
spec:
  serviceName: mongo-headless
  replicas: 3
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:4.4
        ports:
        - containerPort: 27017
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1
            memory: 1Gi
        volumeMounts:
        - name: data
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

### Challenge 2
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

### Challenge 3
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "*/5 * * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ['sh', '-c', 'tar -czf /backup/data-$(date +%Y%m%d-%H%M%S).tar.gz /data']
            volumeMounts:
            - name: data
              mountPath: /data
            - name: backup
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: data-pvc
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
```

### Challenge 6
```bash
# Deploy metrics-server (if not installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create deployment
kubectl create deployment php-apache --image=k8s.gcr.io/hpa-example
kubectl set resources deployment php-apache --requests=cpu=200m

# Create HPA
kubectl autoscale deployment php-apache --cpu-percent=50 --min=2 --max=10

# Generate load
kubectl run -it load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

# Watch HPA
kubectl get hpa -w
```

### Challenge 8
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: probe-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: probe-demo
  template:
    metadata:
      labels:
        app: probe-demo
    spec:
      containers:
      - name: app
        image: nginx
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 3
        readinessProbe:
          tcpSocket:
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        startupProbe:
          httpGet:
            path: /
            port: 80
          failureThreshold: 30
          periodSeconds: 10
```
</details>
