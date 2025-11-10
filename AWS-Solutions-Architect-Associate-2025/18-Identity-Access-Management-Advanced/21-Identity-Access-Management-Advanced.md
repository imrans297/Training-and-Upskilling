# Section 21: Identity and Access Management Advanced

## 📋 Overview
This section covers advanced IAM concepts including cross-account access, identity federation, advanced policies, and enterprise identity integration.

## 🔐 Advanced IAM Concepts

### Cross-Account Access
- **Assume Role**: Cross-account resource access
- **Resource-based policies**: Direct resource permissions
- **External ID**: Additional security for third-party access
- **Trust relationships**: Define who can assume roles
- **Account boundaries**: Isolate environments and workloads

### Identity Federation
- **SAML 2.0**: Enterprise identity provider integration
- **OpenID Connect**: Web identity federation
- **AWS SSO**: Centralized access management
- **Active Directory**: On-premises directory integration
- **Temporary credentials**: Short-lived access tokens

### Advanced Policy Features
- **Policy conditions**: Context-based access control
- **Policy variables**: Dynamic policy evaluation
- **Permission boundaries**: Maximum permissions for entities
- **Service control policies**: Organization-wide guardrails
- **Access analyzer**: Identify unintended access

## 🛠️ Hands-On Practice

### Practice 1: Cross-Account Role Access
**Objective**: Set up secure cross-account access using IAM roles

**Steps**:
1. **Create Cross-Account Role**:
   ```bash
   # Account A (Resource Account) - Create role for Account B
   cat > cross-account-trust-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::ACCOUNT_B_ID:root"
         },
         "Action": "sts:AssumeRole",
         "Condition": {
           "StringEquals": {
             "sts:ExternalId": "unique-external-id-12345"
           },
           "IpAddress": {
             "aws:SourceIp": ["203.0.113.0/24", "198.51.100.0/24"]
           }
         }
       }
     ]
   }
   EOF
   
   # Create cross-account role
   aws iam create-role \
     --role-name CrossAccountS3AccessRole \
     --assume-role-policy-document file://cross-account-trust-policy.json \
     --description "Role for cross-account S3 access"
   
   # Create permission policy for the role
   cat > s3-access-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::shared-bucket-12345",
           "arn:aws:s3:::shared-bucket-12345/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetBucketLocation",
           "s3:ListAllMyBuckets"
         ],
         "Resource": "*"
       }
     ]
   }
   EOF
   
   # Attach policy to role
   aws iam put-role-policy \
     --role-name CrossAccountS3AccessRole \
     --policy-name S3AccessPolicy \
     --policy-document file://s3-access-policy.json
   ```

2. **Test Cross-Account Access**:
   ```bash
   # Account B - Create script to assume role and access resources
   cat > assume_cross_account_role.py << 'EOF'
   import boto3
   import json
   from datetime import datetime
   
   def assume_cross_account_role():
       """Assume role in another account"""
       sts_client = boto3.client('sts')
       
       try:
           response = sts_client.assume_role(
               RoleArn='arn:aws:iam::ACCOUNT_A_ID:role/CrossAccountS3AccessRole',
               RoleSessionName='CrossAccountSession',
               ExternalId='unique-external-id-12345',
               DurationSeconds=3600
           )
           
           credentials = response['Credentials']
           
           print("Successfully assumed cross-account role!")
           print(f"Access Key: {credentials['AccessKeyId']}")
           print(f"Session expires: {credentials['Expiration']}")
           
           return credentials
           
       except Exception as e:
           print(f"Error assuming role: {e}")
           return None
   
   def test_s3_access(credentials):
       """Test S3 access with assumed role credentials"""
       s3_client = boto3.client(
           's3',
           aws_access_key_id=credentials['AccessKeyId'],
           aws_secret_access_key=credentials['SecretAccessKey'],
           aws_session_token=credentials['SessionToken']
       )
       
       bucket_name = 'shared-bucket-12345'
       
       try:
           # List bucket contents
           response = s3_client.list_objects_v2(Bucket=bucket_name)
           print(f"\nBucket contents ({bucket_name}):")
           
           if 'Contents' in response:
               for obj in response['Contents']:
                   print(f"- {obj['Key']} ({obj['Size']} bytes)")
           else:
               print("Bucket is empty")
           
           # Upload test file
           test_content = f"Cross-account access test - {datetime.now().isoformat()}"
           s3_client.put_object(
               Bucket=bucket_name,
               Key='cross-account-test.txt',
               Body=test_content.encode('utf-8')
           )
           print(f"\nUploaded test file to {bucket_name}")
           
           # Download and verify
           response = s3_client.get_object(
               Bucket=bucket_name,
               Key='cross-account-test.txt'
           )
           content = response['Body'].read().decode('utf-8')
           print(f"Downloaded content: {content}")
           
       except Exception as e:
           print(f"Error accessing S3: {e}")
   
   if __name__ == "__main__":
       credentials = assume_cross_account_role()
       if credentials:
           test_s3_access(credentials)
   EOF
   
   # Update with actual account IDs and run
   python3 assume_cross_account_role.py
   ```

