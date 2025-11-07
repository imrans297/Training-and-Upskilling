# Section 17: Databases

## 📋 Overview
This section covers AWS database services including relational databases (RDS), NoSQL databases (DynamoDB), in-memory databases (ElastiCache), and data warehousing (Redshift).

## 🗄️ Amazon RDS (Relational Database Service)

### What is RDS?
- **Managed relational database**: Automated administration
- **Multiple engines**: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server, Aurora
- **High availability**: Multi-AZ deployments
- **Backup and recovery**: Automated backups and snapshots
- **Scaling**: Vertical and horizontal scaling options

### RDS Features
- **Read replicas**: Scale read workloads
- **Multi-AZ**: Automatic failover for high availability
- **Encryption**: At-rest and in-transit encryption
- **Monitoring**: Performance Insights and CloudWatch
- **Maintenance**: Automated patching and updates

## ⚡ Amazon Aurora

### What is Aurora?
- **Cloud-native database**: Built for the cloud
- **MySQL/PostgreSQL compatible**: Drop-in replacement
- **High performance**: Up to 5x faster than MySQL
- **Serverless**: On-demand, auto-scaling compute
- **Global database**: Cross-region replication

## 📊 Amazon DynamoDB

### What is DynamoDB?
- **NoSQL database**: Key-value and document database
- **Serverless**: Fully managed, no servers to manage
- **Performance**: Single-digit millisecond latency
- **Scaling**: Automatic scaling based on demand
- **Global tables**: Multi-region replication

### DynamoDB Features
- **On-demand billing**: Pay per request
- **Provisioned capacity**: Predictable performance
- **Streams**: Capture data changes
- **Global secondary indexes**: Additional query patterns
- **Point-in-time recovery**: Continuous backups

## 🚀 Amazon ElastiCache

### What is ElastiCache?
- **In-memory caching**: Redis and Memcached
- **High performance**: Microsecond latency
- **Scaling**: Horizontal and vertical scaling
- **High availability**: Multi-AZ with failover
- **Security**: VPC, encryption, and IAM integration

## 🏢 Amazon Redshift

### What is Redshift?
- **Data warehouse**: Petabyte-scale analytics
- **Columnar storage**: Optimized for analytics
- **Massively parallel**: Distributed processing
- **Serverless**: On-demand data warehousing
- **Integration**: Works with BI tools and AWS services

## 🛠️ Hands-On Practice

### Practice 1: RDS Multi-AZ with Read Replicas
**Objective**: Create RDS instance with high availability and read scaling

**Steps**:
1. **Create RDS Subnet Group**:
   ```bash
   # Get VPC and subnet information
   VPC_ID=$(aws ec2 describe-vpcs \
     --filters "Name=is-default,Values=true" \
     --query 'Vpcs[0].VpcId' --output text)
   
   SUBNET_IDS=$(aws ec2 describe-subnets \
     --filters "Name=vpc-id,Values=$VPC_ID" \
     --query 'Subnets[*].SubnetId' --output text)
   
   # Create DB subnet group
   aws rds create-db-subnet-group \
     --db-subnet-group-name my-db-subnet-group \
     --db-subnet-group-description "Subnet group for RDS instances" \
     --subnet-ids $SUBNET_IDS
   
   # Create security group for RDS
   SG_ID=$(aws ec2 create-security-group \
     --group-name rds-security-group \
     --description "Security group for RDS instances" \
     --vpc-id $VPC_ID \
     --query 'GroupId' --output text)
   
   # Allow MySQL/Aurora access from VPC
   aws ec2 authorize-security-group-ingress \
     --group-id $SG_ID \
     --protocol tcp \
     --port 3306 \
     --cidr 10.0.0.0/16
   ```

2. **Create RDS Instance with Multi-AZ**:
   ```bash
   # Create RDS MySQL instance
   aws rds create-db-instance \
     --db-instance-identifier my-mysql-db \
     --db-instance-class db.t3.micro \
     --engine mysql \
     --engine-version 8.0.35 \
     --master-username admin \
     --master-user-password MySecurePassword123! \
     --allocated-storage 20 \
     --storage-type gp2 \
     --vpc-security-group-ids $SG_ID \
     --db-subnet-group-name my-db-subnet-group \
     --multi-az \
     --backup-retention-period 7 \
     --storage-encrypted \
     --deletion-protection
   
   # Wait for instance to be available
   aws rds wait db-instance-available \
     --db-instance-identifier my-mysql-db
   
   # Get RDS endpoint
   RDS_ENDPOINT=$(aws rds describe-db-instances \
     --db-instance-identifier my-mysql-db \
     --query 'DBInstances[0].Endpoint.Address' --output text)
   
   echo "RDS Endpoint: $RDS_ENDPOINT"
   ```

3. **Create Read Replica**:
   ```bash
   # Create read replica in different AZ
   aws rds create-db-instance-read-replica \
     --db-instance-identifier my-mysql-read-replica \
     --source-db-instance-identifier my-mysql-db \
     --db-instance-class db.t3.micro
   
   # Wait for read replica to be available
   aws rds wait db-instance-available \
     --db-instance-identifier my-mysql-read-replica
   
   # Get read replica endpoint
   READ_REPLICA_ENDPOINT=$(aws rds describe-db-instances \
     --db-instance-identifier my-mysql-read-replica \
     --query 'DBInstances[0].Endpoint.Address' --output text)
   
   echo "Read Replica Endpoint: $READ_REPLICA_ENDPOINT"
   ```

