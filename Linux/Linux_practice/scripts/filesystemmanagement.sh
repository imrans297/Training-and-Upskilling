#!/bin/bash
# Log analysis and monitoring

LOG_DIR="$HOME/log_analysis"
mkdir -p "$LOG_DIR"
cd "$LOG_DIR"

# Create realistic log files
cat << 'EOF' > web_access.log
192.168.1.100 - - [18/Dec/2023:10:30:15 +0000] "GET /index.html HTTP/1.1" 200 1234
192.168.1.101 - - [18/Dec/2023:10:30:16 +0000] "GET /about.html HTTP/1.1" 200 2345
192.168.1.100 - - [18/Dec/2023:10:30:17 +0000] "POST /login HTTP/1.1" 200 567
192.168.1.102 - - [18/Dec/2023:10:30:18 +0000] "GET /products.html HTTP/1.1" 404 0
192.168.1.101 - - [18/Dec/2023:10:30:19 +0000] "GET /contact.html HTTP/1.1" 200 1890
192.168.1.103 - - [18/Dec/2023:10:30:20 +0000] "GET /admin HTTP/1.1" 403 0
192.168.1.100 - - [18/Dec/2023:10:30:21 +0000] "GET /images/logo.png HTTP/1.1" 200 45678
192.168.1.104 - - [18/Dec/2023:10:30:22 +0000] "GET /api/data HTTP/1.1" 500 0
EOF

cat << 'EOF' > application.log
2023-12-18 10:30:15 INFO Application started successfully
2023-12-18 10:30:20 INFO Database connection established
2023-12-18 10:30:25 WARNING High memory usage detected: 85%
2023-12-18 10:30:30 INFO User authentication successful: user123
2023-12-18 10:30:35 ERROR Failed to load configuration file
2023-12-18 10:30:40 INFO Configuration loaded from backup
2023-12-18 10:30:45 WARNING Disk space low: 90% used
2023-12-18 10:30:50 ERROR Database query timeout
2023-12-18 10:30:55 INFO Query retry successful
2023-12-18 10:31:00 INFO Backup process started
EOF

echo "=== LOG ANALYSIS CHALLENGE ==="

echo "1. Web Access Log Analysis:"
echo "   Total requests: $(wc -l < web_access.log)"
echo "   Unique IP addresses:"
awk '{print $1}' web_access.log | sort | uniq
echo "   HTTP status codes:"
awk '{print $9}' web_access.log | sort | uniq -c
echo "   Most requested files:"
awk '{print $7}' web_access.log | sort | uniq -c | sort -nr
echo "   Error requests (4xx, 5xx):"
awk '$9 >= 400 {print $0}' web_access.log

echo -e "\n2. Application Log Analysis:"
echo "   Total log entries: $(wc -l < application.log)"
echo "   Log level distribution:"
awk '{print $3}' application.log | sort | uniq -c
echo "   Error messages:"
grep "ERROR" application.log
echo "   Warning messages:"
grep "WARNING" application.log
echo "   Time range:"
echo "   First entry: $(head -1 application.log | awk '{print $1, $2}')"
echo "   Last entry: $(tail -1 application.log | awk '{print $1, $2}')"

echo -e "\n3. Combined Analysis:"
echo "   Total issues found:"
error_count=$(grep -c "ERROR" application.log)
warning_count=$(grep -c "WARNING" application.log)
http_errors=$(awk '$9 >= 400' web_access.log | wc -l)
echo "   Application errors: $error_count"
echo "   Application warnings: $warning_count"
echo "   HTTP errors: $http_errors"
echo "   Total issues: $((error_count + warning_count + http_errors))"
