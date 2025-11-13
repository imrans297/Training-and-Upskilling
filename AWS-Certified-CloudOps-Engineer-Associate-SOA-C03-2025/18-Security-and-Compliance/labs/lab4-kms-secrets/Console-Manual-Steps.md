# Lab 4: AWS KMS & Secrets Manager - Console Manual Steps

## Part 1: Create KMS Key

### Step 1: Create KMS Key

1. **Go to KMS Console**
2. **Customer managed keys** → **Create key**
3. **Configure key:**
   - **Key type**: Symmetric
   - **Key usage**: Encrypt and decrypt
   - **Advanced options**: KMS
4. **Next**

### Step 2: Add Labels

1. **Alias**: `cloudops-key`
2. **Description**: `CloudOps encryption key`
3. **Tags**: 
   - Key: Environment, Value: Production
   - Key: ManagedBy, Value: CloudOps
4. **Next**

### Step 3: Define Key Administrators

1. **Key administrators**: Select IAM users/roles
2. **Key deletion**: ☑️ Allow key administrators to delete this key
3. **Next**

### Step 4: Define Key Usage Permissions

1. **Key users**: Select IAM users/roles who can use the key
2. **Other AWS accounts**: Leave empty (or add if needed)
3. **Next**

### Step 5: Review and Create

1. **Review key policy**
2. **Finish**

### Step 6: Enable Key Rotation

1. **Select created key**
2. **Key rotation** tab
3. **☑️ Automatically rotate this KMS key every year**
4. **Save**

## Part 2: Create Secrets in Secrets Manager

### Step 1: Store Database Credentials

1. **Go to Secrets Manager Console**
2. **Store a new secret**
3. **Secret type**: 
   - **Credentials for RDS database** (or Other type of secret)
4. **Credentials:**
   - **Username**: `admin`
   - **Password**: Generate or enter secure password
   - **Encryption key**: Select `cloudops-key`
5. **Database**: Optional - select RDS instance
6. **Next**

### Step 2: Configure Secret

1. **Secret name**: `cloudops/database/credentials`
2. **Description**: `Database credentials for CloudOps application`
3. **Tags**: Add as needed
4. **Next**

### Step 3: Configure Rotation (Optional)

1. **Automatic rotation**: ☐ Disable for now
2. **Next**

### Step 4: Review and Store

1. **Review configuration**
2. **Store**

### Step 5: Store API Key

1. **Store a new secret**
2. **Secret type**: Other type of secret
3. **Key/value pairs:**
   - **Plaintext**: Enter API key directly
4. **Encryption key**: Select `cloudops-key`
5. **Next**
6. **Secret name**: `cloudops/api/key`
7. **Store**

## Testing After Creation

### Test 1: Retrieve Secret via Console

1. **Secrets Manager Console**
2. **Select secret**: `cloudops/database/credentials`
3. **Retrieve secret value**
4. **View credentials:**
   - Username
   - Password
   - Connection details

### Test 2: Encrypt Data with KMS

1. **KMS Console**
2. **Select key**: `cloudops-key`
3. **Key actions** → **Encrypt data**
4. **Enter plaintext**: `Sensitive information`
5. **Encrypt**
6. **Copy ciphertext**

### Test 3: Decrypt Data

1. **Key actions** → **Decrypt data**
2. **Paste ciphertext**
3. **Decrypt**
4. **View plaintext**

### Test 4: Update Secret

1. **Secrets Manager Console**
2. **Select secret**: `cloudops/database/credentials`
3. **Retrieve secret value**
4. **Edit**
5. **Update password**
6. **Save**

### Test 5: View Secret Versions

1. **Select secret**
2. **Versions** tab
3. **View version history:**
   - Current version (AWSCURRENT)
   - Previous versions (AWSPREVIOUS)
   - Version IDs
   - Creation dates

## What to Observe

### KMS Key Details
- **Key ID**: Unique identifier
- **ARN**: Full Amazon Resource Name
- **Status**: Enabled
- **Creation date**: When key was created
- **Key rotation**: Enabled/Disabled
- **Origin**: AWS_KMS
- **Key spec**: SYMMETRIC_DEFAULT

