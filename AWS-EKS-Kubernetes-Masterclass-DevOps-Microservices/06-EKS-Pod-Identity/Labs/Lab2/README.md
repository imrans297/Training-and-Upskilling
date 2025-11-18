# Lab 2: Advanced Pod Identity Scenarios

## What We're Achieving
Implement advanced Pod Identity patterns including cross-account access, multiple AWS services integration, and production security practices.

## What We're Doing
- Configure cross-account Pod Identity access
- Integrate with multiple AWS services (S3, DynamoDB, SQS, SNS)
- Implement fine-grained permissions and conditions
- Set up monitoring and auditing for Pod Identity usage

## Prerequisites
- Completed Lab 1 (Basic Pod Identity Setup)
- Understanding of AWS IAM policies and conditions
- kubectl configured

## Lab Exercises

### Exercise 1: Multi-Service Integration
```bash
# Switch to pod identity namespace
kubectl config set-context --current --namespace=pod-identity

# Create comprehensive IAM policy for multiple services
cat > multi-service-policy.json << EOF
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
      "Resource": "arn:aws:s3:::pod-identity-demo/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:ap-south-1:*:table/pod-identity-table"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:ap-south-1:*:pod-identity-queue"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish"
      ],
      "Resource": "arn:aws:sns:ap-south-1:*:pod-identity-topic"
    }
  ]
}
EOF

# Create IAM role with multi-service policy
aws iam create-role \
  --role-name EKS-Pod-Identity-MultiService-Role \
  --assume-role-policy-document file://pod-identity-trust-policy.json

aws iam put-role-policy \
  --role-name EKS-Pod-Identity-MultiService-Role \
  --policy-name MultiServiceAccess \
  --policy-document file://multi-service-policy.json
```

### Exercise 2: Conditional Access Policies
```bash
# Create policy with conditions
cat > conditional-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::pod-identity-demo/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "ap-south-1"
        },
        "DateGreaterThan": {
          "aws:CurrentTime": "2024-01-01T00:00:00Z"
        },
        "IpAddress": {
          "aws:SourceIp": ["10.0.0.0/16"]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-south-1:*:table/pod-identity-table",
      "Condition": {
        "ForAllValues:StringEquals": {
          "dynamodb:Attributes": ["id", "name", "timestamp"]
        }
      }
    }
  ]
}
EOF

# Create role with conditional access
aws iam create-role \
  --role-name EKS-Pod-Identity-Conditional-Role \
  --assume-role-policy-document file://pod-identity-trust-policy.json

aws iam put-role-policy \
  --role-name EKS-Pod-Identity-Conditional-Role \
  --policy-name ConditionalAccess \
  --policy-document file://conditional-policy.json
```

### Exercise 3: Application with Multiple AWS Services
```bash
# Create service account for multi-service app
kubectl create serviceaccount multi-service-sa -n pod-identity

# Create Pod Identity Association
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
MULTI_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/EKS-Pod-Identity-MultiService-Role"

aws eks create-pod-identity-association \
  --cluster-name training-cluster \
  --namespace pod-identity \
  --service-account multi-service-sa \
  --role-arn $MULTI_ROLE_ARN \
  --region ap-south-1

# Deploy application that uses multiple services
cat > multi-service-app.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-service-app
  namespace: pod-identity
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-service-app
  template:
    metadata:
      labels:
        app: multi-service-app
    spec:
      serviceAccountName: multi-service-sa
      containers:
      - name: app
        image: amazon/aws-cli:latest
        command: ["/bin/sh"]
        args:
        - -c
        - |
          while true; do
            echo "=== Multi-Service Demo ==="
            echo "1. Testing S3 access..."
            aws s3 ls s3://pod-identity-demo/ || echo "S3 bucket not found"
            
            echo "2. Testing DynamoDB access..."
            aws dynamodb list-tables --region ap-south-1
            
            echo "3. Testing SQS access..."
            aws sqs list-queues --region ap-south-1
            
            echo "4. Testing SNS access..."
            aws sns list-topics --region ap-south-1
            
            echo "Sleeping for 60 seconds..."
            sleep 60
          done
        env:
        - name: AWS_DEFAULT_REGION
          value: "ap-south-1"
EOF

kubectl apply -f multi-service-app.yaml
```

