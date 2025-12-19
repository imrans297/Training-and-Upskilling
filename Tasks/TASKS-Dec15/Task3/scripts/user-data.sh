#!/bin/bash

# Basic server setup script
yum update -y

# Install some useful packages
yum install -y htop tree wget curl git

# Change hostname
hostnamectl set-hostname ${hostname}

# Disable root login for security
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install apache web server
yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Create simple web page
cat > /var/www/html/index.html << 'EOF'
<html>
<head><title>Server Info</title></head>
<body>
<h1>Server Details</h1>
<p>Hostname: HOSTNAME_PLACEHOLDER</p>
<p>This is a test server in my VPC setup</p>
</body>
</html>
EOF

# Replace placeholder with actual hostname
sed -i "s/HOSTNAME_PLACEHOLDER/${hostname}/g" /var/www/html/index.html

# Fix file ownership
chown apache:apache /var/www/html/index.html

# Log that setup is done
echo "Setup completed on $(date)" >> /var/log/setup.log