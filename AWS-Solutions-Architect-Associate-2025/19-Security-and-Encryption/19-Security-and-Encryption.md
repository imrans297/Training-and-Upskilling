# Section 22: AWS Security and Encryption

## 📋 Overview
This section covers AWS security services including encryption with KMS, secrets management with Systems Manager Parameter Store, DDoS protection with Shield, and web application security with WAF.

## 🔐 AWS Key Management Service (KMS)

### What is KMS?
- **Managed encryption**: Centralized key management service
- **Customer Master Keys (CMKs)**: Encryption keys for data protection
- **Envelope encryption**: Efficient encryption for large data
- **Integration**: Native integration with AWS services
- **Compliance**: FIPS 140-2 Level 2 validated

### KMS Key Types
- **AWS Managed Keys**: Automatically created and managed
- **Customer Managed Keys**: Full control over key policies
- **AWS Owned Keys**: Used by AWS services internally
- **CloudHSM Keys**: Hardware security module backed keys

## 🔒 AWS Systems Manager Parameter Store

### What is Parameter Store?
- **Configuration management**: Store configuration data and secrets
- **Hierarchical storage**: Organize parameters in tree structure
- **Encryption**: Encrypt sensitive parameters with KMS
- **Access control**: Fine-grained IAM permissions
- **Versioning**: Track parameter changes over time

## 🛡️ AWS Shield

### What is Shield?
- **DDoS protection**: Protect against distributed denial of service attacks
- **Always-on detection**: Automatic attack detection and mitigation
- **Shield Standard**: Free basic protection for all AWS customers
- **Shield Advanced**: Enhanced protection with 24/7 support
- **Cost protection**: Safeguard against DDoS-related charges

## 🔥 AWS WAF (Web Application Firewall)

### What is WAF?
- **Web application protection**: Filter malicious web traffic
- **Rule-based filtering**: Custom rules for traffic inspection
- **Managed rules**: Pre-configured rule sets from AWS and partners
- **Real-time monitoring**: Detailed metrics and logging
- **Integration**: Works with CloudFront, ALB, and API Gateway

## 🛠️ Hands-On Practice

### Practice 1: KMS Key Management and Encryption
**Objective**: Create and manage KMS keys for data encryption

**Steps**:
1. **Create Customer Managed Keys**:
   ```bash
   # Create KMS key for general encryption
   aws kms create-key \
     --description "General purpose encryption key" \
     --key-usage ENCRYPT_DECRYPT \
     --key-spec SYMMETRIC_DEFAULT
   
   # Get key ID from output and create alias
   KEY_ID="your-key-id-here"
   aws kms create-alias \
     --alias-name alias/general-encryption \
     --target-key-id $KEY_ID
   
   # Create key for S3 encryption
   aws kms create-key \
     --description "S3 bucket encryption key" \
     --key-usage ENCRYPT_DECRYPT
   
   S3_KEY_ID="your-s3-key-id-here"
   aws kms create-alias \
     --alias-name alias/s3-encryption \
     --target-key-id $S3_KEY_ID
   ```

2. **Configure Key Policies**:
   ```bash
   # Create comprehensive key policy
   cat > kms-key-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "Enable IAM User Permissions",
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::ACCOUNT_ID:root"
         },
         "Action": "kms:*",
         "Resource": "*"
       },
       {
         "Sid": "Allow use of the key for encryption",
         "Effect": "Allow",
         "Principal": {
           "AWS": [
             "arn:aws:iam::ACCOUNT_ID:role/EC2-KMS-Role",
             "arn:aws:iam::ACCOUNT_ID:user/developer"
           ]
         },
         "Action": [
           "kms:Encrypt",
           "kms:Decrypt",
           "kms:ReEncrypt*",
           "kms:GenerateDataKey*",
           "kms:DescribeKey"
         ],
         "Resource": "*"
       },
       {
         "Sid": "Allow attachment of persistent resources",
         "Effect": "Allow",
         "Principal": {
           "AWS": [
             "arn:aws:iam::ACCOUNT_ID:role/EC2-KMS-Role"
           ]
         },
         "Action": [
           "kms:CreateGrant",
           "kms:ListGrants",
           "kms:RevokeGrant"
         ],
         "Resource": "*",
         "Condition": {
           "Bool": {
             "kms:GrantIsForAWSResource": "true"
           }
         }
       }
     ]
   }
   EOF
   
   # Apply key policy
   aws kms put-key-policy \
     --key-id $KEY_ID \
     --policy-name default \
     --policy file://kms-key-policy.json
   ```