4. **Test Database Connection and Operations**:
   ```bash
   # Create test script for database operations
   cat > test_rds.py << 'EOF'
   import mysql.connector
   import time
   import random
   
   # Database configuration
   primary_config = {
       'host': 'RDS_ENDPOINT_HERE',
       'user': 'admin',
       'password': 'MySecurePassword123!',
       'database': 'testdb'
   }
   
   replica_config = {
       'host': 'READ_REPLICA_ENDPOINT_HERE',
       'user': 'admin',
       'password': 'MySecurePassword123!',
       'database': 'testdb'
   }
   
   def create_database_and_table():
       """Create database and sample table"""
       try:
           # Connect to primary
           conn = mysql.connector.connect(
               host=primary_config['host'],
               user=primary_config['user'],
               password=primary_config['password']
           )
           cursor = conn.cursor()
           
           # Create database
           cursor.execute("CREATE DATABASE IF NOT EXISTS testdb")
           cursor.execute("USE testdb")
           
           # Create sample table
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS users (
                   id INT AUTO_INCREMENT PRIMARY KEY,
                   name VARCHAR(100) NOT NULL,
                   email VARCHAR(100) UNIQUE NOT NULL,
                   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
               )
           """)
           
           conn.commit()
           print("Database and table created successfully")
           
       except Exception as e:
           print(f"Error creating database: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   def insert_sample_data():
       """Insert sample data into primary database"""
       try:
           conn = mysql.connector.connect(**primary_config)
           cursor = conn.cursor()
           
           # Insert sample users
           users = [
               ('John Doe', 'john@example.com'),
               ('Jane Smith', 'jane@example.com'),
               ('Bob Johnson', 'bob@example.com'),
               ('Alice Brown', 'alice@example.com')
           ]
           
           cursor.executemany(
               "INSERT INTO users (name, email) VALUES (%s, %s)",
               users
           )
           
           conn.commit()
           print(f"Inserted {cursor.rowcount} users")
           
       except Exception as e:
           print(f"Error inserting data: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   def read_from_primary():
       """Read data from primary database"""
       try:
           conn = mysql.connector.connect(**primary_config)
           cursor = conn.cursor()
           
           cursor.execute("SELECT * FROM users ORDER BY created_at DESC")
           results = cursor.fetchall()
           
           print("Data from Primary Database:")
           for row in results:
               print(f"ID: {row[0]}, Name: {row[1]}, Email: {row[2]}")
           
       except Exception as e:
           print(f"Error reading from primary: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   def read_from_replica():
       """Read data from read replica"""
       try:
           conn = mysql.connector.connect(**replica_config)
           cursor = conn.cursor()
           
           cursor.execute("SELECT COUNT(*) FROM users")
           count = cursor.fetchone()[0]
           
           print(f"Total users in Read Replica: {count}")
           
           cursor.execute("SELECT * FROM users LIMIT 5")
           results = cursor.fetchall()
           
           print("Sample data from Read Replica:")
           for row in results:
               print(f"ID: {row[0]}, Name: {row[1]}, Email: {row[2]}")
           
       except Exception as e:
           print(f"Error reading from replica: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   if __name__ == "__main__":
       print("Setting up RDS test...")
       create_database_and_table()
       time.sleep(5)  # Wait for replication
       
       print("\nInserting sample data...")
       insert_sample_data()
       time.sleep(10)  # Wait for replication to read replica
       
       print("\nReading from primary database...")
       read_from_primary()
       
       print("\nReading from read replica...")
       read_from_replica()
   EOF
   
   # Install MySQL connector
   pip install mysql-connector-python
   
   # Update endpoints in script and run
   sed -i "s/RDS_ENDPOINT_HERE/$RDS_ENDPOINT/g" test_rds.py
   sed -i "s/READ_REPLICA_ENDPOINT_HERE/$READ_REPLICA_ENDPOINT/g" test_rds.py
   
   python3 test_rds.py
   ```

**Screenshot Placeholder**:
![RDS Multi-AZ Setup](screenshots/17-rds-multi-az-setup.png)
*Caption: RDS MySQL instance with Multi-AZ and read replica*

### Practice 2: DynamoDB with Global Secondary Index
**Objective**: Create DynamoDB table with GSI and perform various operations

**Steps**:
1. **Create DynamoDB Table**:
   ```bash
   # Create DynamoDB table with GSI
   aws dynamodb create-table \
     --table-name UserProfiles \
     --attribute-definitions \
       AttributeName=userId,AttributeType=S \
       AttributeName=email,AttributeType=S \
       AttributeName=department,AttributeType=S \
       AttributeName=createdAt,AttributeType=S \
     --key-schema \
       AttributeName=userId,KeyType=HASH \
     --global-secondary-indexes \
       IndexName=EmailIndex,KeySchema=[{AttributeName=email,KeyType=HASH}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
       IndexName=DepartmentIndex,KeySchema=[{AttributeName=department,KeyType=HASH},{AttributeName=createdAt,KeyType=RANGE}],Projection={ProjectionType=ALL},ProvisionedThroughput={ReadCapacityUnits=5,WriteCapacityUnits=5} \
     --provisioned-throughput \
       ReadCapacityUnits=10,WriteCapacityUnits=10
   
   # Wait for table to be active
   aws dynamodb wait table-exists --table-name UserProfiles
   
   # Describe table
   aws dynamodb describe-table --table-name UserProfiles
   ```