### Exercise 4: Cross-Account Access Setup
```bash
# Create cross-account trust policy
cat > cross-account-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::CROSS-ACCOUNT-ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        }
      }
    }
  ]
}
EOF

echo "Cross-account trust policy created (replace CROSS-ACCOUNT-ID)"
# aws iam create-role --role-name EKS-Pod-Identity-CrossAccount-Role --assume-role-policy-document file://cross-account-trust-policy.json
```

### Exercise 5: Monitoring and Auditing
```bash
# Create CloudWatch log group for Pod Identity events
aws logs create-log-group \
  --log-group-name /aws/eks/pod-identity/audit \
  --region ap-south-1

# Create CloudTrail for API monitoring (if not exists)
cat > cloudtrail-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:ap-south-1:*:log-group:/aws/eks/pod-identity/*"
    }
  ]
}
EOF

# Deploy monitoring application
cat > monitoring-app.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: pod-identity-monitor
  namespace: pod-identity
spec:
  serviceAccountName: multi-service-sa
  containers:
  - name: monitor
    image: amazon/aws-cli:latest
    command: ["/bin/sh"]
    args:
    - -c
    - |
      while true; do
        echo "=== Pod Identity Monitoring ==="
        echo "Current identity:"
        aws sts get-caller-identity
        
        echo "Recent CloudTrail events:"
        aws logs describe-log-groups --log-group-name-prefix "/aws/eks/pod-identity" --region ap-south-1 || echo "No log groups found"
        
        echo "IAM role usage:"
        aws iam get-role --role-name EKS-Pod-Identity-MultiService-Role --region ap-south-1 || echo "Role not accessible"
        
        sleep 300
      done
    env:
    - name: AWS_DEFAULT_REGION
      value: "ap-south-1"
EOF

kubectl apply -f monitoring-app.yaml
```

### Exercise 6: Security Best Practices Implementation
```bash
# Create least-privilege policy
cat > least-privilege-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::pod-identity-demo/app-data/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/Environment": "production"
        }
      }
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:DeleteObject"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/Critical": "true"
        }
      }
    }
  ]
}
EOF

# Create secure role
aws iam create-role \
  --role-name EKS-Pod-Identity-Secure-Role \
  --assume-role-policy-document file://pod-identity-trust-policy.json

aws iam put-role-policy \
  --role-name EKS-Pod-Identity-Secure-Role \
  --policy-name LeastPrivilegeAccess \
  --policy-document file://least-privilege-policy.json
```

## Cleanup
```bash
# Delete applications
kubectl delete -f multi-service-app.yaml
kubectl delete -f monitoring-app.yaml
kubectl delete pod pod-identity-monitor -n pod-identity

# Delete Pod Identity Associations
aws eks delete-pod-identity-association \
  --cluster-name training-cluster \
  --association-id $(aws eks list-pod-identity-associations --cluster-name training-cluster --region ap-south-1 --query 'associations[?serviceAccount==`multi-service-sa`].associationId' --output text) \
  --region ap-south-1

# Delete service accounts
kubectl delete serviceaccount multi-service-sa -n pod-identity

# Delete IAM roles and policies
aws iam delete-role-policy --role-name EKS-Pod-Identity-MultiService-Role --policy-name MultiServiceAccess
aws iam delete-role --role-name EKS-Pod-Identity-MultiService-Role
aws iam delete-role-policy --role-name EKS-Pod-Identity-Conditional-Role --policy-name ConditionalAccess
aws iam delete-role --role-name EKS-Pod-Identity-Conditional-Role
aws iam delete-role-policy --role-name EKS-Pod-Identity-Secure-Role --policy-name LeastPrivilegeAccess
aws iam delete-role --role-name EKS-Pod-Identity-Secure-Role

# Clean up files
rm -f multi-service-policy.json conditional-policy.json cross-account-trust-policy.json cloudtrail-policy.json least-privilege-policy.json multi-service-app.yaml monitoring-app.yaml
```

## Key Takeaways
1. Pod Identity supports complex multi-service integrations
2. Conditional policies provide fine-grained access control
3. Cross-account access requires proper trust relationships
4. Monitoring and auditing are essential for security
5. Least-privilege principles should always be applied
6. Resource-based policies can complement identity-based policies
7. Regular review of permissions is crucial for security

## Next Steps
- Move to Lab 3: Security and Troubleshooting
- Practice with real-world application scenarios
- Learn about Pod Identity performance optimization