3. **Test KMS Encryption Operations**:
   ```bash
   # Create KMS encryption test script
   cat > test_kms_encryption.py << 'EOF'
   import boto3
   import base64
   import json
   
   kms_client = boto3.client('kms')
   
   def test_direct_encryption():
       """Test direct encryption with KMS"""
       print("=== Direct KMS Encryption ===")
       
       plaintext = "This is sensitive data that needs encryption"
       key_alias = "alias/general-encryption"
       
       try:
           # Encrypt data
           encrypt_response = kms_client.encrypt(
               KeyId=key_alias,
               Plaintext=plaintext.encode('utf-8')
           )
           
           ciphertext_blob = encrypt_response['CiphertextBlob']
           key_id = encrypt_response['KeyId']
           
           print(f"Encrypted with key: {key_id}")
           print(f"Ciphertext length: {len(ciphertext_blob)} bytes")
           
           # Decrypt data
           decrypt_response = kms_client.decrypt(
               CiphertextBlob=ciphertext_blob
           )
           
           decrypted_text = decrypt_response['Plaintext'].decode('utf-8')
           decryption_key_id = decrypt_response['KeyId']
           
           print(f"Decrypted with key: {decryption_key_id}")
           print(f"Decrypted text: {decrypted_text}")
           print(f"Encryption successful: {plaintext == decrypted_text}")
           
       except Exception as e:
           print(f"Error in direct encryption: {e}")
   
   def test_data_key_generation():
       """Test data key generation for envelope encryption"""
       print(f"\n=== Data Key Generation ===")
       
       key_alias = "alias/general-encryption"
       
       try:
           # Generate data key
           response = kms_client.generate_data_key(
               KeyId=key_alias,
               KeySpec='AES_256'
           )
           
           plaintext_key = response['Plaintext']
           encrypted_key = response['CiphertextBlob']
           key_id = response['KeyId']
           
           print(f"Generated data key with CMK: {key_id}")
           print(f"Plaintext key length: {len(plaintext_key)} bytes")
           print(f"Encrypted key length: {len(encrypted_key)} bytes")
           
           # Decrypt the data key
           decrypt_response = kms_client.decrypt(
               CiphertextBlob=encrypted_key
           )
           
           decrypted_key = decrypt_response['Plaintext']
           print(f"Data key decryption successful: {plaintext_key == decrypted_key}")
           
           return plaintext_key, encrypted_key
           
       except Exception as e:
           print(f"Error generating data key: {e}")
           return None, None
   
   def test_envelope_encryption():
       """Test envelope encryption pattern"""
       print(f"\n=== Envelope Encryption ===")
       
       # Generate data key
       plaintext_key, encrypted_key = test_data_key_generation()
       
       if plaintext_key:
           # Use data key to encrypt large data
           from cryptography.fernet import Fernet
           import os
           
           # Create Fernet key from KMS data key
           fernet_key = base64.urlsafe_b64encode(plaintext_key[:32])
           fernet = Fernet(fernet_key)
           
           # Encrypt large data
           large_data = "This is a large amount of data " * 1000
           encrypted_data = fernet.encrypt(large_data.encode('utf-8'))
           
           print(f"Encrypted {len(large_data)} bytes of data")
           print(f"Encrypted data length: {len(encrypted_data)} bytes")
           
           # To decrypt: first decrypt the data key, then decrypt the data
           decrypt_response = kms_client.decrypt(CiphertextBlob=encrypted_key)
           decrypted_data_key = decrypt_response['Plaintext']
           
           fernet_key = base64.urlsafe_b64encode(decrypted_data_key[:32])
           fernet = Fernet(fernet_key)
           
           decrypted_data = fernet.decrypt(encrypted_data).decode('utf-8')
           print(f"Envelope encryption successful: {large_data == decrypted_data}")
   
   def list_kms_keys():
       """List KMS keys and their details"""
       print(f"\n=== KMS Keys Inventory ===")
       
       try:
           response = kms_client.list_keys()
           
           for key in response['Keys']:
               key_id = key['KeyId']
               
               # Get key details
               key_response = kms_client.describe_key(KeyId=key_id)
               key_metadata = key_response['KeyMetadata']
               
               print(f"\nKey ID: {key_id}")
               print(f"Description: {key_metadata.get('Description', 'N/A')}")
               print(f"Key Usage: {key_metadata['KeyUsage']}")
               print(f"Key State: {key_metadata['KeyState']}")
               print(f"Origin: {key_metadata['Origin']}")
               
               # List aliases
               aliases_response = kms_client.list_aliases(KeyId=key_id)
               if aliases_response['Aliases']:
                   aliases = [alias['AliasName'] for alias in aliases_response['Aliases']]
                   print(f"Aliases: {', '.join(aliases)}")
               
       except Exception as e:
           print(f"Error listing keys: {e}")
   
   if __name__ == "__main__":
       list_kms_keys()
       test_direct_encryption()
       test_envelope_encryption()
   EOF
   
   # Install required package and run
   pip install cryptography
   python3 test_kms_encryption.py
   ```

**Screenshot Placeholder**:
![KMS Key Management](screenshots/22-kms-encryption.png)
*Caption: KMS key creation and encryption operations*

