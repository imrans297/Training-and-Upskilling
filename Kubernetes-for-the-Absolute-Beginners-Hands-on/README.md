# Kubernetes for the Absolute Beginners - Hands-on

## 🎯 Course Purpose
Master Kubernetes from basics to advanced with hands-on labs, covering container orchestration, deployment strategies, and production-ready practices.

## 📚 What You'll Achieve
- Understand Kubernetes architecture and components
- Deploy and manage containerized applications
- Implement scaling, updates, and rollbacks
- Configure networking and storage
- Secure clusters with RBAC and policies
- Troubleshoot production issues
- Build multi-tier applications

---

## 📁 Directory Structure

### **Concepts/** - Theory and Architecture
**Purpose:** Understand Kubernetes fundamentals and design principles

- `00-kubernetes-architecture.md` - Complete architecture with diagrams
- `01-kubernetes-basics.md` - Core concepts and components
- `02-pods.md` - Pod lifecycle and patterns
- `03-replicasets.md` - High availability and scaling
- `04-deployments.md` - Deployment strategies
- `05-services.md` - Service types and networking
- `06-namespaces.md` - Resource isolation
- `07-configmaps-secrets.md` - Configuration management
- `08-volumes-storage.md` - Persistent storage
- `09-advanced-concepts.md` - StatefulSets, Jobs, Ingress, HPA

### **Commands/** - Complete Command Reference
**Purpose:** Quick reference for all kubectl operations

- `01-basic-commands.md` - Cluster info, config, help
- `02-pod-commands.md` - Pod lifecycle management
- `03-deployment-commands.md` - Deployment operations
- `04-service-commands.md` - Service exposure
- `05-namespace-commands.md` - Namespace management
- `06-configmap-secret-commands.md` - Config and secrets
- `07-advanced-commands.md` - StatefulSets, Jobs, RBAC
- `08-troubleshooting-commands.md` - Debug and diagnose

### **Labs/** - Hands-on Practice
**Purpose:** Step-by-step guided exercises with verification

- `lab01-pods.md` - Create and manage pods
- `lab02-deployments.md` - Deploy and scale applications
- `lab03-services.md` - Expose applications
- `lab04-configmaps-secrets.md` - Manage configuration
- `lab05-volumes-storage.md` - Persistent storage
- `lab06-namespaces.md` - Resource organization
- `lab07-advanced-workloads.md` - StatefulSets, Jobs, CronJobs

### **Exercises/** - Challenge Yourself
**Purpose:** Test your skills with real-world scenarios

- `exercise01-basic.md` - Basic operations challenges
- `exercise02-intermediate.md` - Multi-tier applications
- `exercise03-advanced.md` - Production scenarios
- `final-project.md` - Complete application deployment

### **YAML-Files/** - Ready-to-Use Templates
**Purpose:** Example manifests for quick deployment

- `sample-pod.yaml` - Basic pod
- `sample-deployment.yaml` - Deployment with replicas
- `sample-service.yaml` - Service exposure
- `configmap-examples.yaml` - Configuration examples
- `secret-examples.yaml` - Secret management
- `storage-examples.yaml` - PV, PVC, StorageClass
- `namespace-examples.yaml` - Namespace, quotas, limits
- `advanced-examples.yaml` - StatefulSet, DaemonSet, Jobs

### **Notes/** - Reference Guides
**Purpose:** Quick guides and best practices

- `getting-started.md` - Kubernetes introduction
- `kubectl-cheatsheet.md` - Quick command reference
- `best-practices.md` - Production guidelines
- `common-errors.md` - Troubleshooting guide

---

## 🎓 Learning Path

### **Beginner Level (Week 1-2)**
**Goal:** Understand basics and deploy simple applications

1. Read: `Concepts/00-kubernetes-architecture.md`
2. Read: `Concepts/01-kubernetes-basics.md`
3. Practice: `Commands/01-basic-commands.md`
4. Lab: `Labs/lab01-pods.md`
5. Read: `Concepts/02-pods.md`
6. Practice: `Commands/02-pod-commands.md`
7. Read: `Concepts/04-deployments.md`
8. Lab: `Labs/lab02-deployments.md`
9. Exercise: `Exercises/exercise01-basic.md`

### **Intermediate Level (Week 3-4)**
**Goal:** Master services, configuration, and storage

1. Read: `Concepts/05-services.md`
2. Lab: `Labs/lab03-services.md`
3. Read: `Concepts/07-configmaps-secrets.md`
4. Lab: `Labs/lab04-configmaps-secrets.md`
5. Read: `Concepts/08-volumes-storage.md`
6. Lab: `Labs/lab05-volumes-storage.md`
7. Read: `Concepts/06-namespaces.md`
8. Lab: `Labs/lab06-namespaces.md`
9. Exercise: `Exercises/exercise02-intermediate.md`

### **Advanced Level (Week 5-6)**
**Goal:** Production-ready deployments and troubleshooting

