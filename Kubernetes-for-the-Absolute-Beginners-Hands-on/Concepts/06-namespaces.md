# Namespaces

## What is a Namespace?
Virtual clusters within physical cluster for resource isolation.

## Default Namespaces
- **default** - Default for objects without namespace
- **kube-system** - System components
- **kube-public** - Publicly accessible
- **kube-node-lease** - Node heartbeats

## Use Cases
- Multi-tenancy
- Environment separation (dev/staging/prod)
- Team isolation
- Resource quotas

## Resource Quotas
- Limit CPU/memory per namespace
- Limit object count
- Prevent resource exhaustion

## Network Policies
- Control traffic between namespaces
- Isolation and security

## Best Practices
- Use namespaces for large teams
- Apply resource quotas
- Use RBAC for access control
