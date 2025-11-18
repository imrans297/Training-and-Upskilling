# Lab 1: EBS CSI Driver Setup and Basic Persistent Volumes

## What We're Achieving
Set up AWS EBS CSI driver and create persistent storage for stateful applications in EKS.

## What We're Doing
- Install and configure EBS CSI driver
- Create storage classes for different EBS volume types
- Deploy applications with persistent volumes
- Test data persistence across pod restarts

## Prerequisites
- Shared training cluster running
- EBS CSI driver installed (should be done in cluster setup)
- kubectl configured

## Lab Exercises

### Exercise 1: Verify EBS CSI Driver Installation
```bash
# Switch to storage namespace
kubectl config set-context --current --namespace=storage-ebs

# Check if EBS CSI driver is installed
kubectl get pods -n kube-system | grep ebs-csi

# Check CSI driver
kubectl get csidriver

# Check storage classes
kubectl get storageclass

# Describe default storage class
kubectl describe storageclass gp2

# If EBS CSI driver is not installed, install it
aws eks create-addon --cluster-name training-cluster --addon-name aws-ebs-csi-driver --region ap-south-1

# Wait for addon to be ready
aws eks describe-addon --cluster-name training-cluster --addon-name aws-ebs-csi-driver --region ap-south-1 --query 'addon.status' --output text

# If EBS CSI controller pods are crashing, create IAM service account
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster training-cluster \
  --region ap-south-1 \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts

# Restart EBS CSI controller to use new service account
kubectl rollout restart deployment ebs-csi-controller -n kube-system
kubectl rollout status deployment ebs-csi-controller -n kube-system --timeout=120s
```

### Exercise 2: Create Custom Storage Classes
```bash
# Create different storage classes for various use cases
cat > storage-classes.yaml << EOF
# GP3 Storage Class (recommended)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-fast
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# IO1 Storage Class (high IOPS)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: io1-high-iops
provisioner: ebs.csi.aws.com
parameters:
  type: io1
  iops: "1000"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
# GP2 Storage Class (standard)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp2-standard
provisioner: ebs.csi.aws.com
parameters:
  type: gp2
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# Apply storage classes
kubectl apply -f storage-classes.yaml

# Verify storage classes
kubectl get storageclass
```

### Exercise 3: Create Persistent Volume Claims
```bash
# Create PVCs with different storage classes
cat > persistent-volume-claims.yaml << EOF
# Small PVC for testing
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: small-pvc
  namespace: storage-ebs
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3-fast
  resources:
    requests:
      storage: 1Gi
---
# Medium PVC for applications
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: medium-pvc
  namespace: storage-ebs
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3-fast
  resources:
    requests:
      storage: 5Gi
---
# High IOPS PVC for databases
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
  namespace: storage-ebs
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: io1-high-iops
  resources:
    requests:
      storage: 10Gi
EOF

# Apply PVCs
kubectl apply -f persistent-volume-claims.yaml

# Check PVC status (should be Pending until bound to pods)
kubectl get pvc -n storage-ebs
```

### Exercise 4: Deploy Application with Persistent Storage
```bash
# Create application that uses persistent storage
cat > persistent-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-storage-app
  namespace: storage-ebs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: file-storage
  template:
    metadata:
      labels:
        app: file-storage
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: persistent-storage
          mountPath: /usr/share/nginx/html
        - name: logs-storage
          mountPath: /var/log/nginx
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                echo "<h1>Persistent Storage Demo</h1>" > /usr/share/nginx/html/index.html
                echo "<p>This content is stored on EBS volume</p>" >> /usr/share/nginx/html/index.html
                echo "<p>Pod: $HOSTNAME</p>" >> /usr/share/nginx/html/index.html
                echo "<p>Timestamp: $(date)</p>" >> /usr/share/nginx/html/index.html
      volumes:
      - name: persistent-storage
        persistentVolumeClaim:
          claimName: small-pvc
      - name: logs-storage
        persistentVolumeClaim:
          claimName: medium-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: file-storage-service
  namespace: storage-ebs
spec:
  selector:
    app: file-storage
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30082
  type: NodePort
EOF

# Deploy the application
kubectl apply -f persistent-app.yaml

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod -l app=file-storage -n storage-ebs --timeout=120s

# Check PVC status (should now be Bound)
kubectl get pvc -n storage-ebs

# Check persistent volumes
kubectl get pv
```

