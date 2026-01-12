# K3S Multi-Node Cluster Setup

## Architecture Overview

```
┌─────────────────┐
│  K3S Server     │  (Master Node)
│  - API Server   │
│  - Scheduler    │
│  - Controller   │
│  - SQLite/etcd  │
└────────┬────────┘
         │
    ┌────┴────┬────────┐
    │         │        │
┌───▼───┐ ┌──▼───┐ ┌──▼───┐
│Agent 1│ │Agent2│ │Agent3│  (Worker Nodes)
│Kubelet│ │Kubelet│ │Kubelet│
└───────┘ └──────┘ └──────┘
```

## Prerequisites

### Server Node (Master)
- 2 CPU cores
- 2GB RAM
- 20GB disk
- Static IP address

### Agent Nodes (Workers)
- 1 CPU core
- 1GB RAM
- 10GB disk
- Network connectivity to server

## Step 1: Install K3S Server

### On Master Node

```bash
# Install K3S server
curl -sfL https://get.k3s.io | sh -

# Get node token (needed for agents)
sudo cat /var/lib/rancher/k3s/server/node-token
```

Save the token output, you'll need it for agent nodes.

### Verify Server Installation

```bash
# Check status
sudo systemctl status k3s

# Check nodes
sudo k3s kubectl get nodes

# Get server IP
hostname -I
```

## Step 2: Install K3S Agents

### On Each Worker Node

```bash
# Replace with your server IP and token
export K3S_URL="https://<SERVER_IP>:6443"
export K3S_TOKEN="<NODE_TOKEN_FROM_SERVER>"

# Install agent
curl -sfL https://get.k3s.io | sh -
```

### Example

```bash
export K3S_URL="https://192.168.1.100:6443"
export K3S_TOKEN="K10abc123def456::server:xyz789"

curl -sfL https://get.k3s.io | sh -
```

### Verify Agent Installation

```bash
# On agent node
sudo systemctl status k3s-agent

# On server node
sudo k3s kubectl get nodes
```

Expected output:
```
NAME      STATUS   ROLES                  AGE   VERSION
server    Ready    control-plane,master   10m   v1.28.4+k3s1
agent-1   Ready    <none>                 2m    v1.28.4+k3s1
agent-2   Ready    <none>                 1m    v1.28.4+k3s1
```

## Step 3: Label Worker Nodes

```bash
# Label nodes by role
kubectl label node agent-1 node-role.kubernetes.io/worker=worker
kubectl label node agent-2 node-role.kubernetes.io/worker=worker

# Label by environment
kubectl label node agent-1 environment=production
kubectl label node agent-2 environment=production

# Verify labels
kubectl get nodes --show-labels
```

## Configuration Options

### Server Configuration

Create `/etc/rancher/k3s/config.yaml` on server:

```yaml
write-kubeconfig-mode: "0644"
tls-san:
  - "k3s-server.example.com"
  - "192.168.1.100"
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
disable:
  - traefik
node-taint:
  - "CriticalAddonsOnly=true:NoExecute"
```

### Agent Configuration

Create `/etc/rancher/k3s/config.yaml` on agents:

```yaml
server: https://192.168.1.100:6443
token: <NODE_TOKEN>
node-label:
  - "environment=production"
  - "region=us-east"
kubelet-arg:
  - "max-pods=110"
```

## Networking Setup

### Firewall Rules

#### On Server Node

```bash
# API Server
sudo ufw allow 6443/tcp

# Kubelet metrics
sudo ufw allow 10250/tcp

# etcd (if using)
sudo ufw allow 2379:2380/tcp

# Flannel VXLAN
sudo ufw allow 8472/udp

# Allow from agent nodes
sudo ufw allow from <AGENT_IP>
```

#### On Agent Nodes

```bash
# Kubelet
sudo ufw allow 10250/tcp

# Flannel VXLAN
sudo ufw allow 8472/udp

# Allow from server
sudo ufw allow from <SERVER_IP>
```

### Network Ports Reference

| Port | Protocol | Component | Direction |
|------|----------|-----------|-----------|
| 6443 | TCP | API Server | Agents → Server |
| 10250 | TCP | Kubelet | Server ↔ Agents |
| 8472 | UDP | Flannel VXLAN | All nodes |
| 2379-2380 | TCP | etcd | Server only |

## Testing the Cluster

### 1. Deploy Multi-Replica Application

```bash
# Create deployment
kubectl create deployment nginx --image=nginx --replicas=3

# Check pod distribution
kubectl get pods -o wide

# Scale up
kubectl scale deployment nginx --replicas=6

# Verify distribution across nodes
kubectl get pods -o wide | grep nginx
```

### 2. Test Node Affinity

```yaml
# nginx-affinity.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-affinity
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/worker
                operator: In
                values:
                - worker
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl apply -f nginx-affinity.yaml
kubectl get pods -o wide
```

### 3. Test Service Load Balancing

