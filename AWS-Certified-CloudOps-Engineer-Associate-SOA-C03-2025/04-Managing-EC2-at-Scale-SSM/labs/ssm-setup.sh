#!/bin/bash

# SSM Setup Script for Ubuntu
exec > >(tee /var/log/ssm-setup.log|logger -t ssm-setup -s 2>/dev/console) 2>&1
set -x

echo "Starting SSM setup at $(date)..."

# Update system
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    htop \
    curl \
    wget \
    unzip \
    nginx \
    awscli

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install SSM Agent (usually pre-installed on Ubuntu AMIs)
snap install amazon-ssm-agent --classic

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configure CloudWatch Agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "SSM/CloudOps",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
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
                        "log_group_name": "/aws/ssm/cloudops/syslog",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/ssm-setup.log",
                        "log_group_name": "/aws/ssm/cloudops/setup",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Enable and start services
systemctl enable nginx
systemctl start nginx
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create web content
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>SSM Managed Instance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .info { background: #e8f5e8; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .success { color: #4caf50; font-weight: bold; }
        .command { background: #f0f0f0; padding: 10px; border-radius: 3px; font-family: monospace; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 SSM Managed Instance</h1>
        <p class="success">✅ Systems Manager Agent is running!</p>
        
        <div class="info">
            <h3>Instance Information</h3>
            <p><strong>OS:</strong> Ubuntu 22.04 LTS</p>
            <p><strong>SSM Managed:</strong> Yes</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Private IP:</strong> <span id="private-ip">Loading...</span></p>
            <p><strong>Public IP:</strong> <span id="public-ip">Loading...</span></p>
        </div>
        
        <h3>📋 SSM Features Available</h3>
        <ul>
            <li>Session Manager (Shell Access)</li>
            <li>Run Command (Remote Execution)</li>
            <li>Parameter Store (Configuration)</li>
            <li>Patch Manager (Updates)</li>
            <li>Maintenance Windows</li>
            <li>CloudWatch Monitoring</li>
        </ul>
        
        <h3>🚀 Quick Commands</h3>
        <p><strong>Connect via Session Manager:</strong></p>
        <div class="command">aws ssm start-session --target <span id="instance-id-cmd">INSTANCE_ID</span></div>
        
        <p><strong>Run Command:</strong></p>
        <div class="command">aws ssm send-command --document-name "AWS-RunShellScript" --targets "Key=instanceids,Values=<span id="instance-id-cmd2">INSTANCE_ID</span>" --parameters 'commands=["uptime"]'</div>
    </div>
    
    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => {
                document.getElementById('instance-id').textContent = data;
                document.getElementById('instance-id-cmd').textContent = data;
                document.getElementById('instance-id-cmd2').textContent = data;
            });
            
        fetch('http://169.254.169.254/latest/meta-data/local-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('private-ip').textContent = data);
            
        fetch('http://169.254.169.254/latest/meta-data/public-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('public-ip').textContent = data)
            .catch(() => document.getElementById('public-ip').textContent = 'N/A (Private Instance)');
    </script>
</body>
</html>
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -a start

# Create maintenance scripts
mkdir -p /opt/cloudops
cat > /opt/cloudops/maintenance.sh << 'EOF'
#!/bin/bash
# CloudOps maintenance script

case "$1" in
    update)
        echo "Updating system packages..."
        apt-get update -y && apt-get upgrade -y
        ;;
    restart)
        echo "Restarting nginx service..."
        systemctl restart nginx
        ;;
    status)
        echo "Checking service status..."
        systemctl status nginx --no-pager
        systemctl status amazon-ssm-agent --no-pager
        ;;
    install)
        echo "Installing additional tools..."
        apt-get install -y htop curl wget unzip
        ;;
    *)
        echo "Usage: $0 {update|restart|status|install}"
        exit 1
        ;;
esac
EOF

chmod +x /opt/cloudops/maintenance.sh

echo "SSM setup completed at $(date)!"
echo "Instance is ready for Systems Manager operations"