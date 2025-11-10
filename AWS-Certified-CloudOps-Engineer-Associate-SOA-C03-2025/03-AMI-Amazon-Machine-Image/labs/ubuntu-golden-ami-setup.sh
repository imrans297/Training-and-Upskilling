#!/bin/bash

# Ubuntu Golden AMI Setup Script
# Enable logging and error handling
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -x

echo "Starting Ubuntu Golden AMI setup at $(date)..."

# Wait for system to be ready
sleep 30

# Update system
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    htop \
    git \
    wget \
    curl \
    unzip \
    vim \
    docker.io \
    nginx \
    python3 \
    python3-pip \
    awscli

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configure Docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ubuntu

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install common Python packages
pip3 install boto3 requests

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Install SSM Agent (usually pre-installed on Ubuntu AMIs)
snap install amazon-ssm-agent --classic

# Configure CloudWatch Agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "AMI/CloudOps",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/ami/cloudops/syslog",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Enable services
systemctl enable docker
systemctl enable nginx
systemctl enable amazon-cloudwatch-agent

# Create web application
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Ubuntu Golden AMI Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .info { background: #e3f2fd; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .success { color: #4caf50; font-weight: bold; }
        ul { background: #f9f9f9; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Ubuntu Golden AMI Instance</h1>
        <p class="success">✅ Web server is running successfully!</p>
        
        <div class="info">
            <h3>Instance Information</h3>
            <p><strong>OS:</strong> Ubuntu 22.04 LTS</p>
            <p><strong>AMI Type:</strong> Golden AMI</p>
            <p><strong>Created:</strong> <span id="date"></span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Public IP:</strong> <span id="public-ip">Loading...</span></p>
            <p><strong>Region:</strong> <span id="region">Loading...</span></p>
        </div>
        
        <h3>📦 Installed Software</h3>
        <ul>
            <li>Nginx Web Server</li>
            <li>Docker</li>
            <li>AWS CLI v2</li>
            <li>CloudWatch Agent</li>
            <li>SSM Agent</li>
            <li>Node.js 18</li>
            <li>Python 3</li>
            <li>Git, htop, vim</li>
        </ul>
        
        <h3>🔧 AMI Lab Features</h3>
        <ul>
            <li>Ready for AMI creation</li>
            <li>Pre-configured monitoring</li>
            <li>Docker containerization support</li>
            <li>CloudOps tools installed</li>
        </ul>
    </div>
    
    <script>
        document.getElementById('date').textContent = new Date().toLocaleString();
        
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/public-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('public-ip').textContent = data)
            .catch(() => document.getElementById('public-ip').textContent = 'N/A');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/region')
            .then(response => response.text())
            .then(data => document.getElementById('region').textContent = data)
            .catch(() => document.getElementById('region').textContent = 'N/A');
    </script>
</body>
</html>
EOF

# Configure nginx
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# Start nginx
systemctl start nginx

# Create AMI preparation script
cat > /opt/prepare-for-ami.sh << 'EOF'
#!/bin/bash
echo "Preparing Ubuntu instance for AMI creation..."

# Stop services
systemctl stop nginx
systemctl stop amazon-cloudwatch-agent

# Clean up logs
find /var/log -type f -exec truncate -s 0 {} \;

# Clean up temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clean up package cache
apt-get clean
apt-get autoremove -y

# Clear bash history
history -c
rm -f ~/.bash_history
rm -f /home/ubuntu/.bash_history

# Clear SSH host keys
rm -f /etc/ssh/ssh_host_*

# Clear machine-id
truncate -s 0 /etc/machine-id

echo "Ubuntu instance prepared for AMI creation"
EOF

chmod +x /opt/prepare-for-ami.sh

# Create first boot script
cat > /opt/first-boot-setup.sh << 'EOF'
#!/bin/bash
# First boot setup for Ubuntu instances from Golden AMI

# Regenerate SSH host keys
ssh-keygen -A

# Generate new machine-id
systemd-machine-id-setup

# Start services
systemctl start nginx
systemctl start amazon-cloudwatch-agent

# Log first boot
echo "$(date): First boot completed for instance $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /var/log/first-boot.log
EOF

chmod +x /opt/first-boot-setup.sh

# Add to rc.local equivalent (systemd service)
cat > /etc/systemd/system/first-boot.service << 'EOF'
[Unit]
Description=First Boot Setup
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/first-boot-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable first-boot.service

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -a start

# Final verification
echo "=== Setup Verification ==="
echo "Nginx status: $(systemctl is-active nginx)"
echo "Docker status: $(systemctl is-active docker)"
echo "CloudWatch Agent status: $(systemctl is-active amazon-cloudwatch-agent)"
echo "Web content exists: $(test -f /var/www/html/index.html && echo 'YES' || echo 'NO')"

echo "Ubuntu Golden AMI setup completed at $(date)!"
echo "Nginx is running on port 80"
echo "To prepare for AMI creation, run: /opt/prepare-for-ami.sh"
echo "Setup log available at: /var/log/user-data.log"