### Practice 2: Systems Manager Parameter Store
**Objective**: Store and manage configuration data and secrets securely

**Steps**:
1. **Create Parameters**:
   ```bash
   # Create standard parameters
   aws ssm put-parameter \
     --name "/myapp/database/host" \
     --value "db.example.com" \
     --type "String" \
     --description "Database hostname"
   
   aws ssm put-parameter \
     --name "/myapp/database/port" \
     --value "5432" \
     --type "String" \
     --description "Database port"
   
   # Create encrypted parameters
   aws ssm put-parameter \
     --name "/myapp/database/password" \
     --value "super-secret-password" \
     --type "SecureString" \
     --key-id "alias/general-encryption" \
     --description "Database password"
   
   aws ssm put-parameter \
     --name "/myapp/api/key" \
     --value "api-key-12345" \
     --type "SecureString" \
     --description "API key for external service"
   
   # Create parameter with tags
   aws ssm put-parameter \
     --name "/myapp/config/debug" \
     --value "false" \
     --type "String" \
     --tags Key=Environment,Value=Production Key=Application,Value=MyApp
   ```

2. **Parameter Management Script**:
   ```bash
   # Create parameter management script
   cat > manage_parameters.py << 'EOF'
   import boto3
   import json
   from datetime import datetime
   
   ssm_client = boto3.client('ssm')
   
   def list_parameters_by_path(path):
       """List parameters by path hierarchy"""
       print(f"=== Parameters under {path} ===")
       
       try:
           paginator = ssm_client.get_paginator('get_parameters_by_path')
           
           for page in paginator.paginate(
               Path=path,
               Recursive=True,
               WithDecryption=True
           ):
               for parameter in page['Parameters']:
                   print(f"\nName: {parameter['Name']}")
                   print(f"Type: {parameter['Type']}")
                   print(f"Value: {parameter['Value']}")
                   print(f"Version: {parameter['Version']}")
                   print(f"Last Modified: {parameter['LastModifiedDate']}")
                   
       except Exception as e:
           print(f"Error listing parameters: {e}")
   
   def get_parameter_history(name):
       """Get parameter version history"""
       print(f"\n=== Parameter History for {name} ===")
       
       try:
           response = ssm_client.get_parameter_history(
               Name=name,
               WithDecryption=True
           )
           
           for param in response['Parameters']:
               print(f"Version {param['Version']}: {param['Value']}")
               print(f"  Modified: {param['LastModifiedDate']}")
               print(f"  Modified by: {param['LastModifiedUser']}")
               
       except Exception as e:
           print(f"Error getting parameter history: {e}")
   
   def create_parameter_hierarchy():
       """Create a comprehensive parameter hierarchy"""
       print("=== Creating Parameter Hierarchy ===")
       
       parameters = [
           # Application configuration
           {
               'name': '/myapp/prod/database/host',
               'value': 'prod-db.example.com',
               'type': 'String'
           },
           {
               'name': '/myapp/prod/database/username',
               'value': 'prod_user',
               'type': 'String'
           },
           {
               'name': '/myapp/prod/database/password',
               'value': 'prod-secret-password',
               'type': 'SecureString'
           },
           {
               'name': '/myapp/staging/database/host',
               'value': 'staging-db.example.com',
               'type': 'String'
           },
           {
               'name': '/myapp/staging/database/password',
               'value': 'staging-password',
               'type': 'SecureString'
           },
           # Feature flags
           {
               'name': '/myapp/features/new-ui-enabled',
               'value': 'true',
               'type': 'String'
           },
           {
               'name': '/myapp/features/beta-features',
               'value': 'false',
               'type': 'String'
           },
           # External service configurations
           {
               'name': '/myapp/external/payment-gateway/url',
               'value': 'https://api.payment.com',
               'type': 'String'
           },
           {
               'name': '/myapp/external/payment-gateway/api-key',
               'value': 'payment-api-key-12345',
               'type': 'SecureString'
           }
       ]
       
       for param in parameters:
           try:
               ssm_client.put_parameter(
                   Name=param['name'],
                   Value=param['value'],
                   Type=param['type'],
                   Overwrite=True,
                   Tags=[
                       {'Key': 'Environment', 'Value': 'Demo'},
                       {'Key': 'Application', 'Value': 'MyApp'}
                   ]
               )
               print(f"Created: {param['name']}")
               
           except Exception as e:
               print(f"Error creating {param['name']}: {e}")
   
   def bulk_parameter_operations():
       """Demonstrate bulk parameter operations"""
       print(f"\n=== Bulk Parameter Operations ===")
       
       # Get multiple parameters at once
       parameter_names = [
           '/myapp/prod/database/host',
           '/myapp/prod/database/username',
           '/myapp/prod/database/password'
       ]
       
       try:
           response = ssm_client.get_parameters(
               Names=parameter_names,
               WithDecryption=True
           )
           
           print("Retrieved parameters:")
           for param in response['Parameters']:
               print(f"  {param['Name']}: {param['Value']}")
           
           if response['InvalidParameters']:
               print(f"Invalid parameters: {response['InvalidParameters']}")
               
       except Exception as e:
           print(f"Error in bulk operations: {e}")
   
   def parameter_store_policies():
       """Demonstrate parameter store access patterns"""
       print(f"\n=== Parameter Store Access Patterns ===")
       
       # Get parameters by path with different access patterns
       paths = ['/myapp/prod', '/myapp/staging', '/myapp/features']
       
       for path in paths:
           try:
               response = ssm_client.get_parameters_by_path(
                   Path=path,
                   Recursive=True,
                   WithDecryption=False  # Don't decrypt for this demo
               )
               
               print(f"\nPath: {path}")
               print(f"Parameters found: {len(response['Parameters'])}")
               
               for param in response['Parameters']:
                   print(f"  - {param['Name']} ({param['Type']})")
                   
           except Exception as e:
               print(f"Error accessing path {path}: {e}")
   
   def cleanup_demo_parameters():
       """Clean up demo parameters"""
       print(f"\n=== Cleaning Up Demo Parameters ===")
       
       try:
           # Get all parameters under /myapp
           response = ssm_client.get_parameters_by_path(
               Path='/myapp',
               Recursive=True
           )
           
           for param in response['Parameters']:
               try:
                   ssm_client.delete_parameter(Name=param['Name'])
                   print(f"Deleted: {param['Name']}")
               except Exception as e:
                   print(f"Error deleting {param['Name']}: {e}")
                   
       except Exception as e:
           print(f"Error in cleanup: {e}")
   
   if __name__ == "__main__":
       create_parameter_hierarchy()
       list_parameters_by_path('/myapp')
       bulk_parameter_operations()
       parameter_store_policies()
       # cleanup_demo_parameters()  # Uncomment to clean up
   EOF
   
   python3 manage_parameters.py
   ```

