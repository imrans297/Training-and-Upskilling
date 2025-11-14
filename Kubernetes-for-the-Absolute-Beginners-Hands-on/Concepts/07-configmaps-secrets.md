# ConfigMaps and Secrets

## ConfigMaps

### What is a ConfigMap?
Store non-confidential configuration data as key-value pairs.

### Use Cases
- Application configuration
- Command-line arguments
- Environment variables
- Configuration files

### Consumption Methods
- Environment variables
- Command-line arguments
- Volume mounts

## Secrets

### What is a Secret?
Store sensitive data (passwords, tokens, keys) in base64 encoded format.

### Secret Types
- **Opaque** - Arbitrary user data (default)
- **kubernetes.io/service-account-token** - Service account token
- **kubernetes.io/dockerconfigjson** - Docker registry credentials
- **kubernetes.io/tls** - TLS certificates

### Best Practices
- Enable encryption at rest
- Use RBAC for access control
- Rotate secrets regularly
- Use external secret management (Vault)

## ConfigMap vs Secret
- ConfigMap: Non-sensitive data
- Secret: Sensitive data, base64 encoded