### Exercise 5: Test Data Persistence
```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=file-storage -n storage-ebs -o jsonpath='{.items[0].metadata.name}')

# Add some data to persistent volume
kubectl exec -it $POD_NAME -n storage-ebs -- sh -c "echo 'Additional data added at $(date)' >> /usr/share/nginx/html/data.txt"
kubectl exec -it $POD_NAME -n storage-ebs -- sh -c "ls -la /usr/share/nginx/html/"

# Test web access
kubectl exec -it $POD_NAME -n storage-ebs -- curl localhost

# Delete the pod to test persistence
kubectl delete pod $POD_NAME -n storage-ebs

# Wait for new pod to be created
kubectl wait --for=condition=Ready pod -l app=file-storage -n storage-ebs --timeout=120s

# Get new pod name
NEW_POD_NAME=$(kubectl get pods -l app=file-storage -n storage-ebs -o jsonpath='{.items[0].metadata.name}')

# Verify data persisted
kubectl exec -it $NEW_POD_NAME -n storage-ebs -- ls -la /usr/share/nginx/html/
kubectl exec -it $NEW_POD_NAME -n storage-ebs -- cat /usr/share/nginx/html/data.txt
kubectl exec -it $NEW_POD_NAME -n storage-ebs -- curl localhost
```

### Exercise 6: Volume Expansion
```bash
# Check current PVC size
kubectl get pvc small-pvc -n storage-ebs

# Expand the PVC (storage class must support expansion)
kubectl patch pvc small-pvc -n storage-ebs -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'

# Check expansion status
kubectl get pvc small-pvc -n storage-ebs -w

# Verify expansion in pod
kubectl exec -it $NEW_POD_NAME -n storage-ebs -- df -h /usr/share/nginx/html
```

### Exercise 7: Database with Persistent Storage
```bash
# Deploy MySQL with persistent storage
cat > mysql-persistent.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-persistent
  namespace: storage-ebs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-persistent
  template:
    metadata:
      labels:
        app: mysql-persistent
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        - name: MYSQL_DATABASE
          value: "testdb"
        - name: MYSQL_USER
          value: "testuser"
        - name: MYSQL_PASSWORD
          value: "testpass"
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: database-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: storage-ebs
spec:
  selector:
    app: mysql-persistent
  ports:
    - port: 3306
      targetPort: 3306
  type: ClusterIP
EOF

# Deploy MySQL
kubectl apply -f mysql-persistent.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=Ready pod -l app=mysql-persistent -n storage-ebs --timeout=180s

# Test database connection
MYSQL_POD=$(kubectl get pods -l app=mysql-persistent -n storage-ebs -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $MYSQL_POD -n storage-ebs -- mysql -u root -prootpassword -e "SHOW DATABASES;"

# Create test data
kubectl exec -it $MYSQL_POD -n storage-ebs -- mysql -u root -prootpassword testdb -e "CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(50)); INSERT INTO users VALUES (1, 'John Doe'), (2, 'Jane Smith');"

# Verify data
kubectl exec -it $MYSQL_POD -n storage-ebs -- mysql -u root -prootpassword testdb -e "SELECT * FROM users;"
```

## Cleanup
```bash
# Delete applications
kubectl delete -f persistent-app.yaml
kubectl delete -f mysql-persistent.yaml

# Delete PVCs (this will also delete the EBS volumes)
kubectl delete -f persistent-volume-claims.yaml

# Delete storage classes (optional)
kubectl delete -f storage-classes.yaml

# Clean up files
rm -f storage-classes.yaml persistent-volume-claims.yaml persistent-app.yaml mysql-persistent.yaml
```

## Key Takeaways
1. EBS CSI driver enables dynamic volume provisioning
2. Storage classes define volume characteristics (type, IOPS, encryption)
3. PVCs request storage resources from storage classes
4. Data persists across pod restarts and rescheduling
5. Volume expansion is supported for compatible storage classes
6. Different storage types serve different performance needs
7. Proper resource requests/limits are important for database workloads

## Next Steps
- Move to Lab 2: StatefulSets with Persistent Storage
- Practice with different EBS volume types
- Learn about volume snapshots and backup strategies