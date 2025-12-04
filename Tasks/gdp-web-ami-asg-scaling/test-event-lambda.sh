#!/bin/bash

# Test Event-Driven Lambda by Creating New AMI Backup

echo "=== Testing Event-Driven Lambda ==="

# Get running GDP-Web instances
echo "1. Getting running GDP-Web instances..."
aws ec2 describe-instances \
    --filters "Name=tag:Application,Values=gdp-web-1,gdp-web-2,gdp-web-3" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Application`].Value|[0],InstanceId,PublicIpAddress]' \
    --output table

echo ""
echo "2. Choose which instance to create AMI backup for:"
echo "   gdp-web-1: Test with instance 1"
echo "   gdp-web-2: Test with instance 2" 
echo "   gdp-web-3: Test with instance 3"
echo ""

# Get instance ID for gdp-web-2 (for testing)
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Application,Values=gdp-web-2" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "No running gdp-web-2 instance found"
    exit 1
fi

echo "3. Creating AMI backup for gdp-web-2 (Instance: $INSTANCE_ID)..."

# Create AMI backup
TIMESTAMP=$(date -u +%Y-%m-%d-%H-%M)
AMI_NAME="gdp-web-2-$TIMESTAMP"

AMI_ID=$(aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "$AMI_NAME" \
    --description "Test AMI backup for event-driven Lambda" \
    --no-reboot \
    --query 'ImageId' \
    --output text)

echo "✓ AMI Created: $AMI_ID ($AMI_NAME)"
echo ""

echo "4. Waiting 30 seconds for EventBridge to trigger Lambda..."
sleep 30

echo "5. Checking Lambda logs for automatic trigger..."
aws logs describe-log-streams \
    --log-group-name /aws/lambda/gdp-web-event-driven-ami \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text > latest-stream.txt

if [ -s latest-stream.txt ]; then
    STREAM_NAME=$(cat latest-stream.txt)
    echo "Latest log stream: $STREAM_NAME"
    
    echo ""
    echo "6. Recent Lambda execution logs:"
    aws logs get-log-events \
        --log-group-name /aws/lambda/gdp-web-event-driven-ami \
        --log-stream-name "$STREAM_NAME" \
        --start-time $(date -d '2 minutes ago' +%s)000 \
        --query 'events[].message' \
        --output text
else
    echo "No recent Lambda executions found"
fi

echo ""
echo "7. Manual test with the new AMI:"
aws lambda invoke \
    --function-name gdp-web-event-driven-ami \
    --cli-binary-format raw-in-base64-out \
    --payload "{\"detail\":{\"responseElements\":{\"imageId\":\"$AMI_ID\"}}}" \
    manual-test-result.json

echo "Manual test result:"
cat manual-test-result.json | jq .

echo ""
echo "✅ Test Complete!"
echo "Created AMI: $AMI_ID for gdp-web-2"
echo "Expected: Lambda should automatically trigger and return only gdp-web-2 data"

# Cleanup
rm -f latest-stream.txt manual-test-result.json