**Screenshot Placeholder**:
![Cross-Account Role Access](screenshots/21-cross-account-access.png)
*Caption: Cross-account IAM role setup and testing*

### Practice 2: SAML Federation Setup
**Objective**: Configure SAML-based identity federation for enterprise users

**Steps**:
1. **Create SAML Identity Provider**:
   ```bash
   # Create SAML metadata document (simplified example)
   cat > saml-metadata.xml << 'EOF'
   <?xml version="1.0" encoding="UTF-8"?>
   <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" 
                        entityID="https://example-idp.com">
     <md:IDPSSODescriptor WantAuthnRequestsSigned="false" 
                          protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
       <md:KeyDescriptor use="signing">
         <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
           <ds:X509Data>
             <ds:X509Certificate>
               MIICXjCCAcegAwIBAgIJAKS0yiqVrJejMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
               BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
               aWRnaXRzIFB0eSBMdGQwHhcNMTQwNzE0MTAyODUyWhcNMTUwNzE0MTAyODUyWjBF
               MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
               ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
               gQDYK8imMuRi/03z0K1Zi0WnvfFHvwlYeyK9Na6XJYaUoIDAtB92kWdGMdAQhLci
               HnAjkXLI6W15OoV3gA/ElRZ1xUpxTMhjP6PyY5wqT5r6y8FxbiiFKKAnHmUcrgfV
               W28tQ+0rkLGMryRtrukXOgXBv7gcrmU7G1jC2a7WqmeI8QIDAQABo1AwTjAdBgNV
               HQ4EFgQUi3XVrMsIvg4fZbf6Vr5sp3Xaha8wHwYDVR0jBBgwFoAUi3XVrMsIvg4f
               Zbf6Vr5sp3Xaha8wDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQA76Hht
               ZfPsw0wzLRwjskiM5T4ilO6EWLuTgOOk0Q0XrYV4eTM0YU2yNaAI1h90gJqp2NqL
               q0D6apTQ9PoP4ZMsZL0u8XBh7Vh6DYJmKjOGLzVVBRlWfz5C9p5nDUFMQIiT4dFr
               LEcNcDlZxC5EyO4VkQjmFg7Z3InzqRXaK2HiDg==
             </ds:X509Certificate>
           </ds:X509Data>
         </ds:KeyInfo>
       </md:KeyDescriptor>
       <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" 
                               Location="https://example-idp.com/sso"/>
     </md:IDPSSODescriptor>
   </md:EntityDescriptor>
   EOF
   
   # Create SAML identity provider
   aws iam create-saml-provider \
     --name ExampleSAMLProvider \
     --saml-metadata-document file://saml-metadata.xml
   ```

2. **Create SAML Role**:
   ```bash
   # Create trust policy for SAML role
   cat > saml-trust-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::ACCOUNT_ID:saml-provider/ExampleSAMLProvider"
         },
         "Action": "sts:AssumeRoleWithSAML",
         "Condition": {
           "StringEquals": {
             "SAML:aud": "https://signin.aws.amazon.com/saml"
           },
           "ForAllValues:StringLike": {
             "SAML:edupersonaffiliation": ["employee", "contractor"]
           }
         }
       }
     ]
   }
   EOF
   
   # Create SAML role
   aws iam create-role \
     --role-name SAMLDeveloperRole \
     --assume-role-policy-document file://saml-trust-policy.json
   
   # Attach permissions policy
   aws iam attach-role-policy \
     --role-name SAMLDeveloperRole \
     --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
   ```

