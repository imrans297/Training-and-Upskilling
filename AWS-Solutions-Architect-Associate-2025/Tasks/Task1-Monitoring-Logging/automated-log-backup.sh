#!/bin/bash
# Automated log backup to S3

LOG_DATE=$(date +%Y-%m-%d)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Backup Apache logs
tar -czf /tmp/apache-logs-${INSTANCE_ID}-${LOG_DATE}.tar.gz /var/log/httpd/

# Upload to S3
aws s3 cp /tmp/apache-logs-${INSTANCE_ID}-${LOG_DATE}.tar.gz \
  s3://monitoring-logs-storage-12366645/automated-backups/

# Backup system logs
tar -czf /tmp/system-logs-${INSTANCE_ID}-${LOG_DATE}.tar.gz /var/log/messages /var/log/secure

aws s3 cp /tmp/system-logs-${INSTANCE_ID}-${LOG_DATE}.tar.gz \
  s3://monitoring-logs-storage-12366645/automated-backups/

# Clean up local files older than 7 days
find /tmp/ -name "*logs-*.tar.gz" -mtime +7 -delete

echo "Log backup completed for ${INSTANCE_ID} on ${LOG_DATE}"