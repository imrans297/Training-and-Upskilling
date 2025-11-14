# Volumes and Storage

## Volumes

### What is a Volume?
Directory accessible to containers in a pod, persists beyond container restarts.

### Volume Types
- **emptyDir** - Temporary, pod lifetime
- **hostPath** - Node filesystem
- **configMap** - ConfigMap data
- **secret** - Secret data
- **persistentVolumeClaim** - PVC reference

## Persistent Volumes (PV)

### What is a PV?
Cluster-level storage resource provisioned by admin or dynamically.

### Access Modes
- **ReadWriteOnce (RWO)** - Single node read-write
- **ReadOnlyMany (ROX)** - Multiple nodes read-only
- **ReadWriteMany (RWX)** - Multiple nodes read-write

### Reclaim Policies
- **Retain** - Manual reclamation
- **Delete** - Delete storage
- **Recycle** - Basic scrub (deprecated)

## Persistent Volume Claims (PVC)

### What is a PVC?
Request for storage by user, binds to PV.

## Storage Classes

### What is a StorageClass?
Defines storage types and provisioners for dynamic provisioning.

### Dynamic Provisioning
- Automatic PV creation
- On-demand storage
- Cloud provider integration