3. **Test SAML Authentication**:
   ```bash
   # Create SAML assertion handler
   cat > saml_auth_test.py << 'EOF'
   import boto3
   import base64
   import xml.etree.ElementTree as ET
   from datetime import datetime, timedelta
   
   def create_sample_saml_assertion():
       """Create a sample SAML assertion for testing"""
       # This is a simplified example - in practice, this comes from your IdP
       assertion_template = '''
       <saml2:Assertion xmlns:saml2="urn:oasis:names:tc:SAML:2.0:assertion"
                        ID="id123456789"
                        IssueInstant="{issue_instant}"
                        Version="2.0">
         <saml2:Issuer>https://example-idp.com</saml2:Issuer>
         <saml2:Subject>
           <saml2:NameID Format="urn:oasis:names:tc:SAML:2.0:nameid-format:persistent">
             user@example.com
           </saml2:NameID>
           <saml2:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
             <saml2:SubjectConfirmationData NotOnOrAfter="{not_on_or_after}"
                                            Recipient="https://signin.aws.amazon.com/saml"/>
           </saml2:SubjectConfirmation>
         </saml2:Subject>
         <saml2:AttributeStatement>
           <saml2:Attribute Name="https://aws.amazon.com/SAML/Attributes/Role">
             <saml2:AttributeValue>
               arn:aws:iam::ACCOUNT_ID:role/SAMLDeveloperRole,arn:aws:iam::ACCOUNT_ID:saml-provider/ExampleSAMLProvider
             </saml2:AttributeValue>
           </saml2:Attribute>
           <saml2:Attribute Name="https://aws.amazon.com/SAML/Attributes/RoleSessionName">
             <saml2:AttributeValue>SAMLUser</saml2:AttributeValue>
           </saml2:Attribute>
           <saml2:Attribute Name="edupersonaffiliation">
             <saml2:AttributeValue>employee</saml2:AttributeValue>
           </saml2:Attribute>
         </saml2:AttributeStatement>
       </saml2:Assertion>
       '''
       
       issue_instant = datetime.utcnow().isoformat() + 'Z'
       not_on_or_after = (datetime.utcnow() + timedelta(hours=1)).isoformat() + 'Z'
       
       assertion = assertion_template.format(
           issue_instant=issue_instant,
           not_on_or_after=not_on_or_after
       )
       
       return base64.b64encode(assertion.encode('utf-8')).decode('utf-8')
   
   def assume_role_with_saml(saml_assertion):
       """Assume role using SAML assertion"""
       sts_client = boto3.client('sts')
       
       try:
           response = sts_client.assume_role_with_saml(
               RoleArn='arn:aws:iam::ACCOUNT_ID:role/SAMLDeveloperRole',
               PrincipalArn='arn:aws:iam::ACCOUNT_ID:saml-provider/ExampleSAMLProvider',
               SAMLAssertion=saml_assertion
           )
           
           credentials = response['Credentials']
           assumed_role_user = response['AssumedRoleUser']
           
           print("Successfully assumed role with SAML!")
           print(f"Assumed Role User: {assumed_role_user['AssumedRoleId']}")
           print(f"Session expires: {credentials['Expiration']}")
           
           return credentials
           
       except Exception as e:
           print(f"Error assuming role with SAML: {e}")
           return None
   
   def test_federated_access(credentials):
       """Test access with federated credentials"""
       # Create EC2 client with federated credentials
       ec2_client = boto3.client(
           'ec2',
           aws_access_key_id=credentials['AccessKeyId'],
           aws_secret_access_key=credentials['SecretAccessKey'],
           aws_session_token=credentials['SessionToken']
       )
       
       try:
           # Test EC2 access
           response = ec2_client.describe_instances()
           print(f"\nEC2 Instances: {len(response['Reservations'])} reservations found")
           
           # Test S3 access
           s3_client = boto3.client(
               's3',
               aws_access_key_id=credentials['AccessKeyId'],
               aws_secret_access_key=credentials['SecretAccessKey'],
               aws_session_token=credentials['SessionToken']
           )
           
           response = s3_client.list_buckets()
           print(f"S3 Buckets: {len(response['Buckets'])} buckets accessible")
           
       except Exception as e:
           print(f"Error testing federated access: {e}")
   
   if __name__ == "__main__":
       # Note: This is a simplified example
       # In practice, SAML assertions come from your identity provider
       print("Creating sample SAML assertion...")
       saml_assertion = create_sample_saml_assertion()
       
       print("Attempting to assume role with SAML...")
       credentials = assume_role_with_saml(saml_assertion)
       
       if credentials:
           test_federated_access(credentials)
   EOF
   
   # Note: Update ACCOUNT_ID and run (this is a demonstration)
   echo "SAML federation setup completed. Update account ID in script to test."
   ```

