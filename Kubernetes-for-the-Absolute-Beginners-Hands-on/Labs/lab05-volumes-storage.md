# Lab 5: Volumes and Storage

## Objective
Learn to work with volumes, persistent volumes, and persistent volume claims.

## Tasks

### Task 1: EmptyDir Volume
Create `emptydir-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ['sh', '-c', 'echo "Hello from writer" > /data/message.txt && sleep 3600']
    volumeMounts:
    - name: shared-data
      mountPath: /data
  - name: reader
    image: busybox
    command: ['sh', '-c', 'sleep 10 && cat /data/message.txt && sleep 3600']
    volumeMounts:
    - name: shared-data
      mountPath: /data
  volumes:
  - name: shared-data
    emptyDir: {}
```

Apply and test:
```bash
kubectl apply -f emptydir-pod.yaml
kubectl logs emptydir-pod -c reader
kubectl exec emptydir-pod -c reader -- cat /data/message.txt
```

### Task 2: HostPath Volume
Create `hostpath-pod.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'echo "Data on host" > /host-data/file.txt && sleep 3600']
    volumeMounts:
    - name: host-volume
      mountPath: /host-data
  volumes:
  - name: host-volume
    hostPath:
      path: /tmp/k8s-data
      type: DirectoryOrCreate
```

Apply and test:
```bash
kubectl apply -f hostpath-pod.yaml
kubectl exec hostpath-pod -- cat /host-data/file.txt

# On node (if accessible)
# cat /tmp/k8s-data/file.txt
```

### Task 3: Create PersistentVolume
Create `pv.yaml`:
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data
```

Apply:
```bash
kubectl apply -f pv.yaml
kubectl get pv
kubectl describe pv my-pv
```

### Task 4: Create PersistentVolumeClaim
Create `pvc.yaml`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

Apply:
```bash
kubectl apply -f pvc.yaml
kubectl get pvc
kubectl describe pvc my-pvc
kubectl get pv
```

### Task 5: Use PVC in Pod
Create `pod-with-pvc.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

Apply and test:
```bash
kubectl apply -f pod-with-pvc.yaml
kubectl exec pvc-pod -- sh -c 'echo "Hello from PVC" > /usr/share/nginx/html/index.html'
kubectl exec pvc-pod -- cat /usr/share/nginx/html/index.html
```

### Task 6: StorageClass (Dynamic Provisioning)
Create `storageclass.yaml`:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

Apply:
```bash
kubectl apply -f storageclass.yaml
kubectl get storageclass
```

### Task 7: PVC with StorageClass
Create `pvc-with-sc.yaml`:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 1Gi
```

Apply:
```bash
kubectl apply -f pvc-with-sc.yaml
kubectl get pvc dynamic-pvc
```

### Task 8: Multi-Pod Volume Sharing
Create `shared-volume-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-volume-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: shared-app
  template:
    metadata:
      labels:
        app: shared-app
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: shared-storage
          mountPath: /usr/share/nginx/html
      volumes:
      - name: shared-storage
        persistentVolumeClaim:
          claimName: my-pvc
```

Apply:
```bash
kubectl apply -f shared-volume-deployment.yaml
kubectl get pods -l app=shared-app
```

## Cleanup
```bash
kubectl delete pod emptydir-pod hostpath-pod pvc-pod
kubectl delete deployment shared-volume-deploy
kubectl delete pvc my-pvc dynamic-pvc
kubectl delete pv my-pv
kubectl delete storageclass fast-storage
```

## Verification
- [ ] Created emptyDir volume
- [ ] Created hostPath volume
- [ ] Created PersistentVolume
- [ ] Created PersistentVolumeClaim
- [ ] Used PVC in pod
- [ ] Created StorageClass
- [ ] Shared volume between pods
