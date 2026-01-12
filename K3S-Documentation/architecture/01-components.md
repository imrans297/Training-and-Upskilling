# K3S Architecture & Components

## Overview

K3S is a simplified Kubernetes distribution that packages all components into a single binary while maintaining full Kubernetes API compatibility.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    K3S Server Node                      │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐  │
│  │         K3S Server Process (Single Binary)       │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  • API Server                                    │  │
│  │  • Controller Manager                            │  │
│  │  • Scheduler                                     │  │
│  │  • Cloud Controller (optional)                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Datastore (SQLite or etcd)               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Agent Components                         │  │
│  │  • Kubelet                                       │  │
│  │  • Kube-proxy                                    │  │
│  │  • Containerd                                    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Built-in Add-ons                         │  │
│  │  • Traefik (Ingress)                            │  │
│  │  • ServiceLB (Load Balancer)                    │  │
│  │  • Local-path (Storage)                         │  │
│  │  • CoreDNS                                       │  │
│  │  • Metrics Server                                │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                    K3S Agent Node                       │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐  │
│  │         K3S Agent Process (Single Binary)        │  │
│  ├──────────────────────────────────────────────────┤  │
│  │  • Kubelet                                       │  │
│  │  • Kube-proxy                                    │  │
│  │  • Containerd                                    │  │
│  │  • Flannel (CNI)                                 │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. API Server
**Purpose**: Front-end for Kubernetes control plane

**Features**:
- RESTful API interface
- Authentication & authorization
- Admission control
- API validation

**K3S Specifics**:
- Embedded in single binary
- Listens on port 6443
- TLS enabled by default

**Configuration**:
```yaml
# /etc/rancher/k3s/config.yaml
kube-apiserver-arg:
  - "max-requests-inflight=400"
  - "max-mutating-requests-inflight=200"
  - "enable-admission-plugins=NodeRestriction,PodSecurityPolicy"
```

### 2. Controller Manager
**Purpose**: Runs controller processes

**Controllers**:
- Node controller
- Replication controller
- Endpoints controller
- Service account controller
- Namespace controller

**K3S Specifics**:
- Embedded in server binary
- Simplified configuration
- Auto-configured for single-node

### 3. Scheduler
**Purpose**: Assigns pods to nodes

**Factors**:
- Resource requirements
- Node affinity/anti-affinity
- Taints and tolerations
- Pod priority

**K3S Specifics**:
- Default scheduler policies
- Optimized for edge/IoT

### 4. Datastore

#### SQLite (Default)
**Advantages**:
- No external dependencies
- Simple setup
- Low resource usage
- Perfect for single-node

**Location**:
```
/var/lib/rancher/k3s/server/db/state.db
```

**Limitations**:
- Single-node only
- No HA support

#### Embedded etcd
**Advantages**:
- Multi-node support
- High availability
- Kubernetes standard

**Enable**:
```bash
curl -sfL https://get.k3s.io | sh -s - server --cluster-init
```

**Configuration**:
```yaml
cluster-init: true
etcd-snapshot-schedule-cron: "0 */12 * * *"
etcd-snapshot-retention: 5
```

#### External Datastore
**Supported**:
- MySQL
- PostgreSQL
- etcd (external)

**Example**:
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --datastore-endpoint="mysql://user:pass@tcp(host:3306)/k3s"
```

## Agent Components

### 1. Kubelet
**Purpose**: Node agent that runs pods

**Responsibilities**:
- Pod lifecycle management
- Container health checks
- Resource monitoring
- Volume management

**K3S Configuration**:
```yaml
kubelet-arg:
  - "max-pods=110"
  - "eviction-hard=memory.available<500Mi"
  - "image-gc-high-threshold=85"
  - "image-gc-low-threshold=80"
```

### 2. Kube-proxy
**Purpose**: Network proxy on each node

**Modes**:
- iptables (default)
- ipvs
- userspace

**K3S Configuration**:
```yaml
kube-proxy-arg:
  - "proxy-mode=iptables"
  - "metrics-bind-address=0.0.0.0:10249"
```

### 3. Containerd
**Purpose**: Container runtime

**Features**:
- OCI compliant
- Lightweight
- CRI compatible

**K3S Specifics**:
- Embedded in binary
- No Docker required
- Optimized for K3S

**Configuration**:
```toml
# /var/lib/rancher/k3s/agent/etc/containerd/config.toml
[plugins.cri.registry.mirrors]
  [plugins.cri.registry.mirrors."docker.io"]
    endpoint = ["https://registry-1.docker.io"]
```

## Built-in Add-ons

### 1. Traefik (Ingress Controller)

**Features**:
- HTTP/HTTPS routing
- TLS termination
- Load balancing
- Automatic service discovery

**Default Configuration**:
```yaml
# Deployed automatically
# Listens on ports 80/443
```

**Disable**:
```yaml
disable:
  - traefik