### Key Policy
Shows who can:
- Administer the key
- Use the key for encryption/decryption
- Grant permissions to others

### Key Usage
- **CloudTrail logs**: All key operations
- **Grants**: Temporary permissions
- **Aliases**: Friendly names

### Secrets Manager Details
- **Secret name**: Hierarchical naming
- **Description**: Purpose of secret
- **Encryption**: KMS key used
- **Last retrieved**: When accessed
- **Last changed**: When updated
- **Rotation**: Status and schedule

### Secret Versions
- **AWSCURRENT**: Active version
- **AWSPREVIOUS**: Previous version
- **Version stages**: Custom labels
- **Version IDs**: Unique identifiers

## Use Cases Demonstration

### Use Case 1: Application Configuration

**Store application config:**
1. **Create secret**: `cloudops/app/config`
2. **Store JSON:**
```json
{
  "api_endpoint": "https://api.example.com",
  "api_key": "sk-1234567890",
  "timeout": 30,
  "retry_count": 3
}
```

### Use Case 2: Certificate Storage

**Store SSL certificate:**
1. **Create secret**: `cloudops/ssl/certificate`
2. **Store certificate and private key**
3. **Use in load balancer or application**

### Use Case 3: Third-party API Keys

**Store external service keys:**
1. **Create secret**: `cloudops/external/stripe-key`
2. **Store API key**
3. **Reference in application code**

## Integration Examples

### With Lambda
1. **Lambda function** can retrieve secrets
2. **Use IAM role** for permissions
3. **Cache secrets** to reduce API calls

### With ECS/Fargate
1. **Task definition** references secrets
2. **Injected as environment variables**
3. **Automatic retrieval** at container start

### With RDS
1. **Store RDS credentials**
2. **Enable automatic rotation**
3. **Lambda rotates password** automatically

## Monitoring

### CloudTrail Events to Monitor
- **Encrypt**: Data encryption operations
- **Decrypt**: Data decryption operations
- **GetSecretValue**: Secret retrievals
- **PutSecretValue**: Secret updates
- **DeleteSecret**: Secret deletions

### CloudWatch Alarms
1. **Create alarm** for excessive GetSecretValue calls
2. **Alert on** failed decryption attempts
3. **Monitor** key usage patterns

## Troubleshooting

### Issue: Cannot decrypt data
**Check:**
1. IAM permissions for kms:Decrypt
2. Key policy allows your user/role
3. Key is enabled (not disabled/deleted)
4. Correct key was used for encryption

### Issue: Cannot retrieve secret
**Check:**
1. IAM permissions for secretsmanager:GetSecretValue
2. Secret exists and is not deleted
3. Resource policy allows access
4. KMS key permissions for decryption

### Issue: Key rotation failed
**Check:**
1. Key is customer managed (not AWS managed)
2. Key is enabled
3. Sufficient permissions
4. No pending deletion

## Best Practices

1. **Use separate keys** for different purposes
2. **Enable key rotation** for compliance
3. **Use aliases** for easier key management
4. **Implement least privilege** access
5. **Monitor key usage** via CloudTrail
6. **Use secret rotation** for credentials
7. **Tag resources** for organization
8. **Use resource policies** for cross-account access

## Cleanup

### Delete Secrets
1. **Secrets Manager Console**
2. **Select secret**
3. **Actions** → **Delete secret**
4. **Schedule deletion**: 7-30 days
5. **Confirm**

### Delete KMS Key
1. **KMS Console**
2. **Select key**
3. **Key actions** → **Schedule key deletion**
4. **Waiting period**: 7-30 days
5. **Confirm**

**Note**: Both have recovery periods before permanent deletion

## Key Takeaways

- KMS provides centralized key management
- Automatic key rotation for compliance
- Secrets Manager stores and rotates credentials
- Both integrate with AWS services
- CloudTrail logs all operations
- Essential for security and compliance
- Cost-effective for credential management
