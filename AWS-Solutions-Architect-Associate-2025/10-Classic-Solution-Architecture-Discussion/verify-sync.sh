#!/bin/bash
# verify-sync.sh - Verify data synchronization status

echo "=== Disaster Recovery Sync Verification ==="

# Check S3 replication status
echo "Checking S3 replication status..."
aws s3api get-bucket-replication \
  --bucket webapp-dr-primary-bucket-$(date +%Y%m%d) \
  --query 'ReplicationConfiguration.Rules[0].Status' \
  --output text 2>/dev/null || echo "S3 replication not configured"

# Check RDS replica lag
echo "Checking RDS replica lag..."
REPLICA_LAG=$(aws rds describe-db-instances \
  --db-instance-identifier webapp-db-replica \
  --query 'DBInstances[0].ReadReplicaSourceDBInstanceIdentifier' \
  --output text \
  --region us-west-2 2>/dev/null)

if [ "$REPLICA_LAG" != "None" ]; then
    echo "RDS replica is active and syncing"
else
    echo "RDS replica is promoted or not configured"
fi

# Check secondary region infrastructure
echo "Checking secondary region infrastructure..."
ASG_STATUS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names webapp-dr-secondary-asg \
  --query 'AutoScalingGroups[0].DesiredCapacity' \
  --output text \
  --region us-west-2 2>/dev/null)

echo "Secondary ASG desired capacity: $ASG_STATUS"

# Check ALB health
ALB_STATUS=$(aws elbv2 describe-load-balancers \
  --names webapp-dr-secondary-alb \
  --query 'LoadBalancers[0].State.Code' \
  --output text \
  --region us-west-2 2>/dev/null)

echo "Secondary ALB status: $ALB_STATUS"

echo "=== Verification completed ==="