**Screenshot Placeholder**:
![Parameter Store Management](screenshots/22-parameter-store.png)
*Caption: Systems Manager Parameter Store hierarchy and management*

### Practice 3: AWS Shield DDoS Protection
**Objective**: Configure DDoS protection and monitoring

**Steps**:
1. **Enable Shield Advanced** (Optional - has cost implications):
   ```bash
   # Enable Shield Advanced (requires subscription)
   # aws shield subscribe-to-proactive-engagement
   
   # Create CloudWatch alarms for DDoS detection
   aws cloudwatch put-metric-alarm \
     --alarm-name "DDoS-Attack-Detection" \
     --alarm-description "Detect potential DDoS attacks" \
     --metric-name DDoSDetected \
     --namespace AWS/DDoSProtection \
     --statistic Maximum \
     --period 300 \
     --threshold 1 \
     --comparison-operator GreaterThanOrEqualToThreshold \
     --evaluation-periods 1 \
     --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:ddos-alerts
   ```

2. **DDoS Monitoring Script**:
   ```bash
   # Create DDoS monitoring script
   cat > monitor_ddos.py << 'EOF'
   import boto3
   import json
   from datetime import datetime, timedelta
   
   shield_client = boto3.client('shield')
   cloudwatch_client = boto3.client('cloudwatch')
   
   def check_shield_subscription():
       """Check Shield Advanced subscription status"""
       print("=== Shield Subscription Status ===")
       
       try:
           response = shield_client.describe_subscription()
           subscription = response['Subscription']
           
           print(f"Subscription Status: {subscription['SubscriptionState']}")
           print(f"Start Time: {subscription.get('StartTime', 'N/A')}")
           print(f"End Time: {subscription.get('EndTime', 'N/A')}")
           print(f"Time Commitment: {subscription.get('TimeCommitmentInSeconds', 'N/A')} seconds")
           
           return True
           
       except shield_client.exceptions.ResourceNotFoundException:
           print("Shield Advanced subscription not found")
           print("Shield Standard is automatically enabled for all AWS customers")
           return False
       except Exception as e:
           print(f"Error checking subscription: {e}")
           return False
   
   def list_protected_resources():
       """List resources protected by Shield"""
       print(f"\n=== Protected Resources ===")
       
       try:
           response = shield_client.list_protections()
           
           if response['Protections']:
               for protection in response['Protections']:
                   print(f"\nProtection ID: {protection['Id']}")
                   print(f"Name: {protection.get('Name', 'N/A')}")
                   print(f"Resource ARN: {protection['ResourceArn']}")
                   
                   # Get protection details
                   try:
                       detail_response = shield_client.describe_protection(
                           ResourceArn=protection['ResourceArn']
                       )
                       
                       protection_detail = detail_response['Protection']
                       print(f"Health Check IDs: {protection_detail.get('HealthCheckIds', [])}")
                       
                   except Exception as e:
                       print(f"Error getting protection details: {e}")
           else:
               print("No protected resources found")
               
       except Exception as e:
           print(f"Error listing protections: {e}")
   
   def check_ddos_attacks():
       """Check for recent DDoS attacks"""
       print(f"\n=== Recent DDoS Attacks ===")
       
       try:
           end_time = datetime.utcnow()
           start_time = end_time - timedelta(days=30)
           
           response = shield_client.list_attacks(
               StartTime=start_time,
               EndTime=end_time
           )
           
           if response['AttackSummaries']:
               print(f"Found {len(response['AttackSummaries'])} attacks in the last 30 days")
               
               for attack in response['AttackSummaries']:
                   print(f"\nAttack ID: {attack['AttackId']}")
                   print(f"Resource ARN: {attack['ResourceArn']}")
                   print(f"Start Time: {attack['StartTime']}")
                   print(f"End Time: {attack.get('EndTime', 'Ongoing')}")
                   print(f"Attack Vectors: {[v['VectorType'] for v in attack.get('AttackVectors', [])]}")
                   
                   # Get attack details
                   try:
                       detail_response = shield_client.describe_attack(
                           AttackId=attack['AttackId']
                       )
                       
                       attack_detail = detail_response['Attack']
                       print(f"Attack Properties: {len(attack_detail.get('AttackProperties', []))}")
                       
                   except Exception as e:
                       print(f"Error getting attack details: {e}")
           else:
               print("No DDoS attacks detected in the last 30 days")
               
       except Exception as e:
           print(f"Error checking attacks: {e}")
   
   def get_ddos_metrics():
       """Get DDoS-related CloudWatch metrics"""
       print(f"\n=== DDoS CloudWatch Metrics ===")
       
       try:
           end_time = datetime.utcnow()
           start_time = end_time - timedelta(hours=24)
           
           # Get DDoS detection metrics
           response = cloudwatch_client.get_metric_statistics(
               Namespace='AWS/DDoSProtection',
               MetricName='DDoSDetected',
               Dimensions=[],
               StartTime=start_time,
               EndTime=end_time,
               Period=3600,
               Statistics=['Maximum']
           )
           
           if response['Datapoints']:
               print("DDoS Detection Metrics (last 24 hours):")
               for datapoint in sorted(response['Datapoints'], key=lambda x: x['Timestamp']):
                   print(f"  {datapoint['Timestamp']}: {datapoint['Maximum']}")
           else:
               print("No DDoS detection metrics found")
               
           # Get attack volume metrics for CloudFront (if available)
           try:
               cf_response = cloudwatch_client.get_metric_statistics(
                   Namespace='AWS/CloudFront',
                   MetricName='Requests',
                   Dimensions=[
                       {'Name': 'DistributionId', 'Value': 'YOUR_DISTRIBUTION_ID'}
                   ],
                   StartTime=start_time,
                   EndTime=end_time,
                   Period=3600,
                   Statistics=['Sum']
               )
               
               if cf_response['Datapoints']:
                   print("\nCloudFront Request Volume:")
                   for datapoint in sorted(cf_response['Datapoints'], key=lambda x: x['Timestamp']):
                       print(f"  {datapoint['Timestamp']}: {datapoint['Sum']} requests")
                       
           except Exception as e:
               print(f"CloudFront metrics not available: {e}")
               
       except Exception as e:
           print(f"Error getting metrics: {e}")
   
   def create_ddos_response_plan():
       """Create DDoS response plan documentation"""
       print(f"\n=== DDoS Response Plan ===")
       
       response_plan = {
           "detection": [
               "Monitor CloudWatch alarms for unusual traffic patterns",
               "Check Shield Advanced dashboard for attack notifications",
               "Review application performance metrics"
           ],
           "immediate_response": [
               "Verify if traffic is legitimate or attack",
               "Scale resources if needed to handle legitimate traffic",
               "Contact AWS Support if Shield Advanced is enabled"
           ],
           "mitigation": [
               "Enable additional CloudFront distributions",
               "Implement rate limiting with AWS WAF",
               "Use Route 53 health checks for failover"
           ],
           "post_incident": [
               "Review attack patterns and update defenses",
               "Document lessons learned",
               "Update monitoring and alerting thresholds"
           ]
         }
       
       print("DDoS Response Plan:")
       for phase, actions in response_plan.items():
           print(f"\n{phase.upper()}:")
           for action in actions:
               print(f"  - {action}")
   
   if __name__ == "__main__":
       has_shield_advanced = check_shield_subscription()
       list_protected_resources()
       check_ddos_attacks()
       get_ddos_metrics()
       create_ddos_response_plan()
   EOF
   
   python3 monitor_ddos.py
   ```

