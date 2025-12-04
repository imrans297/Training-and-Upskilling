#!/bin/bash

# Fresh ASG Setup using gdp-web-1 instance configuration

# Variables
VPC_ID="vpc-00af5d50f8f210db9"  # GDP-Web-1 VPC
SUBNET_IDS="subnet-0e5111facea9fd5e8,subnet-0eec597f685e0d199"  # GDP-Web-1 subnets
KEY_NAME="gdp-web-keypair"
SECURITY_GROUP_ID="sg-03fde8a4541d8fd9d"  # Existing SG
TARGET_GROUP_ARN="arn:aws:elasticloadbalancing:ap-south-1:375039967967:targetgroup/gdp-web-tg-v2/d1f7c7f17c2d1a7b"

echo "=== Getting GDP-Web-1 AMI ==="
GDP_WEB_AMI=$(aws ec2 describe-instances --instance-ids i-0b2fa2f35913cac0c --query 'Reservations[0].Instances[0].ImageId' --output text)
echo "Using AMI: $GDP_WEB_AMI"

echo "=== Creating Launch Template ==="
aws ec2 create-launch-template \
    --launch-template-name gdp-web-asg-lt \
    --launch-template-data '{
        "ImageId": "'$GDP_WEB_AMI'",
        "InstanceType": "t2.micro",
        "KeyName": "'$KEY_NAME'",
        "SecurityGroupIds": ["'$SECURITY_GROUP_ID'"],
        "IamInstanceProfile": {
            "Name": "EC2-CloudWatch-Role"
        },
        "UserData": "'$(base64 -w 0 << 'EOF'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

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
            // CPU intensive task
            for(let i = 0; i < 1000000; i++) {
                Math.random() * Math.random();
            }
        }
    </script>
</body>
</html>
HTML_EOF

systemctl restart httpd
EOF
)'"
    }'

echo "=== Creating Auto Scaling Group ==="
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name gdp-web-asg \
    --launch-template LaunchTemplateName=gdp-web-asg-lt,Version='$Latest' \
    --min-size 1 \
    --max-size 2 \
    --desired-capacity 1 \
    --target-group-arns $TARGET_GROUP_ARN \
    --vpc-zone-identifier $SUBNET_IDS \
    --health-check-type ELB \
    --health-check-grace-period 300

echo "=== Creating Scaling Policies ==="
SCALE_UP_ARN=$(aws autoscaling put-scaling-policy \
    --auto-scaling-group-name gdp-web-asg \
    --policy-name "gdp-web-scale-up" \
    --policy-type "SimpleScaling" \
    --adjustment-type "ChangeInCapacity" \
    --scaling-adjustment 1 \
    --cooldown 300 \
    --query 'PolicyARN' --output text)

SCALE_DOWN_ARN=$(aws autoscaling put-scaling-policy \
    --auto-scaling-group-name gdp-web-asg \
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
    --dimensions Name=AutoScalingGroupName,Value=gdp-web-asg

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
    --dimensions Name=AutoScalingGroupName,Value=gdp-web-asg

echo "=== Setup Complete ==="
echo "ASG Name: gdp-web-asg"
echo "Launch Template: gdp-web-asg-lt"
echo "ALB URL: http://gdp-web-alb-v2-366659262.ap-south-1.elb.amazonaws.com"