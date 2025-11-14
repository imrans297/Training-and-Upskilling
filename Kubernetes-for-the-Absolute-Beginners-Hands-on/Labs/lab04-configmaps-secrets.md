# Lab 4: ConfigMaps and Secrets

## Objective
Learn to manage configuration and sensitive data.

## Tasks

### Task 1: Create ConfigMap from Literals
```bash
# Create configmap
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_DEBUG=false \
  --from-literal=LOG_LEVEL=info

# Verify
kubectl get configmap app-config
kubectl describe configmap app-config
kubectl get configmap app-config -o yaml
```

### Task 2: Create ConfigMap from File
Create `app.properties`:
```properties
database.host=localhost
database.port=5432
database.name=myapp
```

```bash
# Create configmap from file
kubectl create configmap app-properties --from-file=app.properties

# Verify
kubectl describe configmap app-properties
```

### Task 3: Use ConfigMap as Environment Variables
Create `pod-with-configmap-env.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-env-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'echo "ENV: $APP_ENV, DEBUG: $APP_DEBUG" && sleep 3600']
    env:
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
    - name: APP_DEBUG
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_DEBUG
```

Apply and test:
```bash
kubectl apply -f pod-with-configmap-env.yaml
kubectl logs config-env-pod
kubectl exec config-env-pod -- env | grep APP_
```

### Task 4: Use ConfigMap as Volume
Create `pod-with-configmap-volume.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-volume-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'cat /config/app.properties && sleep 3600']
    volumeMounts:
    - name: config-volume
      mountPath: /config
  volumes:
  - name: config-volume
    configMap:
      name: app-properties
```

Apply and test:
```bash
kubectl apply -f pod-with-configmap-volume.yaml
kubectl logs config-volume-pod
kubectl exec config-volume-pod -- ls /config
kubectl exec config-volume-pod -- cat /config/app.properties
```

### Task 5: Create Secret from Literals
```bash
# Create secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpass123

# Verify
kubectl get secrets
kubectl describe secret db-secret
kubectl get secret db-secret -o yaml
```

### Task 6: Decode Secret
```bash
# Get base64 encoded value
kubectl get secret db-secret -o jsonpath='{.data.password}'

# Decode
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 --decode
```

### Task 7: Use Secret as Environment Variables
Create `pod-with-secret-env.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'echo "User: $DB_USER" && sleep 3600']
    env:
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASS
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

Apply and test:
```bash
kubectl apply -f pod-with-secret-env.yaml
kubectl exec secret-env-pod -- env | grep DB_USER
```

### Task 8: Use Secret as Volume
Create `pod-with-secret-volume.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-volume-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'cat /secrets/username && sleep 3600']
    volumeMounts:
    - name: secret-volume
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
```

Apply and test:
```bash
kubectl apply -f pod-with-secret-volume.yaml
kubectl exec secret-volume-pod -- ls /secrets
kubectl exec secret-volume-pod -- cat /secrets/username
```

### Task 9: Docker Registry Secret
```bash
# Create docker registry secret
kubectl create secret docker-registry my-registry-secret \
  --docker-server=docker.io \
  --docker-username=myuser \
  --docker-password=mypass \
  --docker-email=myemail@example.com

# Use in pod
```

Create `pod-with-registry-secret.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  containers:
  - name: app
    image: private-registry/myapp:latest
  imagePullSecrets:
  - name: my-registry-secret
```

## Cleanup
```bash
kubectl delete configmap app-config app-properties
kubectl delete secret db-secret my-registry-secret
kubectl delete pod config-env-pod config-volume-pod
kubectl delete pod secret-env-pod secret-volume-pod
```

## Verification
- [ ] Created ConfigMap from literals
- [ ] Created ConfigMap from file
- [ ] Used ConfigMap as environment variables
- [ ] Mounted ConfigMap as volume
- [ ] Created Secret
- [ ] Decoded Secret
- [ ] Used Secret as environment variables
- [ ] Mounted Secret as volume
