#!/bin/bash

# Task 2: ASG + ALB with CPU Scaling and AMI Update Automation

# Variables
VPC_ID="vpc-00af5d50f8f210db9"  # GDP-Web-1 VPC
SUBNET_IDS="subnet-0eec597f685e0d199,subnet-0782b79778b517554"  # Different AZs for ALB
KEY_NAME="gdp-web-keypair"
SECURITY_GROUP_NAME="gdp-web-asg-sg"
ALB_NAME="gdp-web-alb"
TARGET_GROUP_NAME="gdp-web-tg"
LAUNCH_TEMPLATE_NAME="gdp-web-lt"
ASG_NAME="gdp-web-asg"

echo "=== Creating Security Group ==="
SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for GDP-Web ASG" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0

echo "Security Group ID: $SG_ID"

echo "=== Getting Latest GDP-Web AMI ==="
LATEST_AMI=$(aws ec2 describe-images \
    --owners self \
    --filters "Name=name,Values=gdp-web-*" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

echo "Latest AMI: $LATEST_AMI"

echo "=== Creating Launch Template ==="
aws ec2 create-launch-template \
    --launch-template-name $LAUNCH_TEMPLATE_NAME \
    --launch-template-data '{
        "ImageId": "'$LATEST_AMI'",
        "InstanceType": "t2.micro",
        "KeyName": "'$KEY_NAME'",
        "SecurityGroupIds": ["'$SG_ID'"],
        "IamInstanceProfile": {
            "Name": "EC2-CloudWatch-Role"
        },
        "UserData": "'$(base64 -w 0 << 'EOF'
#!/bin/bash
yum update -y
yum install -y httpd amazon-cloudwatch-agent
systemctl start httpd
systemctl enable httpd

# Install CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CW_EOF'
{
    "metrics": {
        "namespace": "GDP-Web/ASG",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
CW_EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Create web content
cat > /var/www/html/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html>
<head><title>GDP-Web ASG Instance</title></head>
<body>
    <h1>GDP-Web Auto Scaling Group</h1>
    <p>Instance ID: <span id="instance-id">Loading...</span></p>
    <p>AMI ID: <span id="ami-id">Loading...</span></p>
    <p>Launch Time: <span id="launch-time">Loading...</span></p>
    <p>CPU Load Test: <button onclick="loadTest()">Start CPU Load</button></p>
    <div id="status"></div>
    
    <script>
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(r => r.text()).then(d => document.getElementById('instance-id').textContent = d);
        fetch('http://169.254.169.254/latest/meta-data/ami-id')
            .then(r => r.text()).then(d => document.getElementById('ami-id').textContent = d);
        fetch('http://169.254.169.254/latest/meta-data/launch-time')
            .then(r => r.text()).then(d => document.getElementById('launch-time').textContent = d);
            
        function loadTest() {
            document.getElementById('status').innerHTML = 'Running CPU load test for 5 minutes...';
            fetch('/cgi-bin/cpu-load.sh');
        }
    </script>
</body>
</html>
HTML_EOF

# Create CPU load test script
mkdir -p /var/www/cgi-bin
cat > /var/www/cgi-bin/cpu-load.sh << 'LOAD_EOF'
#!/bin/bash
echo "Content-Type: text/plain"
echo ""
echo "Starting CPU load test..."
# Run CPU intensive task for 5 minutes
timeout 300 yes > /dev/null &
echo "CPU load test started for 5 minutes"
LOAD_EOF

chmod +x /var/www/cgi-bin/cpu-load.sh

# Enable CGI
echo "LoadModule cgi_module modules/mod_cgi.so" >> /etc/httpd/conf/httpd.conf
echo "ScriptAlias /cgi-bin/ /var/www/cgi-bin/" >> /etc/httpd/conf/httpd.conf
systemctl restart httpd
EOF
)'"
    }'

echo "=== Creating Application Load Balancer ==="
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name $ALB_NAME \
    --subnets $(echo $SUBNET_IDS | tr ',' ' ') \
    --security-groups $SG_ID \
    --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB ARN: $ALB_ARN"

echo "=== Creating Target Group ==="
TG_ARN=$(aws elbv2 create-target-group \
    --name $TARGET_GROUP_NAME \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --health-check-path / \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Target Group ARN: $TG_ARN"

echo "=== Creating ALB Listener ==="
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN

echo "=== Creating Auto Scaling Group ==="
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name $ASG_NAME \
    --launch-template LaunchTemplateName=$LAUNCH_TEMPLATE_NAME,Version='$Latest' \
    --min-size 1 \
    --max-size 2 \
    --desired-capacity 1 \
    --target-group-arns $TG_ARN \
    --vpc-zone-identifier $SUBNET_IDS \
    --health-check-type ELB \
    --health-check-grace-period 300

echo "=== Creating CPU Scaling Policy ==="
SCALE_UP_ARN=$(aws autoscaling put-scaling-policy \
    --auto-scaling-group-name $ASG_NAME \
    --policy-name "gdp-web-scale-up" \
    --policy-type "SimpleScaling" \
    --adjustment-type "ChangeInCapacity" \
    --scaling-adjustment 1 \
    --cooldown 300 \
    --query 'PolicyARN' --output text)

SCALE_DOWN_ARN=$(aws autoscaling put-scaling-policy \
    --auto-scaling-group-name $ASG_NAME \
    --policy-name "gdp-web-scale-down" \
    --policy-type "SimpleScaling" \
    --adjustment-type "ChangeInCapacity" \
    --scaling-adjustment -1 \
    --cooldown 300 \
    --query 'PolicyARN' --output text)

echo "=== Creating CloudWatch Alarms ==="
aws cloudwatch put-metric-alarm \
    --alarm-name "gdp-web-cpu-high" \
    --alarm-description "Scale up when CPU > 75%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 75 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SCALE_UP_ARN \
    --dimensions Name=AutoScalingGroupName,Value=$ASG_NAME

aws cloudwatch put-metric-alarm \
    --alarm-name "gdp-web-cpu-low" \
    --alarm-description "Scale down when CPU < 25%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 25 \
    --comparison-operator LessThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions $SCALE_DOWN_ARN \
    --dimensions Name=AutoScalingGroupName,Value=$ASG_NAME

echo "=== Setup Complete ==="
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)
echo "ALB DNS: http://$ALB_DNS"
echo "Security Group ID: $SG_ID"
echo "Launch Template: $LAUNCH_TEMPLATE_NAME"
echo "Auto Scaling Group: $ASG_NAME"