1. Read: `Concepts/09-advanced-concepts.md`
2. Lab: `Labs/lab07-advanced-workloads.md`
3. Practice: `Commands/07-advanced-commands.md`
4. Study: `Notes/best-practices.md`
5. Study: `Notes/common-errors.md`
6. Practice: `Commands/08-troubleshooting-commands.md`
7. Exercise: `Exercises/exercise03-advanced.md`
8. Project: `Exercises/final-project.md`

---

## 📊 Progress Tracker

### Core Concepts
- [ ] Kubernetes architecture
- [ ] Pods and containers
- [ ] ReplicaSets
- [ ] Deployments
- [ ] Services
- [ ] Namespaces
- [ ] ConfigMaps & Secrets
- [ ] Volumes & Storage
- [ ] Advanced workloads

### Hands-on Labs
- [ ] Lab 1: Pods
- [ ] Lab 2: Deployments
- [ ] Lab 3: Services
- [ ] Lab 4: ConfigMaps & Secrets
- [ ] Lab 5: Volumes & Storage
- [ ] Lab 6: Namespaces
- [ ] Lab 7: Advanced Workloads

### Exercises
- [ ] Exercise 1: Basic Operations
- [ ] Exercise 2: Intermediate Operations
- [ ] Exercise 3: Advanced Operations
- [ ] Final Project: Multi-Tier Application

### Skills Mastered
- [ ] kubectl command proficiency
- [ ] YAML manifest creation
- [ ] Application deployment
- [ ] Scaling and updates
- [ ] Troubleshooting
- [ ] Security best practices
- [ ] Production readiness

---

## 🚀 Quick Start

### Prerequisites
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

# Setup cluster (Minikube for local)
minikube start
```

### First Steps
```bash
# Check cluster
kubectl cluster-info
kubectl get nodes

# Create first pod
kubectl run nginx --image=nginx

# Verify
kubectl get pods
kubectl describe pod nginx

# Access pod
kubectl port-forward nginx 8080:80
# Visit: http://localhost:8080
```

---

## 📖 Essential Commands Reference

### Cluster Operations
```bash
kubectl cluster-info              # Cluster information
kubectl get nodes                 # List nodes
kubectl get all                   # All resources
```

### Pod Operations
```bash
kubectl get pods                  # List pods
kubectl describe pod <name>       # Pod details
kubectl logs <pod-name>           # View logs
kubectl exec -it <pod> -- /bin/bash  # Shell access
```

### Deployment Operations
```bash
kubectl create deployment <name> --image=<image>  # Create
kubectl scale deployment <name> --replicas=3      # Scale
kubectl set image deployment/<name> <container>=<image>  # Update
kubectl rollout undo deployment/<name>            # Rollback
```

### Service Operations
```bash
kubectl expose deployment <name> --port=80        # Expose
kubectl get services                              # List services
kubectl describe service <name>                   # Service details
```

---

## 🎯 Learning Objectives by Section

### Architecture (Concepts/00)
- Understand control plane components
- Learn worker node architecture
- Master communication flow

### Pods (Concepts/02, Labs/01)
- Create and manage pods
- Multi-container patterns
- Pod lifecycle management

### Deployments (Concepts/04, Labs/02)
- Deploy applications with replicas
- Perform rolling updates
- Implement rollback strategies

### Services (Concepts/05, Labs/03)
- Expose applications internally/externally
- Understand service types
- Implement load balancing

### Configuration (Concepts/07, Labs/04)
- Externalize configuration
- Manage secrets securely
- Inject config into pods

### Storage (Concepts/08, Labs/05)
- Implement persistent storage
- Use PV and PVC
- Understand storage classes

### Advanced (Concepts/09, Labs/07)
- Deploy stateful applications
- Schedule jobs and cron jobs
- Implement autoscaling

---

## 🛠️ Troubleshooting Resources

### Common Issues
- **ImagePullBackOff** → Check image name and registry credentials
- **CrashLoopBackOff** → Check logs: `kubectl logs <pod> --previous`
- **Pending Pods** → Check resources: `kubectl describe pod <pod>`
- **Service Not Accessible** → Check endpoints: `kubectl get endpoints`

### Debug Commands
```bash
kubectl get events                # Cluster events
kubectl describe pod <pod>        # Pod details
kubectl logs <pod> -f             # Follow logs
kubectl exec -it <pod> -- /bin/sh # Shell access
kubectl top nodes                 # Resource usage
```

---

## 📚 Additional Resources

### Official Documentation
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)

### Practice Environments
- [Minikube](https://minikube.sigs.k8s.io/) - Local cluster
- [Kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
- [Play with Kubernetes](https://labs.play-with-k8s.com/) - Online playground

---

## ✅ Completion Checklist

- [ ] Completed all 9 concept modules
- [ ] Finished all 7 hands-on labs
- [ ] Solved all 3 exercises
- [ ] Completed final project
- [ ] Can deploy multi-tier applications
- [ ] Can troubleshoot common issues
- [ ] Understand security best practices
- [ ] Ready for production deployments

---

**Happy Learning! 🚀**
