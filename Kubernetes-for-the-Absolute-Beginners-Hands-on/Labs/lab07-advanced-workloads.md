# Lab 7: Advanced Workloads

## Objective
Learn StatefulSets, DaemonSets, Jobs, and CronJobs.

## Tasks

### Task 1: StatefulSet
Create `statefulset.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
spec:
  clusterIP: None
  selector:
    app: nginx-sts
  ports:
  - port: 80
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-sts
spec:
  serviceName: nginx-headless
  replicas: 3
  selector:
    matchLabels:
      app: nginx-sts
  template:
    metadata:
      labels:
        app: nginx-sts
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

Apply and test:
```bash
kubectl apply -f statefulset.yaml
kubectl get statefulset
kubectl get pods -l app=nginx-sts

# Check ordered creation
kubectl get pods -w

# Check DNS
kubectl run test --image=busybox -it --rm -- nslookup web-sts-0.nginx-headless
```

### Task 2: Scale StatefulSet
```bash
# Scale up
kubectl scale statefulset web-sts --replicas=5
kubectl get pods -l app=nginx-sts -w

# Scale down
kubectl scale statefulset web-sts --replicas=2
kubectl get pods -l app=nginx-sts -w
```

### Task 3: DaemonSet
Create `daemonset.yaml`:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      containers:
      - name: node-exporter
        image: prom/node-exporter
        ports:
        - containerPort: 9100
```

Apply:
```bash
kubectl apply -f daemonset.yaml
kubectl get daemonset
kubectl get pods -l app=node-exporter -o wide

# One pod per node
kubectl get nodes
```

### Task 4: Job
Create `job.yaml`:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-job
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

Apply and test:
```bash
kubectl apply -f job.yaml
kubectl get jobs
kubectl get pods

# Wait for completion
kubectl wait --for=condition=complete job/pi-job

# View logs
kubectl logs job/pi-job
```

### Task 5: Parallel Job
Create `parallel-job.yaml`:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-job
spec:
  parallelism: 3
  completions: 6
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ['sh', '-c', 'echo "Processing..." && sleep 10']
      restartPolicy: Never
```

Apply:
```bash
kubectl apply -f parallel-job.yaml
kubectl get jobs
kubectl get pods -w
```

### Task 6: CronJob
Create `cronjob.yaml`:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "*/2 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            command: ['sh', '-c', 'date; echo "Hello from CronJob"']
          restartPolicy: OnFailure
```

Apply and test:
```bash
kubectl apply -f cronjob.yaml
kubectl get cronjobs
kubectl get cronjob hello-cron

# Wait and check jobs created
sleep 130
kubectl get jobs

# View logs
kubectl logs job/hello-cron-<timestamp>
```

### Task 7: Suspend CronJob
```bash
# Suspend
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":true}}'

# Verify
kubectl get cronjob hello-cron

# Resume
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":false}}'
```

### Task 8: Manual CronJob Trigger
```bash
# Create job from cronjob
kubectl create job manual-job --from=cronjob/hello-cron

# Check
kubectl get jobs
kubectl logs job/manual-job
```

## Cleanup
```bash
kubectl delete statefulset web-sts
kubectl delete service nginx-headless
kubectl delete daemonset node-exporter
kubectl delete job pi-job parallel-job manual-job
kubectl delete cronjob hello-cron
```

## Verification
- [ ] Created StatefulSet with ordered pods
- [ ] Scaled StatefulSet
- [ ] Created DaemonSet on all nodes
- [ ] Created and completed Job
- [ ] Created parallel Job
- [ ] Created CronJob with schedule
- [ ] Suspended and resumed CronJob
- [ ] Manually triggered CronJob