**Screenshot Placeholder**:
![SAML Federation](screenshots/21-saml-federation.png)
*Caption: SAML identity federation configuration and testing*

### Practice 3: Advanced IAM Policies
**Objective**: Create sophisticated IAM policies with conditions and variables

**Steps**:
1. **Time-Based Access Policy**:
   ```bash
   # Create time-based access policy
   cat > time-based-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:DescribeInstances",
           "ec2:StartInstances",
           "ec2:StopInstances"
         ],
         "Resource": "*",
         "Condition": {
           "DateGreaterThan": {
             "aws:CurrentTime": "08:00Z"
           },
           "DateLessThan": {
             "aws:CurrentTime": "18:00Z"
           },
           "ForAllValues:StringEquals": {
             "aws:RequestedRegion": ["us-east-1", "us-west-2"]
           }
         }
       },
       {
         "Effect": "Deny",
         "Action": "*",
         "Resource": "*",
         "Condition": {
           "DateGreaterThan": {
             "aws:CurrentTime": "18:00Z"
           }
         }
       }
     ]
   }
   EOF
   ```

2. **Dynamic Resource Access Policy**:
   ```bash
   # Create policy with dynamic resource access based on user attributes
   cat > dynamic-resource-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject"
         ],
         "Resource": "arn:aws:s3:::company-data/${aws:username}/*",
         "Condition": {
           "StringEquals": {
             "s3:x-amz-server-side-encryption": "AES256"
           }
         }
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:ListBucket"
         ],
         "Resource": "arn:aws:s3:::company-data",
         "Condition": {
           "StringLike": {
             "s3:prefix": "${aws:username}/*"
           }
         }
       },
       {
         "Effect": "Allow",
         "Action": [
           "ec2:DescribeInstances",
           "ec2:StartInstances",
           "ec2:StopInstances"
         ],
         "Resource": "*",
         "Condition": {
           "StringEquals": {
             "ec2:ResourceTag/Owner": "${aws:username}"
           }
         }
       }
     ]
   }
   EOF
   ```

3. **IP and MFA-Based Policy**:
   ```bash
   # Create policy requiring MFA and IP restrictions
   cat > mfa-ip-policy.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "iam:GetUser",
           "iam:ListMFADevices",
           "iam:GetAccountSummary"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": "*",
         "Resource": "*",
         "Condition": {
           "Bool": {
             "aws:MultiFactorAuthPresent": "true"
           },
           "IpAddress": {
             "aws:SourceIp": [
               "203.0.113.0/24",
               "198.51.100.0/24"
             ]
           },
           "NumericLessThan": {
             "aws:MultiFactorAuthAge": "3600"
           }
         }
       },
       {
         "Effect": "Deny",
         "Action": [
           "iam:DeleteUser",
           "iam:DeleteRole",
           "iam:DeletePolicy"
         ],
         "Resource": "*",
         "Condition": {
           "Bool": {
             "aws:MultiFactorAuthPresent": "false"
           }
         }
       }
     ]
   }
   EOF
   ```