2. **Insert Sample Data**:
   ```bash
   # Create script to populate DynamoDB
   cat > populate_dynamodb.py << 'EOF'
   import boto3
   import json
   from datetime import datetime, timedelta
   import random
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('UserProfiles')
   
   # Sample data
   departments = ['Engineering', 'Marketing', 'Sales', 'HR', 'Finance']
   first_names = ['John', 'Jane', 'Bob', 'Alice', 'Charlie', 'Diana', 'Eve', 'Frank']
   last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis']
   
   def generate_user_data(user_id):
       first_name = random.choice(first_names)
       last_name = random.choice(last_names)
       department = random.choice(departments)
       
       # Generate date within last year
       days_ago = random.randint(1, 365)
       created_date = datetime.now() - timedelta(days=days_ago)
       
       return {
           'userId': f'user_{user_id:04d}',
           'email': f'{first_name.lower()}.{last_name.lower()}@company.com',
           'firstName': first_name,
           'lastName': last_name,
           'department': department,
           'salary': random.randint(50000, 150000),
           'isActive': random.choice([True, False]),
           'skills': random.sample(['Python', 'Java', 'JavaScript', 'AWS', 'Docker', 'Kubernetes'], 
                                 random.randint(2, 4)),
           'createdAt': created_date.isoformat(),
           'lastLogin': (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat()
       }
   
   def batch_write_users(start_id, count):
       """Batch write users to DynamoDB"""
       with table.batch_writer() as batch:
           for i in range(start_id, start_id + count):
               user_data = generate_user_data(i)
               batch.put_item(Item=user_data)
               print(f"Added user: {user_data['userId']}")
   
   if __name__ == "__main__":
       print("Populating DynamoDB table with sample data...")
       
       # Insert 50 users in batches
       batch_size = 25
       for batch_start in range(1, 51, batch_size):
           batch_write_users(batch_start, min(batch_size, 51 - batch_start))
           print(f"Completed batch starting at user_{batch_start:04d}")
       
       print("Data population completed!")
   EOF
   
   python3 populate_dynamodb.py
   ```

3. **Query and Scan Operations**:
   ```bash
   # Create script for DynamoDB operations
   cat > dynamodb_operations.py << 'EOF'
   import boto3
   from boto3.dynamodb.conditions import Key, Attr
   import json
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('UserProfiles')
   
   def query_by_user_id(user_id):
       """Query by primary key"""
       print(f"\n=== Querying user: {user_id} ===")
       
       response = table.get_item(Key={'userId': user_id})
       
       if 'Item' in response:
           user = response['Item']
           print(f"Name: {user['firstName']} {user['lastName']}")
           print(f"Email: {user['email']}")
           print(f"Department: {user['department']}")
           print(f"Salary: ${user['salary']:,}")
       else:
           print("User not found")
   
   def query_by_email(email):
       """Query using Global Secondary Index"""
       print(f"\n=== Querying by email: {email} ===")
       
       response = table.query(
           IndexName='EmailIndex',
           KeyConditionExpression=Key('email').eq(email)
       )
       
       for item in response['Items']:
           print(f"User ID: {item['userId']}")
           print(f"Name: {item['firstName']} {item['lastName']}")
           print(f"Department: {item['department']}")
   
   def query_by_department(department):
       """Query by department using GSI"""
       print(f"\n=== Users in {department} department ===")
       
       response = table.query(
           IndexName='DepartmentIndex',
           KeyConditionExpression=Key('department').eq(department)
       )
       
       print(f"Found {response['Count']} users in {department}")
       for item in response['Items']:
           print(f"- {item['firstName']} {item['lastName']} ({item['email']})")
   
   def scan_active_users():
       """Scan for active users"""
       print(f"\n=== Active Users ===")
       
       response = table.scan(
           FilterExpression=Attr('isActive').eq(True)
       )
       
       print(f"Found {response['Count']} active users")
       for item in response['Items']:
           print(f"- {item['firstName']} {item['lastName']} - {item['department']}")
   
   def scan_high_salary_users():
       """Scan for users with high salary"""
       print(f"\n=== High Salary Users (>$100k) ===")
       
       response = table.scan(
           FilterExpression=Attr('salary').gt(100000)
       )
       
       print(f"Found {response['Count']} high salary users")
       for item in response['Items']:
           print(f"- {item['firstName']} {item['lastName']}: ${item['salary']:,}")
   
   def update_user_salary(user_id, new_salary):
       """Update user salary"""
       print(f"\n=== Updating salary for {user_id} ===")
       
       response = table.update_item(
           Key={'userId': user_id},
           UpdateExpression='SET salary = :salary, lastUpdated = :timestamp',
           ExpressionAttributeValues={
               ':salary': new_salary,
               ':timestamp': datetime.now().isoformat()
           },
           ReturnValues='UPDATED_NEW'
       )
       
       print(f"Updated attributes: {response['Attributes']}")
   
   if __name__ == "__main__":
       # Test various operations
       query_by_user_id('user_0001')
       query_by_email('john.smith@company.com')
       query_by_department('Engineering')
       scan_active_users()
       scan_high_salary_users()
       
       # Update operation
       from datetime import datetime
       update_user_salary('user_0001', 95000)
   EOF
   
   python3 dynamodb_operations.py
   ```

4. **Enable DynamoDB Streams**:
   ```bash
   # Enable streams on the table
   aws dynamodb update-table \
     --table-name UserProfiles \
     --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES
   
   # Get stream ARN
   STREAM_ARN=$(aws dynamodb describe-table \
     --table-name UserProfiles \
     --query 'Table.LatestStreamArn' --output text)
   
   echo "Stream ARN: $STREAM_ARN"
   
   # Create Lambda function to process stream events
   cat > stream_processor.py << 'EOF'
   import json
   import boto3
   
   def lambda_handler(event, context):
       print(f"Processing {len(event['Records'])} DynamoDB stream records")
       
       for record in event['Records']:
           event_name = record['eventName']
           
           if event_name == 'INSERT':
               print(f"New user created: {record['dynamodb']['NewImage']['userId']['S']}")
           elif event_name == 'MODIFY':
               print(f"User modified: {record['dynamodb']['Keys']['userId']['S']}")
           elif event_name == 'REMOVE':
               print(f"User deleted: {record['dynamodb']['OldImage']['userId']['S']}")
       
       return {'statusCode': 200, 'body': 'Stream processed successfully'}
   EOF
   
   zip stream_processor.zip stream_processor.py
   
   # Create Lambda function for stream processing
   aws lambda create-function \
     --function-name dynamodb-stream-processor \
     --runtime python3.9 \
     --role arn:aws:iam::ACCOUNT_ID:role/lambda-execution-role \
     --handler stream_processor.lambda_handler \
     --zip-file fileb://stream_processor.zip
   
   # Create event source mapping
   aws lambda create-event-source-mapping \
     --event-source-arn $STREAM_ARN \
     --function-name dynamodb-stream-processor \
     --starting-position LATEST
   ```

