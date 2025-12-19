#!/bin/bash
# Install and configure Apache web server

yum update -y
yum install -y httpd

# Get instance information from metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Create simple web page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>HA Web Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f4f4f4;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 0 auto;
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        .info {
            margin: 15px 0;
            padding: 10px;
            background: #f8f9fa;
            border-left: 4px solid #007bff;
        }
        .label {
            font-weight: bold;
            color: #555;
        }
        .value {
            color: #007bff;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Web Server Running</h1>
        <div class="info">
            <span class="label">Instance ID:</span>
            <span class="value">$INSTANCE_ID</span>
        </div>
        <div class="info">
            <span class="label">Availability Zone:</span>
            <span class="value">$AZ</span>
        </div>
        <div class="info">
            <span class="label">Private IP:</span>
            <span class="value">$PRIVATE_IP</span>
        </div>
        <div class="info">
            <span class="label">Status:</span>
            <span class="value">Active</span>
        </div>
    </div>
</body>
</html>
EOF

# Start Apache
systemctl start httpd
systemctl enable httpd
