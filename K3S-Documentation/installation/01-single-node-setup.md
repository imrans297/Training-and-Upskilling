# K3S Single Node Installation

## Prerequisites

- Linux server (Ubuntu 20.04+ recommended)
- Root or sudo access
- 512MB RAM minimum (2GB recommended)
- 1 CPU core minimum (2 cores recommended)
- Internet connection

## Installation Methods

### Method 1: Quick Install (Recommended)

```bash
# Install K3S
curl -sfL https://get.k3s.io | sh -

# Check status
sudo systemctl status k3s

# Verify installation
sudo k3s kubectl get nodes
```

### Method 2: Custom Installation

```bash
# Install with custom options
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Or with environment variables
curl -sfL https://get.k3s.io | \
  K3S_KUBECONFIG_MODE="644" \
  INSTALL_K3S_EXEC="--write-kubeconfig-mode=644" \
  sh -
```

### Method 3: Specific Version

```bash
# Install specific version
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.4+k3s1 sh -
```

## Post-Installation Steps

### 1. Verify Installation

```bash
# Check K3S service
sudo systemctl status k3s

# Check nodes
sudo k3s kubectl get nodes

# Check all pods
sudo k3s kubectl get pods -A
```

Expected output:
```
NAME        STATUS   ROLES                  AGE   VERSION
localhost   Ready    control-plane,master   1m    v1.28.4+k3s1
```

### 2. Configure kubectl Access

#### Option A: Use k3s kubectl
```bash
sudo k3s kubectl get nodes
```

#### Option B: Setup regular kubectl
```bash
# Install kubectl (if not installed)
sudo apt-get update
sudo apt-get install -y kubectl

# Copy kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Test
kubectl get nodes
```

#### Option C: Export KUBECONFIG
```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get nodes
```

### 3. Enable kubectl Autocompletion

```bash
# For bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

# For zsh
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
source ~/.zshrc
```

## Configuration Options

### Using Config File

Create `/etc/rancher/k3s/config.yaml`:

```yaml
write-kubeconfig-mode: "0644"
tls-san:
  - "k3s.example.com"
  - "192.168.1.100"
disable:
  - traefik
  - servicelb
node-label:
  - "environment=dev"
  - "region=us-east"
```

Restart K3S:
```bash
sudo systemctl restart k3s
```

### Common Configuration Options

```yaml
# Disable components
disable:
  - traefik          # Ingress controller
  - servicelb        # Load balancer
  - local-storage    # Storage provisioner
  - metrics-server   # Metrics

# Networking
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: "10.43.0.10"

# Security
secrets-encryption: true
protect-kernel-defaults: true

# Resource limits
kube-apiserver-arg:
  - "max-requests-inflight=400"
```

## Verification Tests

### 1. Deploy Test Pod

```bash
# Create nginx pod
kubectl run nginx --image=nginx --port=80

# Check pod status
kubectl get pods

# Expose as service
kubectl expose pod nginx --type=NodePort --port=80

# Get service details
kubectl get svc nginx

# Test access
curl http://localhost:<NodePort>
```

### 2. Check System Pods

```bash
kubectl get pods -n kube-system
```

Expected pods:
- coredns
- local-path-provisioner
- metrics-server
- traefik (if not disabled)

### 3. Test DNS

```bash
# Create test pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Should resolve to cluster IP
```

## File Locations

### Important Directories

```bash
# K3S binary
/usr/local/bin/k3s

# Configuration
/etc/rancher/k3s/config.yaml

# Kubeconfig
/etc/rancher/k3s/k3s.yaml

# Data directory
/var/lib/rancher/k3s/

# Manifests (auto-deploy)
/var/lib/rancher/k3s/server/manifests/

# Logs
/var/log/syslog (or journalctl -u k3s)
```

### Database Location

```bash
# SQLite database
/var/lib/rancher/k3s/server/db/state.db
```

## Service Management

### Systemd Commands

```bash
# Start K3S
sudo systemctl start k3s

# Stop K3S
sudo systemctl stop k3s

# Restart K3S
sudo systemctl restart k3s

# Enable on boot
sudo systemctl enable k3s

# Disable on boot
sudo systemctl disable k3s

# Check status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f
```

## Firewall Configuration

### Required Ports

```bash
# K3S server
6443/tcp  # Kubernetes API
10250/tcp # Kubelet metrics
2379-2380/tcp # etcd (if using embedded etcd)

# Optional
80/tcp    # HTTP ingress
443/tcp   # HTTPS ingress
8472/udp  # Flannel VXLAN
```

### UFW Example

```bash
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8472/udp
```

## Resource Monitoring

### Check Resource Usage

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -A

# System resources
free -h
df -h
```

## Backup

### Backup K3S

```bash
# Stop K3S
sudo systemctl stop k3s

# Backup data directory
sudo tar -czf k3s-backup-$(date +%Y%m%d).tar.gz /var/lib/rancher/k3s/

# Backup config
sudo cp /etc/rancher/k3s/config.yaml config-backup.yaml

# Start K3S
sudo systemctl start k3s
```

### Automated Backup Script

```bash
#!/bin/bash
BACKUP_DIR="/backup/k3s"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup SQLite DB
sudo cp /var/lib/rancher/k3s/server/db/state.db \
  $BACKUP_DIR/state-$DATE.db

# Backup config
sudo cp /etc/rancher/k3s/config.yaml \
  $BACKUP_DIR/config-$DATE.yaml

echo "Backup completed: $DATE"
```

## Troubleshooting

### Check Logs

```bash
# K3S service logs
sudo journalctl -u k3s -f

# Kubelet logs
sudo journalctl -u k3s -f | grep kubelet

# Container logs
sudo k3s crictl logs <container-id>
```

### Common Issues

#### Issue: K3S won't start
```bash
# Check logs
sudo journalctl -u k3s -n 50

# Check port conflicts
sudo netstat -tulpn | grep 6443

# Reset and reinstall
/usr/local/bin/k3s-uninstall.sh
curl -sfL https://get.k3s.io | sh -
```

#### Issue: Pods not starting
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe node

# Check container runtime
sudo k3s crictl ps -a
```

#### Issue: Network issues
```bash
# Check CNI
kubectl get pods -n kube-system | grep flannel

# Check iptables
sudo iptables -L -n -v

# Restart K3S
sudo systemctl restart k3s
```

## Uninstallation

### Complete Removal

```bash
# Uninstall K3S
/usr/local/bin/k3s-uninstall.sh

# Remove data (optional)
sudo rm -rf /var/lib/rancher/k3s/
sudo rm -rf /etc/rancher/k3s/

# Remove kubeconfig
rm -rf ~/.kube/config
```

## Next Steps

1. Deploy applications: [Basic Deployment Lab](../hands-on-labs/lab1-basic-deployment.md)
2. Setup ingress: [Ingress Setup Lab](../hands-on-labs/lab2-ingress-setup.md)
3. Multi-node cluster: [Multi-Node Setup](02-multi-node-cluster.md)
4. High availability: [HA Setup](03-ha-setup.md)

## Quick Reference

```bash
# Installation
curl -sfL https://get.k3s.io | sh -

# Check status
sudo systemctl status k3s

# Get nodes
sudo k3s kubectl get nodes

# Get pods
sudo k3s kubectl get pods -A

# Logs
sudo journalctl -u k3s -f

# Uninstall
/usr/local/bin/k3s-uninstall.sh
```