**Screenshot Placeholder**:
![DynamoDB GSI Operations](screenshots/17-dynamodb-gsi-operations.png)
*Caption: DynamoDB table with Global Secondary Index and stream processing*

### Practice 3: Aurora Serverless v2
**Objective**: Create Aurora Serverless cluster with auto-scaling

**Steps**:
1. **Create Aurora Serverless Cluster**:
   ```bash
   # Create Aurora Serverless v2 cluster
   aws rds create-db-cluster \
     --db-cluster-identifier my-aurora-serverless \
     --engine aurora-mysql \
     --engine-version 8.0.mysql_aurora.3.02.0 \
     --master-username admin \
     --master-user-password MyAuroraPassword123! \
     --database-name sampledb \
     --vpc-security-group-ids $SG_ID \
     --db-subnet-group-name my-db-subnet-group \
     --serverless-v2-scaling-configuration MinCapacity=0.5,MaxCapacity=4.0 \
     --storage-encrypted
   
   # Create Aurora Serverless instance
   aws rds create-db-instance \
     --db-instance-identifier my-aurora-serverless-instance \
     --db-instance-class db.serverless \
     --engine aurora-mysql \
     --db-cluster-identifier my-aurora-serverless
   
   # Wait for cluster to be available
   aws rds wait db-cluster-available \
     --db-cluster-identifier my-aurora-serverless
   
   # Get cluster endpoint
   AURORA_ENDPOINT=$(aws rds describe-db-clusters \
     --db-cluster-identifier my-aurora-serverless \
     --query 'DBClusters[0].Endpoint' --output text)
   
   echo "Aurora Serverless Endpoint: $AURORA_ENDPOINT"
   ```

2. **Test Aurora Serverless Scaling**:
   ```bash
   # Create load testing script
   cat > aurora_load_test.py << 'EOF'
   import mysql.connector
   import threading
   import time
   import random
   
   # Aurora configuration
   aurora_config = {
       'host': 'AURORA_ENDPOINT_HERE',
       'user': 'admin',
       'password': 'MyAuroraPassword123!',
       'database': 'sampledb'
   }
   
   def create_test_table():
       """Create test table for load testing"""
       try:
           conn = mysql.connector.connect(**aurora_config)
           cursor = conn.cursor()
           
           cursor.execute("""
               CREATE TABLE IF NOT EXISTS load_test (
                   id INT AUTO_INCREMENT PRIMARY KEY,
                   data VARCHAR(1000),
                   timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                   random_number INT
               )
           """)
           
           conn.commit()
           print("Test table created")
           
       except Exception as e:
           print(f"Error creating table: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   def generate_load(thread_id, duration_seconds):
       """Generate database load"""
       print(f"Thread {thread_id} starting load generation for {duration_seconds} seconds")
       
       try:
           conn = mysql.connector.connect(**aurora_config)
           cursor = conn.cursor()
           
           start_time = time.time()
           operations = 0
           
           while time.time() - start_time < duration_seconds:
               # Insert operation
               data = f"Load test data from thread {thread_id} - {random.randint(1000, 9999)}"
               random_num = random.randint(1, 1000000)
               
               cursor.execute(
                   "INSERT INTO load_test (data, random_number) VALUES (%s, %s)",
                   (data, random_num)
               )
               
               # Read operation
               cursor.execute(
                   "SELECT COUNT(*) FROM load_test WHERE random_number > %s",
                   (random.randint(1, 500000),)
               )
               result = cursor.fetchone()
               
               operations += 2
               
               if operations % 100 == 0:
                   conn.commit()
                   print(f"Thread {thread_id}: {operations} operations completed")
               
               time.sleep(0.01)  # Small delay
           
           conn.commit()
           print(f"Thread {thread_id} completed {operations} operations")
           
       except Exception as e:
           print(f"Thread {thread_id} error: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   def monitor_scaling():
       """Monitor Aurora scaling"""
       print("Monitoring Aurora Serverless scaling...")
       
       # This would typically involve CloudWatch metrics
       # For demo purposes, we'll just show connection info
       try:
           conn = mysql.connector.connect(**aurora_config)
           cursor = conn.cursor()
           
           cursor.execute("SHOW PROCESSLIST")
           processes = cursor.fetchall()
           print(f"Active connections: {len(processes)}")
           
           cursor.execute("SELECT @@aurora_server_id")
           server_id = cursor.fetchone()[0]
           print(f"Aurora Server ID: {server_id}")
           
       except Exception as e:
           print(f"Monitoring error: {e}")
       finally:
           if conn.is_connected():
               conn.close()
   
   if __name__ == "__main__":
       print("Setting up Aurora Serverless load test...")
       create_test_table()
       
       print("Starting load generation with multiple threads...")
       threads = []
       
       # Create 5 threads to generate load
       for i in range(5):
           thread = threading.Thread(
               target=generate_load,
               args=(i + 1, 300)  # 5 minutes of load
           )
           threads.append(thread)
           thread.start()
       
       # Monitor scaling in main thread
       for _ in range(30):  # Monitor for 5 minutes
           monitor_scaling()
           time.sleep(10)
       
       # Wait for all threads to complete
       for thread in threads:
           thread.join()
       
       print("Load test completed!")
   EOF
   
   # Update endpoint and run load test
   sed -i "s/AURORA_ENDPOINT_HERE/$AURORA_ENDPOINT/g" aurora_load_test.py
   python3 aurora_load_test.py
   ```

**Screenshot Placeholder**:
![Aurora Serverless Scaling](screenshots/17-aurora-serverless-scaling.png)
*Caption: Aurora Serverless v2 with auto-scaling configuration*

### Practice 4: ElastiCache Redis Cluster
**Objective**: Set up ElastiCache Redis with clustering and failover

