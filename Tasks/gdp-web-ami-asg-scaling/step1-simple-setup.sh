#!/bin/bash

# Step 1: Simple Setup - Create 3 GDP-Web instances with enhanced display

echo "=== GDP-Web Task 1: Simple Setup ==="
echo "Creating 3 instances with AMI backup information display"

# Get VPC and subnet
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)

# Get latest Amazon Linux 2 AMI
BASE_AMI=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

echo "Using AMI: $BASE_AMI"
echo "VPC: $VPC_ID, Subnet: $SUBNET_ID"

# Create security group
SG_ID=$(aws ec2 create-security-group \
    --group-name gdp-web-simple-sg \
    --description "GDP-Web Simple Setup Security Group" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=gdp-web-simple-sg" \
    --query 'SecurityGroups[0].GroupId' --output text)

# Add security group rules
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true

# Create user data script
cat > userdata.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y python3 python3-pip
pip3 install flask requests psutil

mkdir -p /opt/gdp-web
cd /opt/gdp-web

cat > app.py << 'PYEOF'
#!/usr/bin/env python3
import os
import time
import socket
import requests
from flask import Flask, jsonify

app = Flask(__name__)

def get_metadata():
    try:
        instance_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id', timeout=2).text
        public_ip = requests.get('http://169.254.169.254/latest/meta-data/public-ipv4', timeout=2).text
        private_ip = requests.get('http://169.254.169.254/latest/meta-data/local-ipv4', timeout=2).text
        ami_id = requests.get('http://169.254.169.254/latest/meta-data/ami-id', timeout=2).text
        az = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone', timeout=2).text
        return instance_id, public_ip, private_ip, ami_id, az
    except:
        return 'unknown', 'unknown', 'unknown', 'unknown', 'unknown'

@app.route('/')
def home():
    hostname = socket.gethostname()
    instance_id, public_ip, private_ip, ami_id, az = get_metadata()
    app_id = os.environ.get('APP_ID', '1')
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())
    ami_backup_name = f"gdp-web-{app_id}-{time.strftime('%Y-%m-%d-%H-%M', time.gmtime())}"
    
    return f"""
    <html>
    <head>
        <title>GDP-Web-{app_id} - Task 1</title>
        <style>
            body {{ font-family: Arial; margin: 40px; background: #f5f5f5; }}
            .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #{'#e74c3c' if app_id == '1' else '#3498db' if app_id == '2' else '#2ecc71'}; }}
            .info-table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
            .info-table th, .info-table td {{ padding: 12px; text-align: left; border: 1px solid #ddd; }}
            .info-table th {{ background-color: #f8f9fa; font-weight: bold; }}
            .highlight {{ background-color: #fff3cd; font-weight: bold; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 GDP-Web-{app_id} Application - Task 1</h1>
            
            <h2>📋 Instance Information</h2>
            <table class="info-table">
                <tr><th>Field</th><th>Value</th></tr>
                <tr class="highlight"><td><b>AMI Backup ID</b></td><td>{ami_id}</td></tr>
                <tr class="highlight"><td><b>AMI Backup Name</b></td><td>{ami_backup_name}</td></tr>
                <tr class="highlight"><td><b>Public IP</b></td><td>{public_ip}</td></tr>
                <tr class="highlight"><td><b>Version</b></td><td>1.0.0</td></tr>
                <tr class="highlight"><td><b>Date</b></td><td>{timestamp}</td></tr>
                <tr class="highlight"><td><b>Hostname</b></td><td>{hostname}</td></tr>
                <tr><td>Instance ID</td><td>{instance_id}</td></tr>
                <tr><td>Private IP</td><td>{private_ip}</td></tr>
                <tr><td>Availability Zone</td><td>{az}</td></tr>
                <tr><td>Application</td><td>GDP-Web-{app_id}</td></tr>
            </table>
            
            <h3>🔗 Quick Links</h3>
            <p>
                <a href="/json">JSON View</a> | 
                <a href="/health">Health Check</a>
            </p>
        </div>
    </body>
    </html>
    """

@app.route('/json')
def json_view():
    hostname = socket.gethostname()
    instance_id, public_ip, private_ip, ami_id, az = get_metadata()
    app_id = os.environ.get('APP_ID', '1')
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())
    ami_backup_name = f"gdp-web-{app_id}-{time.strftime('%Y-%m-%d-%H-%M', time.gmtime())}"
    
    return jsonify({
        'ami_backup_id': ami_id,
        'ami_backup_name': ami_backup_name,
        'public_ip': public_ip,
        'version': '1.0.0',
        'date': timestamp,
        'hostname': hostname,
        'instance_id': instance_id,
        'private_ip': private_ip,
        'availability_zone': az,
        'application': f'GDP-Web-{app_id}'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
PYEOF

# Create systemd service
cat > /etc/systemd/system/gdp-web.service << 'SVCEOF'
[Unit]
Description=GDP-Web Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gdp-web
Environment=APP_ID=APP_ID_PLACEHOLDER
ExecStart=/usr/bin/python3 /opt/gdp-web/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable gdp-web
systemctl start gdp-web
EOF

# Create 3 instances
echo "Creating 3 GDP-Web instances..."
for i in {1..3}; do
    echo "Creating GDP-Web-$i instance..."
    
    # Replace APP_ID placeholder in user data
    sed "s/APP_ID_PLACEHOLDER/$i/g" userdata.sh > userdata_$i.sh
    
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $BASE_AMI \
        --count 1 \
        --instance-type t3.micro \
        --key-name gdp-web-keypair \
        --security-group-ids $SG_ID \
        --subnet-id $SUBNET_ID \
        --user-data file://userdata_$i.sh \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=gdp-web-$i-instance},{Key=Application,Value=gdp-web-$i}]" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    echo "✓ Created instance: $INSTANCE_ID for GDP-Web-$i"
    rm -f userdata_$i.sh
done

echo "=== Waiting for instances to be running ==="
sleep 60

# Show instance details
echo "=== GDP-Web Instances Created ==="
aws ec2 describe-instances \
    --filters "Name=tag:Application,Values=gdp-web-1,gdp-web-2,gdp-web-3" "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceId,PublicIpAddress,State.Name]' \
    --output table

echo ""
echo "=== Access Your Applications ==="
for i in {1..3}; do
    PUBLIC_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:Application,Values=gdp-web-$i" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>/dev/null)
    
    if [ "$PUBLIC_IP" != "None" ] && [ "$PUBLIC_IP" != "" ]; then
        echo "GDP-Web-$i: http://$PUBLIC_IP"
        echo "  SSH: ssh -i gdp-web-keypair.pem ec2-user@$PUBLIC_IP"
    fi
done

# Cleanup
rm -f userdata.sh

echo ""
echo "=== Task 1 Complete ==="
echo "✓ 3 instances created with enhanced web display"
echo "✓ Each shows: AMI Backup ID, Name, Public IP, Version, Date, Hostname"
echo "✓ Access via browser to see the information"