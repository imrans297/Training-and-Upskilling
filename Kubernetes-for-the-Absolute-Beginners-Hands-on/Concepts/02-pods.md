# Pods

## What is a Pod?
Smallest deployable unit in Kubernetes. Contains one or more containers sharing network and storage.

## Pod Characteristics
- Shared IP address
- Shared volumes
- Ephemeral (temporary)
- Single or multi-container

## Pod Lifecycle
1. **Pending** - Accepted but not running
2. **Running** - Bound to node, containers running
3. **Succeeded** - All containers terminated successfully
4. **Failed** - Containers terminated with failure
5. **Unknown** - State cannot be determined

## Multi-Container Patterns
- **Sidecar** - Helper container
- **Ambassador** - Proxy container
- **Adapter** - Standardize output

## Pod Design Patterns
- One container per pod (most common)
- Tightly coupled containers in same pod
- Shared storage between containers