**Steps**:
1. **Create ElastiCache Subnet Group**:
   ```bash
   # Create ElastiCache subnet group
   aws elasticache create-cache-subnet-group \
     --cache-subnet-group-name my-cache-subnet-group \
     --cache-subnet-group-description "Subnet group for ElastiCache" \
     --subnet-ids $SUBNET_IDS
   
   # Create security group for ElastiCache
   CACHE_SG_ID=$(aws ec2 create-security-group \
     --group-name elasticache-security-group \
     --description "Security group for ElastiCache" \
     --vpc-id $VPC_ID \
     --query 'GroupId' --output text)
   
   # Allow Redis access from VPC
   aws ec2 authorize-security-group-ingress \
     --group-id $CACHE_SG_ID \
     --protocol tcp \
     --port 6379 \
     --cidr 10.0.0.0/16
   ```

2. **Create Redis Replication Group**:
   ```bash
   # Create Redis replication group with clustering
   aws elasticache create-replication-group \
     --replication-group-id my-redis-cluster \
     --description "Redis cluster with failover" \
     --node-type cache.t3.micro \
     --engine redis \
     --engine-version 7.0 \
     --num-cache-clusters 3 \
     --cache-subnet-group-name my-cache-subnet-group \
     --security-group-ids $CACHE_SG_ID \
     --automatic-failover-enabled \
     --multi-az-enabled \
     --at-rest-encryption-enabled \
     --transit-encryption-enabled \
     --auth-token MyRedisAuthToken123!
   
   # Wait for replication group to be available
   aws elasticache wait replication-group-available \
     --replication-group-id my-redis-cluster
   
   # Get Redis endpoint
   REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
     --replication-group-id my-redis-cluster \
     --query 'ReplicationGroups[0].RedisEndpoint.Address' --output text)
   
   echo "Redis Endpoint: $REDIS_ENDPOINT"
   ```

3. **Test Redis Operations**:
   ```bash
   # Create Redis testing script
   cat > test_redis.py << 'EOF'
   import redis
   import json
   import time
   import random
   from datetime import datetime, timedelta
   
   # Redis configuration
   redis_config = {
       'host': 'REDIS_ENDPOINT_HERE',
       'port': 6379,
       'password': 'MyRedisAuthToken123!',
       'ssl': True,
       'decode_responses': True
   }
   
   def test_basic_operations():
       """Test basic Redis operations"""
       print("=== Testing Basic Redis Operations ===")
       
       r = redis.Redis(**redis_config)
       
       # String operations
       r.set('user:1001:name', 'John Doe')
       r.set('user:1001:email', 'john@example.com')
       r.expire('user:1001:name', 3600)  # Expire in 1 hour
       
       name = r.get('user:1001:name')
       email = r.get('user:1001:email')
       print(f"User: {name}, Email: {email}")
       
       # Hash operations
       user_data = {
           'name': 'Jane Smith',
           'email': 'jane@example.com',
           'department': 'Engineering',
           'salary': '95000'
       }
       r.hset('user:1002', mapping=user_data)
       
       retrieved_user = r.hgetall('user:1002')
       print(f"User hash: {retrieved_user}")
       
       # List operations
       r.lpush('recent_logins', 'user:1001', 'user:1002', 'user:1003')
       recent = r.lrange('recent_logins', 0, 4)
       print(f"Recent logins: {recent}")
       
       # Set operations
       r.sadd('active_users', 'user:1001', 'user:1002', 'user:1003')
       active_count = r.scard('active_users')
       print(f"Active users count: {active_count}")
       
       # Sorted set operations
       r.zadd('leaderboard', {'user:1001': 1500, 'user:1002': 1200, 'user:1003': 1800})
       top_users = r.zrevrange('leaderboard', 0, 2, withscores=True)
       print(f"Top users: {top_users}")
   
   def test_session_management():
       """Test session management with Redis"""
       print("\n=== Testing Session Management ===")
       
       r = redis.Redis(**redis_config)
       
       # Create session data
       session_id = f"sess_{random.randint(100000, 999999)}"
       session_data = {
           'user_id': 'user:1001',
           'username': 'john_doe',
           'login_time': datetime.now().isoformat(),
           'last_activity': datetime.now().isoformat(),
           'permissions': json.dumps(['read', 'write', 'admin'])
       }
       
       # Store session with expiration
       r.hset(f'session:{session_id}', mapping=session_data)
       r.expire(f'session:{session_id}', 1800)  # 30 minutes
       
       # Retrieve session
       retrieved_session = r.hgetall(f'session:{session_id}')
       print(f"Session {session_id}: {retrieved_session}")
       
       # Update last activity
       r.hset(f'session:{session_id}', 'last_activity', datetime.now().isoformat())
       r.expire(f'session:{session_id}', 1800)  # Reset expiration
       
       print("Session updated successfully")
   
   def test_caching_pattern():
       """Test cache-aside pattern"""
       print("\n=== Testing Cache-Aside Pattern ===")
       
       r = redis.Redis(**redis_config)
       
       def get_user_profile(user_id):
           # Try to get from cache first
           cache_key = f'profile:{user_id}'
           cached_profile = r.get(cache_key)
           
           if cached_profile:
               print(f"Cache HIT for user {user_id}")
               return json.loads(cached_profile)
           
           print(f"Cache MISS for user {user_id}")
           
           # Simulate database fetch
           time.sleep(0.1)  # Simulate DB latency
           profile = {
               'user_id': user_id,
               'name': f'User {user_id}',
               'email': f'user{user_id}@example.com',
               'last_login': datetime.now().isoformat(),
               'preferences': {'theme': 'dark', 'language': 'en'}
           }
           
           # Store in cache with expiration
           r.setex(cache_key, 300, json.dumps(profile))  # 5 minutes
           
           return profile
       
       # Test cache pattern
       for user_id in [1001, 1002, 1001, 1003, 1001]:
           profile = get_user_profile(user_id)
           print(f"Retrieved profile for {profile['name']}")
   
   def test_pub_sub():
       """Test Redis pub/sub functionality"""
       print("\n=== Testing Pub/Sub ===")
       
       import threading
       
       r = redis.Redis(**redis_config)
       
       def subscriber():
           pubsub = r.pubsub()
           pubsub.subscribe('notifications')
           
           print("Subscriber started, waiting for messages...")
           for message in pubsub.listen():
               if message['type'] == 'message':
                   print(f"Received: {message['data']}")
                   if message['data'] == 'STOP':
                       break
           
           pubsub.unsubscribe('notifications')
           pubsub.close()
       
       # Start subscriber in separate thread
       sub_thread = threading.Thread(target=subscriber)
       sub_thread.start()
       
       time.sleep(1)  # Give subscriber time to start
       
       # Publish messages
       messages = [
           'User logged in',
           'New order received',
           'System maintenance scheduled',
           'STOP'
       ]
       
       for msg in messages:
           r.publish('notifications', msg)
           time.sleep(0.5)
       
       sub_thread.join()
       print("Pub/Sub test completed")
   
   if __name__ == "__main__":
       try:
           test_basic_operations()
           test_session_management()
           test_caching_pattern()
           test_pub_sub()
           
           print("\nAll Redis tests completed successfully!")
           
       except Exception as e:
           print(f"Redis test error: {e}")
   EOF
   
   # Install Redis Python client
   pip install redis
   
   # Update endpoint and run tests
   sed -i "s/REDIS_ENDPOINT_HERE/$REDIS_ENDPOINT/g" test_redis.py
   python3 test_redis.py
   ```