**Screenshot Placeholder**:
![Shield DDoS Protection](screenshots/22-shield-protection.png)
*Caption: AWS Shield DDoS protection monitoring and response*

### Practice 4: AWS WAF Web Application Firewall
**Objective**: Configure WAF rules to protect web applications

**Steps**:
1. **Create WAF Web ACL**:
   ```bash
   # Create IP set for blocked IPs
   aws wafv2 create-ip-set \
     --name "BlockedIPs" \
     --scope CLOUDFRONT \
     --ip-address-version IPV4 \
     --addresses "192.0.2.0/24" "203.0.113.0/24" \
     --description "IP addresses to block"
   
   # Create regex pattern set
   aws wafv2 create-regex-pattern-set \
     --name "SQLInjectionPatterns" \
     --scope CLOUDFRONT \
     --regular-expression-list "(?i)(union|select|insert|delete|drop|create|alter|exec)" \
     --description "SQL injection patterns"
   ```

2. **Create WAF Rules**:
   ```bash
   # Create comprehensive WAF configuration
   cat > waf_rules.py << 'EOF'
   import boto3
   import json
   
   wafv2_client = boto3.client('wafv2')
   
   def create_web_acl():
       """Create WAF Web ACL with comprehensive rules"""
       print("=== Creating WAF Web ACL ===")
       
       # Define rules
       rules = [
           {
               "Name": "AWSManagedRulesCommonRuleSet",
               "Priority": 1,
               "OverrideAction": {"None": {}},
               "Statement": {
                   "ManagedRuleGroupStatement": {
                       "VendorName": "AWS",
                       "Name": "AWSManagedRulesCommonRuleSet"
                   }
               },
               "VisibilityConfig": {
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "CommonRuleSetMetric"
               }
           },
           {
               "Name": "AWSManagedRulesKnownBadInputsRuleSet",
               "Priority": 2,
               "OverrideAction": {"None": {}},
               "Statement": {
                   "ManagedRuleGroupStatement": {
                       "VendorName": "AWS",
                       "Name": "AWSManagedRulesKnownBadInputsRuleSet"
                   }
               },
               "VisibilityConfig": {
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "KnownBadInputsMetric"
               }
           },
           {
               "Name": "RateLimitRule",
               "Priority": 3,
               "Action": {"Block": {}},
               "Statement": {
                   "RateBasedStatement": {
                       "Limit": 2000,
                       "AggregateKeyType": "IP"
                   }
               },
               "VisibilityConfig": {
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "RateLimitMetric"
               }
           },
           {
               "Name": "BlockSpecificCountries",
               "Priority": 4,
               "Action": {"Block": {}},
               "Statement": {
                   "GeoMatchStatement": {
                       "CountryCodes": ["CN", "RU", "KP"]
                   }
               },
               "VisibilityConfig": {
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "GeoBlockMetric"
               }
           }
       ]
       
       try:
           response = wafv2_client.create_web_acl(
               Name="MyWebApplicationFirewall",
               Scope="CLOUDFRONT",
               DefaultAction={"Allow": {}},
               Description="Comprehensive WAF for web application protection",
               Rules=rules,
               VisibilityConfig={
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "MyWebACLMetric"
               },
               Tags=[
                   {"Key": "Environment", "Value": "Production"},
                   {"Key": "Application", "Value": "WebApp"}
               ]
           )
           
           web_acl_arn = response['Summary']['ARN']
           web_acl_id = response['Summary']['Id']
           
           print(f"Created Web ACL: {web_acl_id}")
           print(f"Web ACL ARN: {web_acl_arn}")
           
           return web_acl_id, web_acl_arn
           
       except Exception as e:
           print(f"Error creating Web ACL: {e}")
           return None, None
   
   def create_custom_rule_group():
       """Create custom rule group for specific application needs"""
       print(f"\n=== Creating Custom Rule Group ===")
       
       rules = [
           {
               "Name": "BlockSQLInjection",
               "Priority": 1,
               "Action": {"Block": {}},
               "Statement": {
                   "ByteMatchStatement": {
                       "SearchString": "union select",
                       "FieldToMatch": {"Body": {}},
                       "TextTransformations": [
                           {"Priority": 0, "Type": "LOWERCASE"}
                       ],
                       "PositionalConstraint": "CONTAINS"
                   }
               },
               "VisibilityConfig": {
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "SQLInjectionBlocks"
               }
           },
           {
               "Name": "BlockXSS",
               "Priority": 2,
               "Action": {"Block": {}},
               "Statement": {
                   "XssMatchStatement": {
                       "FieldToMatch": {"AllQueryArguments": {}},
                       "TextTransformations": [
                           {"Priority": 0, "Type": "URL_DECODE"},
                           {"Priority": 1, "Type": "HTML_ENTITY_DECODE"}
                       ]
                   }
               },
               "VisibilityConfig": {
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "XSSBlocks"
               }
           }
       ]
       
       try:
           response = wafv2_client.create_rule_group(
               Name="CustomApplicationRules",
               Scope="CLOUDFRONT",
               Capacity=100,
               Description="Custom rules for application-specific protection",
               Rules=rules,
               VisibilityConfig={
                   "SampledRequestsEnabled": True,
                   "CloudWatchMetricsEnabled": True,
                   "MetricName": "CustomRuleGroupMetric"
               }
           )
           
           rule_group_arn = response['Summary']['ARN']
           print(f"Created Rule Group: {rule_group_arn}")
           
           return rule_group_arn
           
       except Exception as e:
           print(f"Error creating rule group: {e}")
           return None
   
   def list_web_acls():
       """List existing Web ACLs"""
       print(f"\n=== Existing Web ACLs ===")
       
       try:
           response = wafv2_client.list_web_acls(Scope="CLOUDFRONT")
           
           for web_acl in response['WebACLs']:
               print(f"\nName: {web_acl['Name']}")
               print(f"ID: {web_acl['Id']}")
               print(f"ARN: {web_acl['ARN']}")
               print(f"Description: {web_acl.get('Description', 'N/A')}")
               
               # Get detailed information
               try:
                   detail_response = wafv2_client.get_web_acl(
                       Name=web_acl['Name'],
                       Scope="CLOUDFRONT",
                       Id=web_acl['Id']
                   )
                   
                   web_acl_detail = detail_response['WebACL']
                   print(f"Rules: {len(web_acl_detail['Rules'])}")
                   print(f"Default Action: {list(web_acl_detail['DefaultAction'].keys())[0]}")
                   
               except Exception as e:
                   print(f"Error getting Web ACL details: {e}")
                   
       except Exception as e:
           print(f"Error listing Web ACLs: {e}")
   
   def get_waf_metrics():
       """Get WAF CloudWatch metrics"""
       print(f"\n=== WAF Metrics ===")
       
       cloudwatch = boto3.client('cloudwatch')
       
       try:
           from datetime import datetime, timedelta
           
           end_time = datetime.utcnow()
           start_time = end_time - timedelta(hours=24)
           
           # Get blocked requests metric
           response = cloudwatch.get_metric_statistics(
               Namespace='AWS/WAFV2',
               MetricName='BlockedRequests',
               Dimensions=[
                   {'Name': 'WebACL', 'Value': 'MyWebApplicationFirewall'},
                   {'Name': 'Region', 'Value': 'CloudFront'}
               ],
               StartTime=start_time,
               EndTime=end_time,
               Period=3600,
               Statistics=['Sum']
           )
           
           if response['Datapoints']:
               print("Blocked Requests (last 24 hours):")
               for datapoint in sorted(response['Datapoints'], key=lambda x: x['Timestamp']):
                   print(f"  {datapoint['Timestamp']}: {datapoint['Sum']} requests")
           else:
               print("No blocked requests metrics found")
               
           # Get allowed requests metric
           response = cloudwatch.get_metric_statistics(
               Namespace='AWS/WAFV2',
               MetricName='AllowedRequests',
               Dimensions=[
                   {'Name': 'WebACL', 'Value': 'MyWebApplicationFirewall'},
                   {'Name': 'Region', 'Value': 'CloudFront'}
               ],
               StartTime=start_time,
               EndTime=end_time,
               Period=3600,
               Statistics=['Sum']
           )
           
           if response['Datapoints']:
               print("\nAllowed Requests (last 24 hours):")
               for datapoint in sorted(response['Datapoints'], key=lambda x: x['Timestamp']):
                   print(f"  {datapoint['Timestamp']}: {datapoint['Sum']} requests")
                   
       except Exception as e:
           print(f"Error getting WAF metrics: {e}")
   
   if __name__ == "__main__":
       list_web_acls()
       web_acl_id, web_acl_arn = create_web_acl()
       rule_group_arn = create_custom_rule_group()
       get_waf_metrics()
   EOF
   
   python3 waf_rules.py
   ```