4. **Test Policy Conditions**:
   ```bash
   # Create policy testing script
   cat > test_policy_conditions.py << 'EOF'
   import boto3
   import json
   from datetime import datetime
   
   def test_policy_simulator():
       """Test policies using IAM Policy Simulator"""
       iam_client = boto3.client('iam')
       
       # Test time-based policy
       print("=== Testing Time-Based Policy ===")
       
       try:
           response = iam_client.simulate_principal_policy(
               PolicySourceArn='arn:aws:iam::ACCOUNT_ID:user/testuser',
               ActionNames=['ec2:StartInstances'],
               ResourceArns=['*'],
               ContextEntries=[
                   {
                       'ContextKeyName': 'aws:CurrentTime',
                       'ContextKeyValues': ['2024-01-15T10:00:00Z'],
                       'ContextKeyType': 'date'
                   }
               ]
           )
           
           for result in response['EvaluationResults']:
               print(f"Action: {result['EvalActionName']}")
               print(f"Decision: {result['EvalDecision']}")
               if result.get('MatchedStatements'):
                   for statement in result['MatchedStatements']:
                       print(f"Matched Statement: {statement}")
               
       except Exception as e:
           print(f"Error testing policy: {e}")
   
   def analyze_policy_permissions():
       """Analyze policy permissions and conditions"""
       policies = [
           'time-based-policy.json',
           'dynamic-resource-policy.json',
           'mfa-ip-policy.json'
       ]
       
       for policy_file in policies:
           print(f"\n=== Analyzing {policy_file} ===")
           
           try:
               with open(policy_file, 'r') as f:
                   policy = json.load(f)
               
               for i, statement in enumerate(policy['Statement']):
                   print(f"\nStatement {i + 1}:")
                   print(f"Effect: {statement['Effect']}")
                   print(f"Actions: {statement.get('Action', 'N/A')}")
                   print(f"Resources: {statement.get('Resource', 'N/A')}")
                   
                   if 'Condition' in statement:
                       print("Conditions:")
                       for condition_type, conditions in statement['Condition'].items():
                           print(f"  {condition_type}:")
                           for key, values in conditions.items():
                               print(f"    {key}: {values}")
                               
           except FileNotFoundError:
               print(f"Policy file {policy_file} not found")
           except Exception as e:
               print(f"Error analyzing policy: {e}")
   
   def check_policy_variables():
       """Check for policy variables usage"""
       print("\n=== Policy Variables Analysis ===")
       
       variables_found = {
           '${aws:username}': 'Dynamic username-based access',
           '${aws:userid}': 'User ID-based access',
           '${aws:PrincipalTag/Department}': 'Tag-based access control',
           '${aws:RequestedRegion}': 'Region-based restrictions',
           '${aws:SourceIp}': 'IP-based access control'
       }
       
       try:
           with open('dynamic-resource-policy.json', 'r') as f:
               policy_content = f.read()
               
           for variable, description in variables_found.items():
               if variable in policy_content:
                   print(f"✓ Found: {variable} - {description}")
               else:
                   print(f"✗ Not found: {variable}")
                   
       except Exception as e:
           print(f"Error checking variables: {e}")
   
   if __name__ == "__main__":
       analyze_policy_permissions()
       check_policy_variables()
       # test_policy_simulator()  # Uncomment to test with actual resources
   EOF
   
   python3 test_policy_conditions.py
   ```

**Screenshot Placeholder**:
![Advanced IAM Policies](screenshots/21-advanced-policies.png)
*Caption: Advanced IAM policies with conditions and variables*

### Practice 4: Permission Boundaries
**Objective**: Implement permission boundaries for maximum security

