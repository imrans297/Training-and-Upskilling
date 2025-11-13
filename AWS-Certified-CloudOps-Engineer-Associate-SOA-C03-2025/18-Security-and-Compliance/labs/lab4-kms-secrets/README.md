# Lab 4: AWS KMS & Secrets Manager

## What is KMS?
AWS Key Management Service (KMS) is a managed service that makes it easy to create and control cryptographic keys used to encrypt your data.

## What is Secrets Manager?
AWS Secrets Manager helps you protect secrets needed to access your applications, services, and IT resources. It enables you to rotate, manage, and retrieve credentials.

## Why Use KMS & Secrets Manager?
- **Data Encryption**: Protect sensitive data at rest and in transit
- **Key Management**: Centralized key lifecycle management
- **Credential Rotation**: Automatic secret rotation
- **Audit Trail**: CloudTrail logs all key usage
- **Compliance**: Meet regulatory requirements

## Where is it Used?
- Database credential management
- API key storage
- Encryption key management
- Application secrets
- Certificate storage

## Resources Created
- KMS key with automatic rotation
- KMS alias for easy reference
- Database credentials secret
- API key secret
- Both secrets encrypted with KMS

## Deployment

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

## What to Observe After Deployment

### 1. KMS Key Status
```bash
# Describe KMS key
aws kms describe-key --key-id $(terraform output -raw kms_key_id)

# Check key rotation status
aws kms get-key-rotation-status --key-id $(terraform output -raw kms_key_id)

# List key aliases
aws kms list-aliases | grep cloudops
```

### 2. Secrets Manager
```bash
# List secrets
aws secretsmanager list-secrets

# Get secret value (database credentials)
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_secret_arn) \
  --query SecretString --output text | jq

# Get API key
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw api_secret_arn) \
  --query SecretString --output text
```

## Testing

### Test 1: Encrypt/Decrypt with KMS
```bash
# Encrypt data
echo "Sensitive data" > plaintext.txt
aws kms encrypt \
  --key-id alias/cloudops-key \
  --plaintext fileb://plaintext.txt \
  --output text \
  --query CiphertextBlob | base64 -d > encrypted.bin

# Decrypt data
aws kms decrypt \
  --ciphertext-blob fileb://encrypted.bin \
  --output text \
  --query Plaintext | base64 -d
```

### Test 2: Generate Data Key
```bash
# Generate data key for envelope encryption
aws kms generate-data-key \
  --key-id alias/cloudops-key \
  --key-spec AES_256

# Returns plaintext key and encrypted key
```

### Test 3: Update Secret
```bash
# Update database password
aws secretsmanager update-secret \
  --secret-id cloudops/database/credentials \
  --secret-string '{"username":"admin","password":"NewPassword456!","host":"db.cloudops.example.com","port":3306,"engine":"mysql"}'

# Retrieve updated secret
aws secretsmanager get-secret-value \
  --secret-id cloudops/database/credentials \
  --query SecretString --output text | jq
```

### Test 4: Secret Versioning
```bash
# List secret versions
aws secretsmanager list-secret-version-ids \
  --secret-id cloudops/database/credentials

# Get specific version
aws secretsmanager get-secret-value \
  --secret-id cloudops/database/credentials \
  --version-id <version-id>
```

## Key Observations

### KMS Key Features
- **Automatic rotation**: Enabled (yearly)
- **Key state**: Enabled
- **Key usage**: ENCRYPT_DECRYPT
- **Key spec**: SYMMETRIC_DEFAULT
- **Origin**: AWS_KMS

### KMS Key Policy
- Root account has full access
- Can grant access to specific IAM users/roles
- Supports cross-account access
- Integrates with AWS services

### Secrets Manager Features
- **Encryption**: Uses KMS key
- **Versioning**: Automatic version tracking
- **Rotation**: Can enable automatic rotation
- **Replication**: Can replicate to other regions
- **Access control**: IAM-based permissions

### Secret Structure
Database credentials include:
- Username
- Password
- Host
- Port
- Engine type

## Use Cases

### 1. Application Database Connection
```python
import boto3
import json

def get_db_credentials():
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId='cloudops/database/credentials')
    secret = json.loads(response['SecretString'])
    return secret

# Use in application
creds = get_db_credentials()
connection = mysql.connect(
    host=creds['host'],
    user=creds['username'],
    password=creds['password'],
    port=creds['port']
)
```

### 2. Encrypt S3 Objects
```bash
# Upload with KMS encryption
aws s3 cp file.txt s3://my-bucket/ \
  --sse aws:kms \
  --sse-kms-key-id alias/cloudops-key
```

### 3. Lambda Environment Variables
```bash
# Encrypt Lambda environment variable
aws lambda update-function-configuration \
  --function-name my-function \
  --kms-key-arn $(terraform output -raw kms_key_arn) \
  --environment Variables={DB_SECRET=cloudops/database/credentials}
```

## Monitoring

### CloudTrail Events
```bash
# View KMS key usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=$(terraform output -raw kms_key_id) \
  --max-items 10
```

### CloudWatch Metrics
- KMS API call count
- Secrets Manager retrieval count
- Failed decryption attempts

## Troubleshooting

### Issue: Access denied to KMS key
```bash
# Check key policy
aws kms get-key-policy \
  --key-id $(terraform output -raw kms_key_id) \
  --policy-name default

# Check IAM permissions
aws iam get-user-policy --user-name <username> --policy-name <policy-name>
```

### Issue: Cannot retrieve secret
```bash
# Check secret exists
aws secretsmanager describe-secret \
  --secret-id cloudops/database/credentials

# Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn <user-arn> \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns $(terraform output -raw db_secret_arn)
```

## Cleanup
```bash
terraform destroy -auto-approve
```

## Cost Considerations
- **KMS**: $1/month per key + $0.03 per 10,000 requests
- **Secrets Manager**: $0.40/month per secret + $0.05 per 10,000 API calls
- **Typical cost**: $5-20/month for small applications