3. **WAF Testing and Monitoring**:
   ```bash
   # Create WAF testing script
   cat > test_waf_rules.py << 'EOF'
   import boto3
   import requests
   import time
   import json
   
   def test_waf_rules():
       """Test WAF rules with various attack patterns"""
       print("=== Testing WAF Rules ===")
       
       # Test URL (replace with your actual CloudFront distribution)
       base_url = "https://your-distribution.cloudfront.net"
       
       test_cases = [
           {
               "name": "Normal Request",
               "url": f"{base_url}/",
               "expected": "allowed"
           },
           {
               "name": "SQL Injection Attempt",
               "url": f"{base_url}/search?q=1' UNION SELECT * FROM users--",
               "expected": "blocked"
           },
           {
               "name": "XSS Attempt",
               "url": f"{base_url}/comment?text=<script>alert('xss')</script>",
               "expected": "blocked"
           },
           {
               "name": "Rate Limit Test",
               "url": f"{base_url}/api/data",
               "requests": 50,
               "expected": "rate_limited"
           }
       ]
       
       for test_case in test_cases:
           print(f"\nTesting: {test_case['name']}")
           
           try:
               if test_case.get('requests'):
                   # Rate limit test
                   for i in range(test_case['requests']):
                       response = requests.get(test_case['url'], timeout=5)
                       if response.status_code == 403:
                           print(f"  Request {i+1}: Blocked (403)")
                           break
                       else:
                           print(f"  Request {i+1}: Allowed ({response.status_code})")
                       time.sleep(0.1)
               else:
                   # Single request test
                   response = requests.get(test_case['url'], timeout=5)
                   
                   if response.status_code == 403:
                       print(f"  Result: Blocked (403) - Expected: {test_case['expected']}")
                   elif response.status_code == 200:
                       print(f"  Result: Allowed (200) - Expected: {test_case['expected']}")
                   else:
                       print(f"  Result: Unexpected ({response.status_code})")
                       
           except requests.exceptions.RequestException as e:
               print(f"  Error: {e}")
   
   def analyze_waf_logs():
       """Analyze WAF logs for patterns"""
       print(f"\n=== WAF Log Analysis ===")
       
       # This would typically read from S3 where WAF logs are stored
       # For demo purposes, we'll show the structure
       
       sample_log_entry = {
           "timestamp": 1609459200000,
           "formatVersion": 1,
           "webaclId": "arn:aws:wafv2:us-east-1:123456789012:global/webacl/MyWebACL/12345",
           "terminatingRuleId": "RateLimitRule",
           "terminatingRuleType": "RATE_BASED",
           "action": "BLOCK",
           "httpSourceName": "CF",
           "httpSourceId": "E1234567890123",
           "ruleGroupList": [],
           "rateBasedRuleList": [
               {
                   "rateBasedRuleId": "RateLimitRule",
                   "limitKey": "IP",
                   "maxRateAllowed": 2000
               }
           ],
           "nonTerminatingMatchingRules": [],
           "httpRequest": {
               "clientIp": "192.0.2.1",
               "country": "US",
               "headers": [
                   {"name": "host", "value": "example.com"},
                   {"name": "user-agent", "value": "Mozilla/5.0..."}
               ],
               "uri": "/api/data",
               "args": "param=value",
               "httpVersion": "HTTP/1.1",
               "httpMethod": "GET",
               "requestId": "12345-67890-abcdef"
           }
       }
       
       print("Sample WAF log entry structure:")
       print(json.dumps(sample_log_entry, indent=2))
       
       # Analysis patterns
       analysis_queries = [
           "Top blocked IPs",
           "Most triggered rules",
           "Geographic distribution of attacks",
           "Attack patterns over time",
           "False positive analysis"
       ]
       
       print(f"\nRecommended log analysis queries:")
       for query in analysis_queries:
           print(f"  - {query}")
   
   if __name__ == "__main__":
       print("WAF Testing Script")
       print("Note: Replace base_url with your actual CloudFront distribution")
       # test_waf_rules()  # Uncomment when you have a real endpoint
       analyze_waf_logs()
   EOF
   
   python3 test_waf_rules.py
   ```