**Steps**:
1. **Create Permission Boundary**:
   ```bash
   # Create permission boundary policy
   cat > permission-boundary.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:*",
           "ec2:Describe*",
           "ec2:StartInstances",
           "ec2:StopInstances",
           "ec2:RebootInstances",
           "rds:Describe*",
           "rds:StartDBInstance",
           "rds:StopDBInstance",
           "lambda:*",
           "logs:*",
           "cloudwatch:*"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": [
           "iam:GetRole",
           "iam:GetRolePolicy",
           "iam:ListRolePolicies",
           "iam:ListAttachedRolePolicies"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Deny",
         "Action": [
           "iam:CreateUser",
           "iam:DeleteUser",
           "iam:CreateRole",
           "iam:DeleteRole",
           "iam:AttachUserPolicy",
           "iam:DetachUserPolicy",
           "iam:PutUserPolicy",
           "iam:DeleteUserPolicy"
         ],
         "Resource": "*"
       },
       {
         "Effect": "Deny",
         "Action": [
           "ec2:TerminateInstances",
           "rds:DeleteDBInstance",
           "s3:DeleteBucket"
         ],
         "Resource": "*"
       }
     ]
   }
   EOF
   
   # Create permission boundary policy
   aws iam create-policy \
     --policy-name DeveloperPermissionBoundary \
     --policy-document file://permission-boundary.json \
     --description "Permission boundary for developer users"
   ```

2. **Create User with Permission Boundary**:
   ```bash
   # Create user with permission boundary
   aws iam create-user \
     --user-name developer-user \
     --permissions-boundary arn:aws:iam::ACCOUNT_ID:policy/DeveloperPermissionBoundary
   
   # Create broad permissions policy for the user
   cat > developer-permissions.json << 'EOF'
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": "*",
         "Resource": "*"
       }
     ]
   }
   EOF
   
   # Attach broad policy to user (will be limited by permission boundary)
   aws iam put-user-policy \
     --user-name developer-user \
     --policy-name DeveloperPolicy \
     --policy-document file://developer-permissions.json
   ```

3. **Test Permission Boundaries**:
   ```bash
   # Create permission boundary test script
   cat > test_permission_boundaries.py << 'EOF'
   import boto3
   import json
   
   def test_effective_permissions():
       """Test effective permissions with permission boundaries"""
       iam_client = boto3.client('iam')
       
       print("=== Permission Boundary Analysis ===")
       
       try:
           # Get user details
           user_response = iam_client.get_user(UserName='developer-user')
           user = user_response['User']
           
           print(f"User: {user['UserName']}")
           print(f"Permission Boundary: {user.get('PermissionsBoundary', {}).get('PermissionsBoundaryArn', 'None')}")
           
           # Get user policies
           policies_response = iam_client.list_user_policies(UserName='developer-user')
           print(f"Inline Policies: {policies_response['PolicyNames']}")
           
           attached_response = iam_client.list_attached_user_policies(UserName='developer-user')
           print(f"Attached Policies: {[p['PolicyName'] for p in attached_response['AttachedPolicies']]}")
           
           # Simulate policy evaluation
           test_actions = [
               's3:ListBuckets',
               's3:CreateBucket',
               'ec2:DescribeInstances',
               'ec2:TerminateInstances',
               'iam:CreateUser',
               'lambda:CreateFunction'
           ]
           
           print(f"\n=== Testing Actions ===")
           for action in test_actions:
               try:
                   response = iam_client.simulate_principal_policy(
                       PolicySourceArn=f'arn:aws:iam::ACCOUNT_ID:user/developer-user',
                       ActionNames=[action],
                       ResourceArns=['*']
                   )
                   
                   result = response['EvaluationResults'][0]
                   decision = result['EvalDecision']
                   
                   print(f"{action}: {decision}")
                   
                   if decision == 'implicitDeny' or decision == 'explicitDeny':
                       if result.get('MatchedStatements'):
                           for statement in result['MatchedStatements']:
                               if statement.get('SourcePolicyType') == 'PermissionsBoundary':
                                   print(f"  → Denied by Permission Boundary")
                                   break
                   
               except Exception as e:
                   print(f"{action}: Error - {e}")
                   
       except Exception as e:
           print(f"Error testing permissions: {e}")
   
   def analyze_permission_boundary_policy():
       """Analyze the permission boundary policy"""
       print(f"\n=== Permission Boundary Policy Analysis ===")
       
       try:
           with open('permission-boundary.json', 'r') as f:
               policy = json.load(f)
           
           allowed_actions = set()
           denied_actions = set()
           
           for statement in policy['Statement']:
               actions = statement.get('Action', [])
               if isinstance(actions, str):
                   actions = [actions]
               
               if statement['Effect'] == 'Allow':
                   allowed_actions.update(actions)
               elif statement['Effect'] == 'Deny':
                   denied_actions.update(actions)
           
           print(f"Allowed Action Patterns: {len(allowed_actions)}")
           for action in sorted(allowed_actions)[:10]:
               print(f"  - {action}")
           
           print(f"\nExplicitly Denied Actions: {len(denied_actions)}")
           for action in sorted(denied_actions):
               print(f"  - {action}")
               
       except Exception as e:
           print(f"Error analyzing policy: {e}")
   
   if __name__ == "__main__":
       analyze_permission_boundary_policy()
       test_effective_permissions()
   EOF
   
   python3 test_permission_boundaries.py
   ```