```

**Custom Configuration**:
```yaml
# /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ports:
      web:
        port: 8080
      websecure:
        port: 8443
```

### 2. ServiceLB (Klipper Load Balancer)

**Purpose**: Provides LoadBalancer service type

**How it works**:
- Creates DaemonSet on nodes
- Uses host ports
- Simple L4 load balancing

**Example**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

**Disable**:
```yaml
disable:
  - servicelb
```

### 3. Local-path Provisioner

**Purpose**: Dynamic volume provisioning

**Storage Class**:
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

**Default Path**:
```
/var/lib/rancher/k3s/storage/
```

**Usage**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```

### 4. CoreDNS

**Purpose**: Cluster DNS service

**Configuration**:
```yaml
# Corefile
.:53 {
    errors
    health
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
```

**Custom DNS**:
```yaml
# /var/lib/rancher/k3s/server/manifests/coredns-custom.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  example.server: |
    example.com:53 {
      forward . 1.1.1.1
    }
```

### 5. Metrics Server

**Purpose**: Resource metrics collection

**Usage**:
```bash
kubectl top nodes
kubectl top pods
```

**Disable**:
```yaml
disable:
  - metrics-server
```

## Networking

### CNI Plugin: Flannel

**Mode**: VXLAN (default)

**Configuration**:
```yaml
flannel-backend: vxlan  # or wireguard, host-gw
```

**Network Ranges**:
```yaml
cluster-cidr: "10.42.0.0/16"  # Pod network
service-cidr: "10.43.0.0/16"  # Service network
```

### Network Policies

**Enable Calico**:
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --flannel-backend=none \
  --disable-network-policy
  
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## Security Components

### 1. RBAC (Role-Based Access Control)

**Enabled by default**

**Example Role**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### 2. Pod Security Standards

**Configure**:
```yaml
kube-apiserver-arg:
  - "enable-admission-plugins=PodSecurity"
  - "admission-control-config-file=/etc/k3s/pss-config.yaml"
```

### 3. Network Policies

**Example**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 4. Secrets Encryption

**Enable**:
```yaml
secrets-encryption: true
```

## Resource Management

### Resource Limits

**Node Allocatable**:
```yaml
kubelet-arg:
  - "kube-reserved=cpu=200m,memory=512Mi"
  - "system-reserved=cpu=200m,memory=512Mi"
```

### Quality of Service (QoS)

**Classes**:
1. Guaranteed (requests = limits)
2. Burstable (requests < limits)
3. BestEffort (no requests/limits)

## Component Communication

```
┌─────────────┐
│   kubectl   │
└──────┬──────┘
       │ HTTPS (6443)
       ▼
┌─────────────┐
│ API Server  │
└──────┬──────┘
       │
   ┌───┴───┬────────┬──────────┐
   │       │        │          │
   ▼       ▼        ▼          ▼
┌────┐ ┌────┐ ┌─────────┐ ┌────────┐
│etcd│ │Sched│ │Ctrl Mgr │ │Kubelet │
└────┘ └────┘ └─────────┘ └────────┘
```

## Process Management

### Server Process
```bash
# Check process
ps aux | grep k3s

# Process tree
pstree -p $(pgrep k3s)
```

### Agent Process
```bash
# Check agent
ps aux | grep k3s-agent

# Resource usage
top -p $(pgrep k3s-agent)
```

## File System Layout

```
/var/lib/rancher/k3s/
├── agent/
│   ├── containerd/
│   ├── etc/
│   └── pod-manifests/
├── server/
│   ├── db/              # SQLite database
│   ├── manifests/       # Auto-deploy manifests
│   ├── tls/             # Certificates
│   └── static/          # Static pods
└── storage/             # Local-path volumes

/etc/rancher/k3s/
├── config.yaml          # K3S configuration
└── k3s.yaml             # Kubeconfig
```

## Performance Tuning

### Memory Optimization
```yaml
kubelet-arg:
  - "image-gc-high-threshold=85"
  - "image-gc-low-threshold=80"
  - "eviction-hard=memory.available<100Mi"
```

### CPU Optimization
```yaml
kube-apiserver-arg:
  - "max-requests-inflight=400"
kubelet-arg:
  - "cpu-manager-policy=static"
```

## Monitoring Components

### Metrics
```bash
# API server metrics
curl -k https://localhost:6443/metrics

# Kubelet metrics
curl http://localhost:10250/metrics

# Containerd metrics
curl http://localhost:1338/metrics
```

### Health Checks
```bash
# API server health
curl -k https://localhost:6443/healthz

# Kubelet health
curl http://localhost:10248/healthz
```

## Next Steps

- [Networking Deep Dive](02-networking.md)
- [Storage Configuration](03-storage.md)
- [Security Hardening](04-security.md)