**Screenshot Placeholder**:
![WAF Configuration](screenshots/22-waf-rules.png)
*Caption: AWS WAF web application firewall rules and monitoring*

## ✅ Section Completion Checklist

- [ ] Created and managed KMS customer managed keys
- [ ] Implemented envelope encryption patterns
- [ ] Set up Parameter Store hierarchy for configuration management
- [ ] Configured encrypted parameters with KMS integration
- [ ] Enabled Shield DDoS protection monitoring
- [ ] Created comprehensive WAF rules for web application protection
- [ ] Tested security controls and monitoring
- [ ] Implemented security incident response procedures
- [ ] Set up CloudWatch alarms for security events

## 🎯 Key Takeaways

- **KMS**: Centralized key management for encryption across AWS services
- **Parameter Store**: Secure configuration and secrets management
- **Shield**: Automatic DDoS protection with advanced monitoring options
- **WAF**: Comprehensive web application firewall with managed and custom rules
- **Defense in Depth**: Layer multiple security controls for comprehensive protection
- **Monitoring**: Continuous monitoring and alerting for security events
- **Automation**: Automate security responses and remediation where possible
- **Compliance**: Meet regulatory requirements with proper encryption and auditing

## 📚 Additional Resources

- [AWS KMS Developer Guide](https://docs.aws.amazon.com/kms/)
- [Systems Manager Parameter Store User Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [AWS Shield Advanced Guide](https://docs.aws.amazon.com/waf/latest/developerguide/shield-chapter.html)
- [AWS WAF Developer Guide](https://docs.aws.amazon.com/waf/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)