**Screenshot Placeholder**:
![Permission Boundaries](screenshots/21-permission-boundaries.png)
*Caption: IAM permission boundaries implementation and testing*

### Practice 5: AWS SSO Integration
**Objective**: Set up AWS Single Sign-On for centralized access management

**Steps**:
1. **Enable AWS SSO**:
   ```bash
   # Enable AWS SSO (requires AWS Organizations)
   aws sso-admin create-instance-access-control-attribute-configuration \
     --instance-arn arn:aws:sso:::instance/ssoins-1234567890abcdef \
     --access-control-attributes '[
       {
         "Key": "Department",
         "Value": {
           "Source": "${path:enterprise.department}"
         }
       },
       {
         "Key": "CostCenter", 
         "Value": {
           "Source": "${path:enterprise.costCenter}"
         }
       }
     ]'
   ```

2. **Create SSO Permission Sets**:
   ```bash
   # Create permission set for developers
   cat > developer-permission-set.json << 'EOF'
   {
     "Name": "DeveloperAccess",
     "Description": "Developer access with limited permissions",
     "SessionDuration": "PT8H",
     "InlinePolicy": {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": [
             "s3:*",
             "lambda:*",
             "logs:*",
             "cloudwatch:*",
             "ec2:Describe*",
             "ec2:StartInstances",
             "ec2:StopInstances"
           ],
           "Resource": "*"
         },
         {
           "Effect": "Deny",
           "Action": [
             "ec2:TerminateInstances",
             "s3:DeleteBucket",
             "iam:*"
           ],
           "Resource": "*"
         }
       ]
     }
   }
   EOF
   
   # Create admin permission set
   cat > admin-permission-set.json << 'EOF'
   {
     "Name": "AdminAccess",
     "Description": "Full administrative access",
     "SessionDuration": "PT4H",
     "ManagedPolicies": [
       "arn:aws:iam::aws:policy/AdministratorAccess"
     ]
   }
   EOF
   ```

