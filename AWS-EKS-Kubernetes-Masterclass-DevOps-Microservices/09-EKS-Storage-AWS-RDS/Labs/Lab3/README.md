# Lab 3: RDS Performance and Security

## What We're Achieving
Optimize RDS performance and implement security best practices for production workloads.

## What We're Doing
- Monitor RDS performance metrics
- Implement connection pooling with ProxySQL
- Configure SSL/TLS connections
- Set up database audit logging

## Prerequisites
- Completed Lab 1 and Lab 2
- RDS instance running
- kubectl configured

## Lab Exercises

### Exercise 1: RDS Performance Monitoring
```bash
# Create monitoring dashboard
cat > monitoring-job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: rds-monitor
  namespace: storage-rds
spec:
  template:
    spec:
      containers:
      - name: monitor
        image: mysql:8.0
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "=== RDS Performance Metrics ==="
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SELECT 
            VARIABLE_NAME, 
            VARIABLE_VALUE 
          FROM performance_schema.global_status 
          WHERE VARIABLE_NAME IN (
            'Threads_connected',
            'Threads_running',
            'Questions',
            'Slow_queries',
            'Uptime'
          );"
          
          echo -e "\n=== Active Connections ==="
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "SHOW PROCESSLIST;"
          
          echo -e "\n=== Database Sizes ==="
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SELECT 
            table_schema AS 'Database',
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
          FROM information_schema.tables
          GROUP BY table_schema;"
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: host
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: password
      restartPolicy: Never
EOF

kubectl apply -f monitoring-job.yaml
kubectl wait --for=condition=complete job/rds-monitor -n storage-rds --timeout=60s
kubectl logs job/rds-monitor -n storage-rds
```

### Exercise 2: Connection Pooling with ProxySQL
```bash
# Deploy ProxySQL for connection pooling
cat > proxysql-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: proxysql
  namespace: storage-rds
spec:
  replicas: 1
  selector:
    matchLabels:
      app: proxysql
  template:
    metadata:
      labels:
        app: proxysql
    spec:
      containers:
      - name: proxysql
        image: proxysql/proxysql:latest
        ports:
        - containerPort: 6033
        - containerPort: 6032
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: host
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: password
---
apiVersion: v1
kind: Service
metadata:
  name: proxysql-service
  namespace: storage-rds
spec:
  selector:
    app: proxysql
  ports:
  - name: mysql
    port: 6033
    targetPort: 6033
  - name: admin
    port: 6032
    targetPort: 6032
EOF

kubectl apply -f proxysql-deployment.yaml
kubectl wait --for=condition=Available deployment/proxysql -n storage-rds --timeout=120s
```

### Exercise 3: SSL/TLS Connection Security
```bash
# Test SSL connection
cat > ssl-test-job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ssl-connection-test
  namespace: storage-rds
spec:
  template:
    spec:
      containers:
      - name: ssl-test
        image: mysql:8.0
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Testing SSL connection..."
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD --ssl-mode=REQUIRED -e "
          SHOW STATUS LIKE 'Ssl_cipher';
          SHOW VARIABLES LIKE '%ssl%';"
          echo "SSL connection test completed"
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: host
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: password
      restartPolicy: Never
EOF

kubectl apply -f ssl-test-job.yaml
kubectl logs job/ssl-connection-test -n storage-rds
```

### Exercise 4: Database Security Audit
```bash
# Run security audit
cat > security-audit-job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: security-audit
  namespace: storage-rds
spec:
  template:
    spec:
      containers:
      - name: audit
        image: mysql:8.0
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "=== Security Audit Report ==="
          
          echo -e "\n1. User Privileges:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SELECT user, host FROM mysql.user;"
          
          echo -e "\n2. Database Access:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SELECT * FROM information_schema.schema_privileges;"
          
          echo -e "\n3. SSL Status:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SHOW VARIABLES LIKE 'have_ssl';"
          
          echo -e "\n4. Password Policy:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SHOW VARIABLES LIKE 'validate_password%';"
          
          echo "Audit completed"
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: host
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: password
      restartPolicy: Never
EOF

kubectl apply -f security-audit-job.yaml
kubectl logs job/security-audit -n storage-rds
```

### Exercise 5: Query Performance Analysis
```bash
# Analyze slow queries
cat > query-analysis-job.yaml << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: query-analysis
  namespace: storage-rds
spec:
  template:
    spec:
      containers:
      - name: analyzer
        image: mysql:8.0
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "=== Query Performance Analysis ==="
          
          echo -e "\n1. Slow Query Log Status:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SHOW VARIABLES LIKE 'slow_query%';"
          
          echo -e "\n2. Query Cache Statistics:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e "
          SHOW STATUS LIKE 'Qcache%';"
          
          echo -e "\n3. Table Statistics:"
          mysql -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD webapp -e "
          SELECT 
            TABLE_NAME,
            TABLE_ROWS,
            AVG_ROW_LENGTH,
            DATA_LENGTH,
            INDEX_LENGTH
          FROM information_schema.TABLES
          WHERE TABLE_SCHEMA = 'webapp';"
          
          echo "Analysis completed"
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: host
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: username
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-credentials
              key: password
      restartPolicy: Never
EOF

kubectl apply -f query-analysis-job.yaml
kubectl logs job/query-analysis -n storage-rds
```

## Cleanup
```bash
kubectl delete -f monitoring-job.yaml
kubectl delete -f proxysql-deployment.yaml
kubectl delete -f ssl-test-job.yaml
kubectl delete -f security-audit-job.yaml
kubectl delete -f query-analysis-job.yaml
rm -f monitoring-job.yaml proxysql-deployment.yaml ssl-test-job.yaml security-audit-job.yaml query-analysis-job.yaml
```

## Key Takeaways
1. Monitor RDS performance metrics regularly
2. Use connection pooling for better resource utilization
3. Always enable SSL/TLS for database connections
4. Implement regular security audits
5. Analyze query performance to optimize database
6. Follow principle of least privilege for database users
7. Enable encryption at rest and in transit

## Next Steps
- Implement CloudWatch monitoring
- Set up automated performance alerts
- Configure read replicas for scaling
- Explore Aurora Serverless options
