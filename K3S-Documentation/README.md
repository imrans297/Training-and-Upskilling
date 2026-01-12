# K3S - Lightweight Kubernetes Documentation

## What is K3S?

K3S is a lightweight, certified Kubernetes distribution designed for production workloads in resource-constrained environments, edge computing, IoT devices, and development environments.

## Key Features

- **Lightweight**: Single binary < 100MB
- **Simple**: Easy installation and management
- **Secure**: Secure by default with minimal attack surface
- **Production Ready**: CNCF certified Kubernetes distribution
- **Low Resource**: Runs on 512MB RAM minimum
- **Fast**: Quick startup and deployment

## K3S vs K8S Comparison

| Feature | K3S | K8S (Full) |
|---------|-----|------------|
| Binary Size | ~70MB | ~1GB+ |
| Memory | 512MB min | 2GB+ min |
| Installation | Single command | Complex setup |
| Components | Simplified | Full suite |
| Use Case | Edge, IoT, Dev | Enterprise, Production |
| Startup Time | Seconds | Minutes |

## Architecture Differences

### What K3S Removes:
- Legacy, alpha, non-default features
- In-tree cloud providers
- In-tree storage drivers
- Docker (uses containerd)

### What K3S Adds:
- SQLite as default datastore (instead of etcd)
- Traefik as default ingress controller
- ServiceLB as default load balancer
- Local-path-provisioner for storage
- Embedded network policy controller

## Documentation Structure

```
K3S-Documentation/
├── README.md (this file)
├── installation/
│   ├── 01-single-node-setup.md
│   ├── 02-multi-node-cluster.md
│   ├── 03-ha-setup.md
│   └── 04-uninstall.md
├── architecture/
│   ├── 01-components.md
│   ├── 02-networking.md
│   ├── 03-storage.md
│   └── 04-security.md
├── hands-on-labs/
│   ├── lab1-basic-deployment.md
│   ├── lab2-ingress-setup.md
│   ├── lab3-persistent-storage.md
│   └── lab4-monitoring.md
└── troubleshooting/
    ├── common-issues.md
    └── debugging-guide.md
```

## Quick Start

### Single Node Installation
```bash
curl -sfL https://get.k3s.io | sh -
```

### Verify Installation
```bash
sudo k3s kubectl get nodes
```

### Access Cluster
```bash
sudo k3s kubectl get pods -A
```

## Use Cases

### 1. Edge Computing
- IoT devices
- Remote locations
- Limited connectivity

### 2. Development
- Local Kubernetes testing
- CI/CD pipelines
- Learning Kubernetes

### 3. ARM Devices
- Raspberry Pi clusters
- ARM-based servers
- Mobile edge computing

### 4. Production (Small Scale)
- Microservices
- Small applications
- Resource-constrained environments

## System Requirements

### Minimum
- CPU: 1 core
- RAM: 512MB
- Disk: 1GB

### Recommended
- CPU: 2 cores
- RAM: 2GB
- Disk: 10GB

### Supported OS
- Ubuntu 18.04+
- Debian 10+
- RHEL/CentOS 7.8+
- Raspbian Buster+

## Key Components

### Server Components
- **API Server**: Kubernetes API
- **Controller Manager**: Cluster control loops
- **Scheduler**: Pod scheduling
- **SQLite/etcd**: Datastore
- **Containerd**: Container runtime

### Agent Components
- **Kubelet**: Node agent
- **Kube-proxy**: Network proxy
- **Containerd**: Container runtime

### Built-in Add-ons
- **Traefik**: Ingress controller
- **ServiceLB**: Load balancer
- **Local-path**: Storage provisioner
- **CoreDNS**: DNS server
- **Network Policy**: Calico/Flannel

## Common Commands

```bash
# Check status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f

# Get kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml

# Restart K3S
sudo systemctl restart k3s

# Stop K3S
sudo systemctl stop k3s

# Uninstall K3S
/usr/local/bin/k3s-uninstall.sh
```

## Configuration

### Server Config Location
```
/etc/rancher/k3s/config.yaml
```

### Example Config
```yaml
write-kubeconfig-mode: "0644"
tls-san:
  - "my-k3s-server.example.com"
disable:
  - traefik
  - servicelb
```

## Networking

### Default CNI
- Flannel (VXLAN mode)

### Network Policies
- Calico (optional)

### Service Types
- ClusterIP
- NodePort
- LoadBalancer (via ServiceLB)

## Storage

### Default Storage Class
- local-path (hostPath based)

### Supported Storage
- Local volumes
- NFS
- Longhorn
- External CSI drivers

## Security

### Default Security
- TLS enabled
- RBAC enabled
- Network policies supported
- Pod Security Standards

### Hardening
- CIS Kubernetes Benchmark compliant
- SELinux/AppArmor support
- Secrets encryption

## Monitoring

### Built-in Metrics
```bash
kubectl top nodes
kubectl top pods
```

### External Monitoring
- Prometheus
- Grafana
- Kubernetes Dashboard

## Backup & Restore

### Backup
```bash
# SQLite backup
sudo cp /var/lib/rancher/k3s/server/db/state.db backup.db

# etcd backup (if using etcd)
k3s etcd-snapshot save
```

### Restore
```bash
k3s server --cluster-reset --cluster-reset-restore-path=<snapshot>
```

## High Availability

### Requirements
- 3+ server nodes
- External datastore (MySQL/PostgreSQL) or embedded etcd
- Load balancer for API server

### Setup
```bash
# First server
curl -sfL https://get.k3s.io | sh -s - server --cluster-init

# Additional servers
curl -sfL https://get.k3s.io | sh -s - server --server https://<first-server>:6443
```

## Performance Tuning

### Resource Limits
```yaml
# /etc/rancher/k3s/config.yaml
kube-apiserver-arg:
  - "max-requests-inflight=400"
  - "max-mutating-requests-inflight=200"
```

### Node Optimization
```bash
# Increase file descriptors
ulimit -n 65536

# Kernel parameters
sysctl -w net.ipv4.ip_forward=1
```

## Migration from K8S

### Considerations
- API compatibility (same as K8S)
- Different default components
- Storage class differences
- Ingress controller differences

### Migration Steps
1. Export resources from K8S
2. Modify manifests (if needed)
3. Apply to K3S cluster
4. Verify functionality

## Best Practices

1. **Use config file** instead of CLI flags
2. **Enable auto-updates** for security patches
3. **Backup regularly** (especially SQLite DB)
4. **Monitor resources** to prevent exhaustion
5. **Use namespaces** for workload isolation
6. **Implement RBAC** for access control
7. **Enable audit logging** for compliance

## Resources

### Official Documentation
- https://docs.k3s.io
- https://github.com/k3s-io/k3s

### Community
- K3S Slack: rancher-users.slack.com
- GitHub Issues: github.com/k3s-io/k3s/issues
- Forums: forums.rancher.com

### Training
- Rancher Academy
- CNCF Kubernetes courses
- K3S workshops

## Next Steps

1. **Installation**: Start with [Single Node Setup](installation/01-single-node-setup.md)
2. **Architecture**: Understand [K3S Components](architecture/01-components.md)
3. **Hands-on**: Try [Basic Deployment Lab](hands-on-labs/lab1-basic-deployment.md)
4. **Troubleshooting**: Review [Common Issues](troubleshooting/common-issues.md)

---

**Last Updated**: December 2024  
**Version**: K3S v1.28+
