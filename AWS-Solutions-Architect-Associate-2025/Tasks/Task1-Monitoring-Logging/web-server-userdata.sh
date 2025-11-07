#!/bin/bash
yum update -y
yum install -y httpd

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create web application
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>Monitoring Demo Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
        .container { max-width: 800px; margin: 0 auto; }
        .metrics { background: #f0f8ff; padding: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Web Server Monitoring Demo</h1>
        <div class="metrics">
            <h2>Server Information</h2>
            <p><strong>Server:</strong> <span id="hostname"></span></p>
            <p><strong>Instance ID:</strong> <span id="instanceId"></span></p>
            <p><strong>Load Time:</strong> <span id="loadTime"></span>ms</p>
            <p><strong>Timestamp:</strong> <span id="timestamp"></span></p>
        </div>
        <div class="metrics">
            <h2>Health Status</h2>
            <p>Status: <span style="color: green;">Healthy</span></p>
            <p>CloudWatch Agent: <span style="color: green;">Active</span></p>
        </div>
    </div>
    
    <script>
        document.getElementById('hostname').textContent = window.location.hostname;
        document.getElementById('loadTime').textContent = Math.round(performance.now());
        document.getElementById('timestamp').textContent = new Date().toISOString();
        
        // Get instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instanceId').textContent = data)
            .catch(err => document.getElementById('instanceId').textContent = 'N/A');
    </script>
</body>
</html>
HTML

# Create health check endpoint
echo "OK" > /var/www/html/health

# Start Apache
systemctl start httpd
systemctl enable httpd

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'JSON'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/webserver/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/webserver/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CustomApp/WebServer",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  }
}
JSON

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Log startup
echo "$(date): Web server with CloudWatch monitoring started" >> /var/log/app-startup.log