3. **SSO Management Script**:
   ```bash
   # Create SSO management script
   cat > manage_sso.py << 'EOF'
   import boto3
   import json
   
   sso_admin = boto3.client('sso-admin')
   identitystore = boto3.client('identitystore')
   
   def list_sso_instances():
       """List SSO instances"""
       print("=== SSO Instances ===")
       
       try:
           response = sso_admin.list_instances()
           
           for instance in response['Instances']:
               print(f"Instance ARN: {instance['InstanceArn']}")
               print(f"Identity Store ID: {instance['IdentityStoreId']}")
               print(f"Status: {instance['Status']}")
               
               return instance['InstanceArn'], instance['IdentityStoreId']
               
       except Exception as e:
           print(f"Error listing instances: {e}")
           return None, None
   
   def list_permission_sets(instance_arn):
       """List permission sets"""
       print(f"\n=== Permission Sets ===")
       
       try:
           response = sso_admin.list_permission_sets(InstanceArn=instance_arn)
           
           for ps_arn in response['PermissionSets']:
               ps_response = sso_admin.describe_permission_set(
                   InstanceArn=instance_arn,
                   PermissionSetArn=ps_arn
               )
               
               ps = ps_response['PermissionSet']
               print(f"\nName: {ps['Name']}")
               print(f"Description: {ps.get('Description', 'N/A')}")
               print(f"Session Duration: {ps.get('SessionDuration', 'N/A')}")
               print(f"ARN: {ps_arn}")
               
       except Exception as e:
           print(f"Error listing permission sets: {e}")
   
   def list_account_assignments(instance_arn):
       """List account assignments"""
       print(f"\n=== Account Assignments ===")
       
       try:
           # Get organization accounts
           org_client = boto3.client('organizations')
           accounts_response = org_client.list_accounts()
           
           for account in accounts_response['Accounts'][:5]:  # Limit to first 5
               account_id = account['Id']
               print(f"\nAccount: {account['Name']} ({account_id})")
               
               try:
                   assignments_response = sso_admin.list_account_assignments(
                       InstanceArn=instance_arn,
                       AccountId=account_id
                   )
                   
                   if assignments_response['AccountAssignments']:
                       for assignment in assignments_response['AccountAssignments']:
                           print(f"  - {assignment['PrincipalType']}: {assignment['PrincipalId']}")
                           print(f"    Permission Set: {assignment['PermissionSetArn'].split('/')[-1]}")
                   else:
                       print("  No assignments found")
                       
               except Exception as e:
                   print(f"  Error getting assignments: {e}")
                   
       except Exception as e:
           print(f"Error listing account assignments: {e}")
   
   def create_sso_user(identity_store_id):
       """Create SSO user"""
       print(f"\n=== Creating SSO User ===")
       
       try:
           response = identitystore.create_user(
               IdentityStoreId=identity_store_id,
               UserName='john.developer',
               DisplayName='John Developer',
               Name={
                   'GivenName': 'John',
                   'FamilyName': 'Developer'
               },
               Emails=[
                   {
                       'Value': 'john.developer@example.com',
                       'Type': 'work',
                       'Primary': True
                   }
               ]
           )
           
           user_id = response['UserId']
           print(f"Created user: {user_id}")
           
           return user_id
           
       except Exception as e:
           print(f"Error creating user: {e}")
           return None
   
   def create_sso_group(identity_store_id):
       """Create SSO group"""
       print(f"\n=== Creating SSO Group ===")
       
       try:
           response = identitystore.create_group(
               IdentityStoreId=identity_store_id,
               DisplayName='Developers',
               Description='Development team group'
           )
           
           group_id = response['GroupId']
           print(f"Created group: {group_id}")
           
           return group_id
           
       except Exception as e:
           print(f"Error creating group: {e}")
           return None
   
   if __name__ == "__main__":
       instance_arn, identity_store_id = list_sso_instances()
       
       if instance_arn:
           list_permission_sets(instance_arn)
           list_account_assignments(instance_arn)
           
           if identity_store_id:
               # create_sso_user(identity_store_id)
               # create_sso_group(identity_store_id)
               print("\nSSO user and group creation commented out for safety")
   EOF
   
   python3 manage_sso.py
   ```

**Screenshot Placeholder**:
![AWS SSO Setup](screenshots/21-aws-sso.png)
*Caption: AWS SSO configuration with permission sets and assignments*

## ✅ Section Completion Checklist

- [ ] Configured cross-account IAM role access with external ID
- [ ] Set up SAML identity federation for enterprise users
- [ ] Created advanced IAM policies with conditions and variables
- [ ] Implemented permission boundaries for security constraints
- [ ] Configured AWS SSO for centralized access management
- [ ] Tested policy evaluation and effective permissions
- [ ] Set up attribute-based access control (ABAC)
- [ ] Implemented time-based and IP-based access restrictions
- [ ] Created automated IAM compliance monitoring

## 🎯 Key Takeaways

- **Cross-Account Access**: Use roles for secure cross-account resource sharing
- **Identity Federation**: Integrate with enterprise identity providers
- **Policy Conditions**: Implement context-aware access controls
- **Permission Boundaries**: Set maximum permissions for enhanced security
- **AWS SSO**: Centralize access management across multiple accounts
- **Policy Variables**: Create dynamic, user-specific access patterns
- **Least Privilege**: Always grant minimum necessary permissions
- **Regular Auditing**: Continuously review and optimize access patterns

## 📚 Additional Resources

- [IAM User Guide](https://docs.aws.amazon.com/iam/)
- [AWS SSO User Guide](https://docs.aws.amazon.com/singlesignon/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Identity Federation Patterns](https://aws.amazon.com/identity/federation/)