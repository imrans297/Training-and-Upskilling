#!/bin/bash
# promote-replica.sh - Promote RDS read replica to standalone instance

echo "Checking RDS replica status..."

# Check if it's still a read replica
REPLICA_SOURCE=$(aws rds describe-db-instances \
  --db-instance-identifier webapp-db-replica \
  --query 'DBInstances[0].ReadReplicaSourceDBInstanceIdentifier' \
  --output text \
  --region us-west-2)

if [ "$REPLICA_SOURCE" = "None" ] || [ "$REPLICA_SOURCE" = "null" ]; then
    echo "✅ RDS instance is already promoted to standalone database!"
    echo "No promotion needed."
else
    echo "🔄 Starting RDS replica promotion..."
    
    # Promote the read replica
    aws rds promote-read-replica \
      --db-instance-identifier webapp-db-replica \
      --backup-retention-period 7 \
      --preferred-backup-window "03:00-04:00" \
      --region us-west-2
    
    echo "Waiting for promotion to complete..."
    aws rds wait db-instance-available \
      --db-instance-identifier webapp-db-replica \
      --region us-west-2
    
    echo "✅ RDS promotion completed successfully!"
fi

# Get the current endpoint
REPLICA_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier webapp-db-replica \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text \
  --region us-west-2)

echo "📍 Database endpoint: $REPLICA_ENDPOINT"
echo "🎯 Database is ready for production traffic!"