```bash
# Create service
kubectl expose deployment nginx --port=80 --type=NodePort

# Get service details
kubectl get svc nginx

# Test from each node
curl http://<NODE_IP>:<NodePort>
```

## Node Management

### Add New Agent Node

```bash
# On new node
export K3S_URL="https://<SERVER_IP>:6443"
export K3S_TOKEN="<NODE_TOKEN>"
curl -sfL https://get.k3s.io | sh -

# Verify on server
kubectl get nodes
```

### Remove Agent Node

```bash
# Drain node (on server)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Delete node (on server)
kubectl delete node <node-name>

# Uninstall K3S (on agent)
/usr/local/bin/k3s-agent-uninstall.sh
```

### Cordon/Uncordon Nodes

```bash
# Prevent new pods on node
kubectl cordon <node-name>

# Allow new pods on node
kubectl uncordon <node-name>

# Check node status
kubectl get nodes
```

## High Availability Considerations

### Load Balancer for API Server

```bash
# Install HAProxy on separate node
sudo apt-get install haproxy

# Configure /etc/haproxy/haproxy.cfg
frontend k3s-api
    bind *:6443
    mode tcp
    default_backend k3s-servers

backend k3s-servers
    mode tcp
    balance roundrobin
    server server1 192.168.1.101:6443 check
    server server2 192.168.1.102:6443 check
    server server3 192.168.1.103:6443 check
```

### Multiple Server Nodes

```bash
# First server
curl -sfL https://get.k3s.io | sh -s - server --cluster-init

# Additional servers
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://<FIRST_SERVER>:6443 \
  --token <TOKEN>
```

## Monitoring

### Check Cluster Health

```bash
# Node status
kubectl get nodes

# Component status
kubectl get componentstatuses

# Pod distribution
kubectl get pods -A -o wide

# Resource usage
kubectl top nodes
kubectl top pods -A
```

### Monitor Specific Node

```bash
# Node details
kubectl describe node <node-name>

# Node events
kubectl get events --field-selector involvedObject.name=<node-name>

# Node logs (on the node)
sudo journalctl -u k3s-agent -f
```

## Backup & Restore

### Backup Server Node

```bash
# Stop K3S
sudo systemctl stop k3s

# Backup data
sudo tar -czf k3s-server-backup.tar.gz \
  /var/lib/rancher/k3s/ \
  /etc/rancher/k3s/

# Start K3S
sudo systemctl start k3s
```

### Restore Server Node

```bash
# Stop K3S
sudo systemctl stop k3s

# Restore data
sudo tar -xzf k3s-server-backup.tar.gz -C /

# Start K3S
sudo systemctl start k3s
```

## Troubleshooting

### Agent Can't Connect to Server

```bash
# Check connectivity
telnet <SERVER_IP> 6443

# Check token
sudo cat /var/lib/rancher/k3s/server/node-token

# Check firewall
sudo ufw status

# Check logs on agent
sudo journalctl -u k3s-agent -f
```

### Pods Not Scheduling

```bash
# Check node status
kubectl get nodes

# Check node resources
kubectl describe node <node-name>

# Check pod events
kubectl describe pod <pod-name>

# Check taints
kubectl describe node <node-name> | grep Taints
```

### Network Issues Between Nodes

```bash
# Test connectivity
ping <OTHER_NODE_IP>

# Check Flannel
kubectl get pods -n kube-system | grep flannel

# Check CNI
sudo ls -la /etc/cni/net.d/

# Restart networking
sudo systemctl restart k3s
sudo systemctl restart k3s-agent
```

## Upgrade Cluster

### Upgrade Server

```bash
# On server node
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -

# Verify
kubectl get nodes
```

### Upgrade Agents

```bash
# On each agent node (one at a time)
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -

# Verify
kubectl get nodes
```

## Best Practices

1. **Use static IPs** for all nodes
2. **Label nodes** appropriately for workload placement
3. **Monitor resources** regularly
4. **Backup server** node frequently
5. **Test failover** scenarios
6. **Document** node roles and IPs
7. **Use node affinity** for critical workloads
8. **Implement monitoring** (Prometheus/Grafana)

## Quick Reference

```bash
# Server installation
curl -sfL https://get.k3s.io | sh -

# Get token
sudo cat /var/lib/rancher/k3s/server/node-token

# Agent installation
export K3S_URL="https://<SERVER_IP>:6443"
export K3S_TOKEN="<TOKEN>"
curl -sfL https://get.k3s.io | sh -

# Check nodes
kubectl get nodes

# Label node
kubectl label node <name> role=worker

# Drain node
kubectl drain <name> --ignore-daemonsets

# Delete node
kubectl delete node <name>
```

## Next Steps

- [High Availability Setup](03-ha-setup.md)
- [Basic Deployment Lab](../hands-on-labs/lab1-basic-deployment.md)
- [Monitoring Setup](../hands-on-labs/lab4-monitoring.md)
