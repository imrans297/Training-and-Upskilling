# Exercise 2: Intermediate Kubernetes Operations

## Challenge 1: ConfigMap and Secret Integration
1. Create ConfigMap with database configuration:
   - `DB_HOST=mysql.example.com`
   - `DB_PORT=3306`
   - `DB_NAME=myapp`
2. Create Secret with credentials:
   - `username=admin`
   - `password=secretpass`
3. Create deployment that uses both ConfigMap and Secret
4. Verify environment variables in pod

## Challenge 2: Namespace Management
1. Create namespace `development`
2. Create deployment in `development` namespace
3. Create service in `development` namespace
4. Set `development` as default namespace
5. Create resource quota limiting pods to 5
6. Test quota by creating 6 pods

## Challenge 3: Storage Management
1. Create PersistentVolume with 2Gi capacity
2. Create PersistentVolumeClaim requesting 1Gi
3. Create pod using the PVC
4. Write data to mounted volume
5. Delete pod and create new pod with same PVC
6. Verify data persists

## Challenge 4: Rolling Update Strategy
1. Create deployment with 5 replicas
2. Configure rolling update strategy:
   - maxSurge: 2
   - maxUnavailable: 1
3. Update deployment image
4. Monitor rolling update process
5. Pause rollout midway
6. Resume and complete rollout

## Challenge 5: Multi-Tier Application
1. Create MySQL deployment with:
   - PersistentVolume for data
   - Secret for root password
   - ClusterIP service
2. Create WordPress deployment with:
   - ConfigMap for MySQL host
   - Secret for MySQL password
   - NodePort service
3. Verify WordPress can connect to MySQL

## Solutions
<details>
<summary>Click to reveal solutions</summary>

### Challenge 1
```bash
kubectl create configmap db-config \
  --from-literal=DB_HOST=mysql.example.com \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=myapp

kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password=secretpass
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-config
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c', 'env && sleep 3600']
        envFrom:
        - configMapRef:
            name: db-config
        - secretRef:
            name: db-creds
```

### Challenge 2
```bash
kubectl create namespace development
kubectl create deployment app --image=nginx -n development --replicas=3
kubectl expose deployment app --port=80 -n development
kubectl config set-context --current --namespace=development
kubectl create quota dev-quota --hard=pods=5 -n development
kubectl create deployment test --image=nginx --replicas=6 -n development
```

### Challenge 3
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'echo "Data" > /data/file.txt && sleep 3600']
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

### Challenge 4
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-deploy
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  selector:
    matchLabels:
      app: rolling-app
  template:
    metadata:
      labels:
        app: rolling-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
```
```bash
kubectl apply -f rolling-deploy.yaml
kubectl set image deployment/rolling-deploy nginx=nginx:1.20
kubectl rollout status deployment/rolling-deploy -w
kubectl rollout pause deployment/rolling-deploy
kubectl rollout resume deployment/rolling-deploy
```
</details>
