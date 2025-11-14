# ConfigMap and Secret Commands

## Purpose
Manage application configuration and sensitive data securely.

## What You'll Achieve
- Externalize application configuration
- Store sensitive data securely
- Inject config into containers
- Manage credentials and certificates

---

## ConfigMap Commands

### Create ConfigMaps
```bash
# From literal - Create ConfigMap from key-value pairs
# Purpose: Store simple configuration values
kubectl create configmap app-config --from-literal=key1=value1 --from-literal=key2=value2

# From file - Create ConfigMap from file
# Purpose: Store entire config file as ConfigMap
kubectl create configmap app-config --from-file=config.properties

# From directory
kubectl create configmap app-config --from-file=config-dir/

# From YAML
kubectl create -f configmap.yaml
kubectl apply -f configmap.yaml
```

### List ConfigMaps
```bash
# All configmaps
kubectl get configmaps
kubectl get cm

# Describe
kubectl describe configmap <configmap-name>
kubectl describe cm <configmap-name>
```

### View ConfigMap Data
```bash
# Get YAML - View ConfigMap content
# Purpose: See stored configuration data
kubectl get configmap <configmap-name> -o yaml

# Get specific key - Extract single value
# Purpose: Retrieve specific configuration value
kubectl get configmap <configmap-name> -o jsonpath='{.data.key1}'
```

### Delete ConfigMaps
```bash
# Delete configmap
kubectl delete configmap <configmap-name>
kubectl delete cm <configmap-name>
```

## Secret Commands

### Create Secrets
```bash
# Generic secret from literal - Create secret from values
# Purpose: Store credentials, API keys securely
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=secret123

# From file
kubectl create secret generic db-secret --from-file=username.txt --from-file=password.txt

# Docker registry secret - Store registry credentials
# Purpose: Pull images from private registries
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email>

# TLS secret - Store SSL/TLS certificates
# Purpose: Enable HTTPS for services
kubectl create secret tls tls-secret --cert=path/to/cert --key=path/to/key

# From YAML
kubectl create -f secret.yaml
kubectl apply -f secret.yaml
```

### List Secrets
```bash
# All secrets
kubectl get secrets

# Describe
kubectl describe secret <secret-name>
```

### View Secret Data
```bash
# Get YAML - View secret (base64 encoded)
# Purpose: See secret structure (not plaintext)
kubectl get secret <secret-name> -o yaml

# Decode secret - View plaintext value
# Purpose: Retrieve actual secret value
kubectl get secret <secret-name> -o jsonpath='{.data.password}' | base64 --decode

# Get all keys decoded
kubectl get secret <secret-name> -o json | jq '.data | map_values(@base64d)'
```

### Delete Secrets
```bash
# Delete secret
kubectl delete secret <secret-name>
```

### Edit ConfigMap/Secret
```bash
# Edit configmap
kubectl edit configmap <configmap-name>

# Edit secret
kubectl edit secret <secret-name>
```