**Screenshot Placeholder**:
![ElastiCache Redis Cluster](screenshots/17-elasticache-redis-cluster.png)
*Caption: ElastiCache Redis cluster with replication and failover*

### Practice 5: Redshift Data Warehouse
**Objective**: Create Redshift cluster and perform analytics queries

**Steps**:
1. **Create Redshift Cluster**:
   ```bash
   # Create Redshift subnet group
   aws redshift create-cluster-subnet-group \
     --cluster-subnet-group-name my-redshift-subnet-group \
     --description "Subnet group for Redshift cluster" \
     --subnet-ids $SUBNET_IDS
   
   # Create security group for Redshift
   REDSHIFT_SG_ID=$(aws ec2 create-security-group \
     --group-name redshift-security-group \
     --description "Security group for Redshift cluster" \
     --vpc-id $VPC_ID \
     --query 'GroupId' --output text)
   
   # Allow Redshift access
   aws ec2 authorize-security-group-ingress \
     --group-id $REDSHIFT_SG_ID \
     --protocol tcp \
     --port 5439 \
     --cidr 10.0.0.0/16
   
   # Create Redshift cluster
   aws redshift create-cluster \
     --cluster-identifier my-redshift-cluster \
     --node-type dc2.large \
     --cluster-type single-node \
     --db-name analytics \
     --master-username admin \
     --master-user-password MyRedshiftPassword123! \
     --vpc-security-group-ids $REDSHIFT_SG_ID \
     --cluster-subnet-group-name my-redshift-subnet-group \
     --encrypted
   
   # Wait for cluster to be available
   aws redshift wait cluster-available \
     --cluster-identifier my-redshift-cluster
   
   # Get Redshift endpoint
   REDSHIFT_ENDPOINT=$(aws redshift describe-clusters \
     --cluster-identifier my-redshift-cluster \
     --query 'Clusters[0].Endpoint.Address' --output text)
   
   echo "Redshift Endpoint: $REDSHIFT_ENDPOINT"
   ```

