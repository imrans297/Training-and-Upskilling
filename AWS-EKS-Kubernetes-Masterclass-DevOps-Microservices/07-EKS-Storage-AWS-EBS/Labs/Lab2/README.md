# Lab 2: StatefulSets and Advanced Storage Patterns

## What We're Achieving
Master StatefulSets with persistent storage for stateful applications like databases, and implement advanced storage patterns.

## What We're Doing
- Deploy StatefulSets with persistent volumes
- Implement ordered deployment and scaling
- Configure volume templates and storage classes
- Set up database clusters with persistent storage

## Prerequisites
- Completed Lab 1 (EBS CSI Driver Setup)
- EBS CSI driver installed
- Understanding of StatefulSets

## Lab Exercises

### Exercise 1: Basic StatefulSet with Persistent Storage
```bash
# Switch to storage namespace
kubectl config set-context --current --namespace=storage-ebs

# Create StatefulSet with persistent volumes
cat > basic-statefulset.yaml << EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-statefulset
  namespace: storage-ebs
spec:
  serviceName: web-service
  replicas: 3
  selector:
    matchLabels:
      app: web-statefulset
  template:
    metadata:
      labels:
        app: web-statefulset
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-storage
          mountPath: /usr/share/nginx/html
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                echo "<h1>Pod: \$HOSTNAME</h1>" > /usr/share/nginx/html/index.html
                echo "<p>Persistent storage mounted</p>" >> /usr/share/nginx/html/index.html
                echo "<p>Created: \$(date)</p>" >> /usr/share/nginx/html/index.html
  volumeClaimTemplates:
  - metadata:
      name: web-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3-fast
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: storage-ebs
spec:
  clusterIP: None
  selector:
    app: web-statefulset
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl apply -f basic-statefulset.yaml

# Watch StatefulSet deployment (ordered creation)
kubectl get pods -l app=web-statefulset -w

# Check persistent volumes
kubectl get pvc -n storage-ebs
kubectl get pv
```

### Exercise 2: MySQL Cluster with StatefulSet
```bash
# Create MySQL cluster StatefulSet
cat > mysql-cluster.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
  namespace: storage-ebs
data:
  master.cnf: |
    [mysqld]
    log-bin=mysql-bin
    server-id=1
    binlog-format=ROW
    gtid-mode=ON
    enforce-gtid-consistency=ON
  slave.cnf: |
    [mysqld]
    super-read-only
    server-id=2
    relay-log=mysql-relay-bin
    log-slave-updates=ON
    read-only=ON
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
  namespace: storage-ebs
type: Opaque
data:
  mysql-root-password: cm9vdHBhc3N3b3Jk  # rootpassword
  mysql-password: dXNlcnBhc3N3b3Jk      # userpassword
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-cluster
  namespace: storage-ebs
spec:
  serviceName: mysql-cluster-service
  replicas: 3
  selector:
    matchLabels:
      app: mysql-cluster
  template:
    metadata:
      labels:
        app: mysql-cluster
    spec:
      initContainers:
      - name: init-mysql
        image: mysql:8.0
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Generate server-id based on pod ordinal
          [[ \$HOSTNAME =~ -([0-9]+)\$ ]] || exit 1
          ordinal=\${BASH_REMATCH[1]}
          echo [mysqld] > /mnt/conf.d/server-id.cnf
          echo server-id=\$((100 + \$ordinal)) >> /mnt/conf.d/server-id.cnf
          
          # Copy appropriate conf.d files from config-map to emptyDir
          if [[ \$ordinal -eq 0 ]]; then
            cp /mnt/config-map/master.cnf /mnt/conf.d/
          else
            cp /mnt/config-map/slave.cnf /mnt/conf.d/
          fi
        volumeMounts:
        - name: conf
          mountPath: /mnt/conf.d
        - name: config-map
          mountPath: /mnt/config-map
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          value: "testdb"
        - name: MYSQL_USER
          value: "testuser"
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
        - name: conf
          mountPath: /etc/mysql/conf.d
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping"]
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command: ["mysql", "-h", "127.0.0.1", "-e", "SELECT 1"]
          initialDelaySeconds: 5
          periodSeconds: 2
          timeoutSeconds: 1
      volumes:
      - name: conf
        emptyDir: {}
      - name: config-map
        configMap:
          name: mysql-config
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3-fast
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-cluster-service
  namespace: storage-ebs
spec:
  clusterIP: None
  selector:
    app: mysql-cluster
  ports:
    - port: 3306
      targetPort: 3306
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-read-service
  namespace: storage-ebs
spec:
  selector:
    app: mysql-cluster
  ports:
    - port: 3306
      targetPort: 3306
EOF

kubectl apply -f mysql-cluster.yaml

# Wait for MySQL cluster to be ready
kubectl wait --for=condition=Ready pod/mysql-cluster-0 -n storage-ebs --timeout=300s

# Test MySQL cluster
kubectl exec mysql-cluster-0 -n storage-ebs -- mysql -u root -prootpassword -e "SHOW DATABASES;"
```

