#!/bin/bash
apt update -y
apt install -y apache2
systemctl start apache2
systemctl enable apache2

echo "<h1>SECONDARY REGION - $(hostname)</h1>" > /var/www/html/index.html
echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
echo "<p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>" >> /var/www/html/index.html
echo "OK" > /var/www/html/health

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html