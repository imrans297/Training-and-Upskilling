#!/bin/bash
set -e

# Update system
yum update -y

# Install Apache
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Configure firewall
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

echo "Installation completed successfully"