### Exercise 3: Ordered Scaling and Updates
```bash
# Scale StatefulSet up
kubectl scale statefulset web-statefulset --replicas=5 -n storage-ebs

# Watch ordered scaling
kubectl get pods -l app=web-statefulset -w

# Perform rolling update
kubectl patch statefulset web-statefulset -n storage-ebs -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.21-alpine"}]}}}}'

# Monitor rolling update (ordered)
kubectl rollout status statefulset/web-statefulset -n storage-ebs

# Scale down (reverse order)
kubectl scale statefulset web-statefulset --replicas=2 -n storage-ebs
```

### Exercise 4: Volume Snapshots and Backup
```bash
# Create VolumeSnapshotClass
cat > volume-snapshot-class.yaml << EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ebs-snapshot-class
driver: ebs.csi.aws.com
deletionPolicy: Delete
EOF

kubectl apply -f volume-snapshot-class.yaml

# Create snapshot of MySQL data
cat > mysql-snapshot.yaml << EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: mysql-snapshot-1
  namespace: storage-ebs
spec:
  volumeSnapshotClassName: ebs-snapshot-class
  source:
    persistentVolumeClaimName: mysql-data-mysql-cluster-0
EOF

kubectl apply -f mysql-snapshot.yaml

# Check snapshot status
kubectl get volumesnapshot -n storage-ebs
kubectl describe volumesnapshot mysql-snapshot-1 -n storage-ebs
```

### Exercise 5: Storage Monitoring and Metrics
```bash
# Create storage monitoring pod
cat > storage-monitor.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-monitor
  namespace: storage-ebs
spec:
  containers:
  - name: monitor
    image: busybox
    command: ["/bin/sh"]
    args:
    - -c
    - |
      while true; do
        echo "=== Storage Monitoring Report ==="
        echo "Timestamp: \$(date)"
        echo "Disk Usage:"
        df -h /data
        echo "Inode Usage:"
        df -i /data
        echo "File Count:"
        find /data -type f | wc -l
        echo "=========================="
        sleep 60
      done
    volumeMounts:
    - name: monitor-storage
      mountPath: /data
  volumes:
  - name: monitor-storage
    persistentVolumeClaim:
      claimName: web-storage-web-statefulset-0
EOF

kubectl apply -f storage-monitor.yaml

# Check storage metrics
kubectl logs storage-monitor -n storage-ebs
```

## Cleanup
```bash
# Delete StatefulSets (this will delete pods but keep PVCs)
kubectl delete statefulset web-statefulset mysql-cluster -n storage-ebs

# Delete services
kubectl delete service web-service mysql-cluster-service mysql-read-service -n storage-ebs

# Delete snapshots
kubectl delete volumesnapshot mysql-snapshot-1 -n storage-ebs
kubectl delete volumesnapshotclass ebs-snapshot-class

# Delete PVCs (this will delete the EBS volumes)
kubectl delete pvc --all -n storage-ebs

# Delete other resources
kubectl delete configmap mysql-config -n storage-ebs
kubectl delete secret mysql-secret -n storage-ebs
kubectl delete pod storage-monitor -n storage-ebs

# Clean up files
rm -f basic-statefulset.yaml mysql-cluster.yaml volume-snapshot-class.yaml mysql-snapshot.yaml storage-monitor.yaml
```

## Key Takeaways
1. StatefulSets provide ordered deployment and unique identities
2. Volume claim templates create individual PVCs for each pod
3. Headless services enable direct pod-to-pod communication
4. Ordered scaling ensures proper startup/shutdown sequences
5. Volume snapshots enable backup and restore capabilities
6. StatefulSets are ideal for databases and stateful applications
7. Persistent storage survives pod restarts and rescheduling

## Next Steps
- Move to Lab 3: Advanced Storage Features and Performance
- Practice with different database systems
- Learn about storage performance optimization