2. **Load Sample Data and Run Analytics**:
   ```bash
   # Create Redshift analytics script
   cat > redshift_analytics.py << 'EOF'
   import psycopg2
   import pandas as pd
   from datetime import datetime, timedelta
   import random
   
   # Redshift configuration
   redshift_config = {
       'host': 'REDSHIFT_ENDPOINT_HERE',
       'port': 5439,
       'database': 'analytics',
       'user': 'admin',
       'password': 'MyRedshiftPassword123!'
   }
   
   def create_tables():
       """Create sample tables for analytics"""
       print("Creating analytics tables...")
       
       conn = psycopg2.connect(**redshift_config)
       cursor = conn.cursor()
       
       # Create sales table
       cursor.execute("""
           CREATE TABLE IF NOT EXISTS sales (
               sale_id INTEGER IDENTITY(1,1) PRIMARY KEY,
               product_id INTEGER NOT NULL,
               customer_id INTEGER NOT NULL,
               sale_date DATE NOT NULL,
               quantity INTEGER NOT NULL,
               unit_price DECIMAL(10,2) NOT NULL,
               total_amount DECIMAL(10,2) NOT NULL,
               region VARCHAR(50) NOT NULL,
               sales_rep VARCHAR(100) NOT NULL
           )
       """)
       
       # Create products table
       cursor.execute("""
           CREATE TABLE IF NOT EXISTS products (
               product_id INTEGER PRIMARY KEY,
               product_name VARCHAR(200) NOT NULL,
               category VARCHAR(100) NOT NULL,
               cost_price DECIMAL(10,2) NOT NULL,
               list_price DECIMAL(10,2) NOT NULL
           )
       """)
       
       # Create customers table
       cursor.execute("""
           CREATE TABLE IF NOT EXISTS customers (
               customer_id INTEGER PRIMARY KEY,
               customer_name VARCHAR(200) NOT NULL,
               email VARCHAR(200),
               phone VARCHAR(20),
               address VARCHAR(500),
               city VARCHAR(100),
               state VARCHAR(50),
               country VARCHAR(50),
               registration_date DATE
           )
       """)
       
       conn.commit()
       print("Tables created successfully")
       
       return conn, cursor
   
   def load_sample_data(cursor, conn):
       """Load sample data for analytics"""
       print("Loading sample data...")
       
       # Insert sample products
       products = [
           (1, 'Laptop Pro 15"', 'Electronics', 800.00, 1200.00),
           (2, 'Wireless Mouse', 'Electronics', 15.00, 25.00),
           (3, 'Office Chair', 'Furniture', 120.00, 200.00),
           (4, 'Standing Desk', 'Furniture', 300.00, 500.00),
           (5, 'Monitor 27"', 'Electronics', 200.00, 350.00)
       ]
       
       cursor.executemany("""
           INSERT INTO products (product_id, product_name, category, cost_price, list_price)
           VALUES (%s, %s, %s, %s, %s)
       """, products)
       
       # Insert sample customers
       customers = []
       for i in range(1, 101):
           customers.append((
               i,
               f'Customer {i}',
               f'customer{i}@example.com',
               f'555-{random.randint(1000, 9999)}',
               f'{random.randint(100, 999)} Main St',
               random.choice(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix']),
               random.choice(['NY', 'CA', 'IL', 'TX', 'AZ']),
               'USA',
               (datetime.now() - timedelta(days=random.randint(30, 365))).date()
           ))
       
       cursor.executemany("""
           INSERT INTO customers (customer_id, customer_name, email, phone, address, city, state, country, registration_date)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
       """, customers)
       
       # Insert sample sales data
       sales = []
       regions = ['North', 'South', 'East', 'West']
       sales_reps = ['Alice Johnson', 'Bob Smith', 'Carol Davis', 'David Wilson']
       
       for i in range(1000):
           product_id = random.randint(1, 5)
           customer_id = random.randint(1, 100)
           quantity = random.randint(1, 10)
           
           # Get product price (simplified)
           if product_id == 1:
               unit_price = 1200.00
           elif product_id == 2:
               unit_price = 25.00
           elif product_id == 3:
               unit_price = 200.00
           elif product_id == 4:
               unit_price = 500.00
           else:
               unit_price = 350.00
           
           total_amount = quantity * unit_price
           sale_date = (datetime.now() - timedelta(days=random.randint(1, 365))).date()
           
           sales.append((
               product_id,
               customer_id,
               sale_date,
               quantity,
               unit_price,
               total_amount,
               random.choice(regions),
               random.choice(sales_reps)
           ))
       
       cursor.executemany("""
           INSERT INTO sales (product_id, customer_id, sale_date, quantity, unit_price, total_amount, region, sales_rep)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
       """, sales)
       
       conn.commit()
       print("Sample data loaded successfully")
   
   def run_analytics_queries(cursor):
       """Run various analytics queries"""
       print("\n=== Running Analytics Queries ===")
       
       # Query 1: Total sales by region
       print("\n1. Total Sales by Region:")
       cursor.execute("""
           SELECT region, 
                  COUNT(*) as total_orders,
                  SUM(total_amount) as total_revenue,
                  AVG(total_amount) as avg_order_value
           FROM sales 
           GROUP BY region 
           ORDER BY total_revenue DESC
       """)
       
       for row in cursor.fetchall():
           print(f"Region: {row[0]}, Orders: {row[1]}, Revenue: ${row[2]:,.2f}, Avg: ${row[3]:.2f}")
       
       # Query 2: Top selling products
       print("\n2. Top Selling Products:")
       cursor.execute("""
           SELECT p.product_name,
                  p.category,
                  SUM(s.quantity) as total_quantity,
                  SUM(s.total_amount) as total_revenue
           FROM sales s
           JOIN products p ON s.product_id = p.product_id
           GROUP BY p.product_name, p.category
           ORDER BY total_revenue DESC
           LIMIT 5
       """)
       
       for row in cursor.fetchall():
           print(f"Product: {row[0]}, Category: {row[1]}, Qty: {row[2]}, Revenue: ${row[3]:,.2f}")
       
       # Query 3: Monthly sales trend
       print("\n3. Monthly Sales Trend (Last 6 months):")
       cursor.execute("""
           SELECT DATE_TRUNC('month', sale_date) as month,
                  COUNT(*) as orders,
                  SUM(total_amount) as revenue
           FROM sales 
           WHERE sale_date >= CURRENT_DATE - INTERVAL '6 months'
           GROUP BY DATE_TRUNC('month', sale_date)
           ORDER BY month
       """)
       
       for row in cursor.fetchall():
           print(f"Month: {row[0]}, Orders: {row[1]}, Revenue: ${row[2]:,.2f}")
       
       # Query 4: Sales rep performance
       print("\n4. Sales Rep Performance:")
       cursor.execute("""
           SELECT sales_rep,
                  COUNT(*) as total_sales,
                  SUM(total_amount) as total_revenue,
                  AVG(total_amount) as avg_sale_amount
           FROM sales
           GROUP BY sales_rep
           ORDER BY total_revenue DESC
       """)
       
       for row in cursor.fetchall():
           print(f"Rep: {row[0]}, Sales: {row[1]}, Revenue: ${row[2]:,.2f}, Avg: ${row[3]:.2f}")
       
       # Query 5: Customer analysis
       print("\n5. Top Customers by Revenue:")
       cursor.execute("""
           SELECT c.customer_name,
                  c.city,
                  c.state,
                  COUNT(s.sale_id) as total_orders,
                  SUM(s.total_amount) as total_spent
           FROM customers c
           JOIN sales s ON c.customer_id = s.customer_id
           GROUP BY c.customer_name, c.city, c.state
           ORDER BY total_spent DESC
           LIMIT 10
       """)
       
       for row in cursor.fetchall():
           print(f"Customer: {row[0]}, Location: {row[1]}, {row[2]}, Orders: {row[3]}, Spent: ${row[4]:,.2f}")
   
   if __name__ == "__main__":
       try:
           conn, cursor = create_tables()
           load_sample_data(cursor, conn)
           run_analytics_queries(cursor)
           
           cursor.close()
           conn.close()
           
           print("\nRedshift analytics completed successfully!")
           
       except Exception as e:
           print(f"Redshift error: {e}")
   EOF
   
   # Install PostgreSQL adapter
   pip install psycopg2-binary pandas
   
   # Update endpoint and run analytics
   sed -i "s/REDSHIFT_ENDPOINT_HERE/$REDSHIFT_ENDPOINT/g" redshift_analytics.py
   python3 redshift_analytics.py
   ```

