# Exercise 1: Basic Kubernetes Operations

## Challenge 1: Pod Management
1. Create a pod named `web-server` using `httpd:2.4` image
2. Verify the pod is running
3. Get the pod's IP address
4. Execute command inside pod to check Apache version
5. View pod logs
6. Delete the pod

## Challenge 2: Labels and Selectors
1. Create 3 pods with labels:
   - Pod 1: `app=frontend`, `env=dev`
   - Pod 2: `app=backend`, `env=dev`
   - Pod 3: `app=frontend`, `env=prod`
2. List all pods with label `app=frontend`
3. List all pods with label `env=dev`
4. List all pods with both `app=frontend` and `env=prod`

## Challenge 3: Multi-Container Pod
1. Create a pod with two containers:
   - Container 1: nginx
   - Container 2: busybox (running: `while true; do date; sleep 5; done`)
2. View logs from both containers
3. Execute command in busybox container

## Challenge 4: Deployment Operations
1. Create deployment `app-deploy` with 4 replicas using `nginx:1.19`
2. Scale to 6 replicas
3. Update image to `nginx:1.20`
4. Check rollout status
5. Rollback to previous version
6. Delete deployment

## Challenge 5: Service Exposure
1. Create deployment `backend-app` with 3 replicas
2. Expose as ClusterIP service on port 80
3. Create a test pod and access the service
4. Change service type to NodePort
5. Access service via NodePort

## Solutions
<details>
<summary>Click to reveal solutions</summary>

### Challenge 1
```bash
kubectl run web-server --image=httpd:2.4
kubectl get pods
kubectl get pod web-server -o wide
kubectl exec web-server -- httpd -v
kubectl logs web-server
kubectl delete pod web-server
```

### Challenge 2
```bash
kubectl run pod1 --image=nginx --labels="app=frontend,env=dev"
kubectl run pod2 --image=nginx --labels="app=backend,env=dev"
kubectl run pod3 --image=nginx --labels="app=frontend,env=prod"
kubectl get pods -l app=frontend
kubectl get pods -l env=dev
kubectl get pods -l app=frontend,env=prod
```

### Challenge 3
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-pod
spec:
  containers:
  - name: nginx
    image: nginx
  - name: busybox
    image: busybox
    command: ['sh', '-c', 'while true; do date; sleep 5; done']
```
```bash
kubectl apply -f multi-pod.yaml
kubectl logs multi-pod -c nginx
kubectl logs multi-pod -c busybox
kubectl exec multi-pod -c busybox -- date
```

### Challenge 4
```bash
kubectl create deployment app-deploy --image=nginx:1.19 --replicas=4
kubectl scale deployment app-deploy --replicas=6
kubectl set image deployment/app-deploy nginx=nginx:1.20
kubectl rollout status deployment/app-deploy
kubectl rollout undo deployment/app-deploy
kubectl delete deployment app-deploy
```

### Challenge 5
```bash
kubectl create deployment backend-app --image=nginx --replicas=3
kubectl expose deployment backend-app --port=80
kubectl run test --image=busybox -it --rm -- wget -O- backend-app
kubectl patch svc backend-app -p '{"spec":{"type":"NodePort"}}'
kubectl get svc backend-app
```
</details>