**Screenshot Placeholder**:
![Redshift Analytics Queries](screenshots/17-redshift-analytics.png)
*Caption: Redshift data warehouse with sample analytics queries*

### Practice 6: Database Migration with DMS
**Objective**: Set up AWS Database Migration Service for data migration

**Steps**:
1. **Create DMS Replication Instance**:
   ```bash
   # Create DMS subnet group
   aws dms create-replication-subnet-group \
     --replication-subnet-group-identifier my-dms-subnet-group \
     --replication-subnet-group-description "DMS subnet group" \
     --subnet-ids $SUBNET_IDS
   
   # Create DMS replication instance
   aws dms create-replication-instance \
     --replication-instance-identifier my-dms-instance \
     --replication-instance-class dms.t3.micro \
     --allocated-storage 20 \
     --vpc-security-group-ids $SG_ID \
     --replication-subnet-group-identifier my-dms-subnet-group \
     --multi-az false \
     --publicly-accessible true
   
   # Wait for replication instance to be available
   aws dms wait replication-instance-available \
     --replication-instance-identifier my-dms-instance
   ```

2. **Create Source and Target Endpoints**:
   ```bash
   # Create source endpoint (MySQL RDS)
   aws dms create-endpoint \
     --endpoint-identifier mysql-source \
     --endpoint-type source \
     --engine-name mysql \
     --server-name $RDS_ENDPOINT \
     --port 3306 \
     --database-name testdb \
     --username admin \
     --password MySecurePassword123!
   
   # Create target endpoint (Aurora)
   aws dms create-endpoint \
     --endpoint-identifier aurora-target \
     --endpoint-type target \
     --engine-name aurora-mysql \
     --server-name $AURORA_ENDPOINT \
     --port 3306 \
     --database-name sampledb \
     --username admin \
     --password MyAuroraPassword123!
   
   # Test endpoints
   aws dms test-connection \
     --replication-instance-arn $(aws dms describe-replication-instances \
       --replication-instance-identifier my-dms-instance \
       --query 'ReplicationInstances[0].ReplicationInstanceArn' --output text) \
     --endpoint-arn $(aws dms describe-endpoints \
       --endpoint-identifier mysql-source \
       --query 'Endpoints[0].EndpointArn' --output text)
   ```

3. **Create Migration Task**:
   ```bash
   # Create table mapping configuration
   cat > table-mappings.json << 'EOF'
   {
     "rules": [
       {
         "rule-type": "selection",
         "rule-id": "1",
         "rule-name": "1",
         "object-locator": {
           "schema-name": "testdb",
           "table-name": "%"
         },
         "rule-action": "include"
       }
     ]
   }
   EOF
   
   # Create migration task
   aws dms create-replication-task \
     --replication-task-identifier mysql-to-aurora-migration \
     --source-endpoint-arn $(aws dms describe-endpoints \
       --endpoint-identifier mysql-source \
       --query 'Endpoints[0].EndpointArn' --output text) \
     --target-endpoint-arn $(aws dms describe-endpoints \
       --endpoint-identifier aurora-target \
       --query 'Endpoints[0].EndpointArn' --output text) \
     --replication-instance-arn $(aws dms describe-replication-instances \
       --replication-instance-identifier my-dms-instance \
       --query 'ReplicationInstances[0].ReplicationInstanceArn' --output text) \
     --migration-type full-load-and-cdc \
     --table-mappings file://table-mappings.json
   
   # Start migration task
   aws dms start-replication-task \
     --replication-task-arn $(aws dms describe-replication-tasks \
       --replication-task-identifier mysql-to-aurora-migration \
       --query 'ReplicationTasks[0].ReplicationTaskArn' --output text) \
     --start-replication-task-type start-replication
   ```

**Screenshot Placeholder**:
![DMS Migration Task](screenshots/17-dms-migration-task.png)
*Caption: AWS DMS migration task from MySQL to Aurora*

## ✅ Section Completion Checklist

- [ ] Created RDS Multi-AZ instance with read replicas
- [ ] Set up DynamoDB table with Global Secondary Index
- [ ] Deployed Aurora Serverless v2 with auto-scaling
- [ ] Configured ElastiCache Redis cluster with failover
- [ ] Created Redshift data warehouse and ran analytics
- [ ] Set up DMS for database migration
- [ ] Tested database performance and scaling
- [ ] Implemented database security best practices
- [ ] Monitored database metrics and logs

## 🎯 Key Takeaways

- **RDS**: Managed relational databases with Multi-AZ for high availability
- **Aurora**: Cloud-native database with superior performance and scaling
- **DynamoDB**: NoSQL database for high-performance applications
- **ElastiCache**: In-memory caching for improved application performance
- **Redshift**: Data warehouse for analytics and business intelligence
- **Database Selection**: Choose based on workload requirements and patterns
- **Scaling Strategies**: Vertical scaling, read replicas, and sharding options
- **Security**: Encryption, VPC, and IAM integration for database security

## 📚 Additional Resources

- [AWS Database Services](https://aws.amazon.com/products/databases/)
- [Amazon RDS User Guide](https://docs.aws.amazon.com/rds/)
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [Amazon Aurora User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [Amazon ElastiCache User Guide](https://docs.aws.amazon.com/elasticache/)
- [Amazon Redshift Database Developer Guide](https://docs.aws.amazon.com/redshift/)
- [Database Best Practices](https://aws.amazon.com/architecture/well-architected/)