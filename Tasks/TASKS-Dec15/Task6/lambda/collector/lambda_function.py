import boto3
import json
from datetime import datetime, timedelta
from decimal import Decimal

# AWS Clients
dynamodb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')
rds = boto3.client('rds')
s3 = boto3.client('s3')
lambda_client = boto3.client('lambda')
eks = boto3.client('eks')
cloudwatch = boto3.client('cloudwatch')

TABLE_NAME = 'aws-inventory'

def lambda_handler(event, context):
    """Main Lambda handler for inventory collection"""
    print("Starting inventory collection...")
    
    table = dynamodb.Table(TABLE_NAME)
    timestamp = datetime.utcnow().isoformat()
    
    resources = []
    resources.extend(collect_ec2())
    resources.extend(collect_rds())
    resources.extend(collect_s3())
    resources.extend(collect_lambda())
    resources.extend(collect_eks())
    
    # Store in DynamoDB
    for resource in resources:
        resource['timestamp'] = timestamp
        resource['scan_date'] = datetime.utcnow().strftime('%Y-%m-%d')
        table.put_item(Item=convert_decimals(resource))
    
    print(f"Collected {len(resources)} resources")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Successfully collected {len(resources)} resources',
            'timestamp': timestamp
        })
    }

def collect_ec2():
    """Collect EC2 instances"""
    instances = []
    try:
        response = ec2.describe_instances()
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances.append({
                    'resource_id': instance['InstanceId'],
                    'resource_type': 'EC2',
                    'name': get_tag(instance.get('Tags', []), 'Name'),
                    'instance_type': instance['InstanceType'],
                    'state': instance['State']['Name'],
                    'launch_date': instance['LaunchTime'].isoformat(),
                    'ami_id': instance.get('ImageId', 'N/A'),
                    'region': ec2.meta.region_name,
                    'az': instance['Placement']['AvailabilityZone'],
                    'vpc_id': instance.get('VpcId', 'N/A'),
                    'tags': parse_tags(instance.get('Tags', [])),
                    'recommendations': generate_ec2_recommendations(instance)
                })
    except Exception as e:
        print(f"Error collecting EC2: {e}")
    return instances

def collect_rds():
    """Collect RDS databases"""
    databases = []
    try:
        response = rds.describe_db_instances()
        for db in response['DBInstances']:
            eol_warning = check_rds_eol(db['Engine'], db['EngineVersion'])
            databases.append({
                'resource_id': db['DBInstanceIdentifier'],
                'resource_type': 'RDS',
                'engine': db['Engine'],
                'engine_version': db['EngineVersion'],
                'instance_class': db['DBInstanceClass'],
                'storage_gb': db['AllocatedStorage'],
                'multi_az': db['MultiAZ'],
                'backup_retention': db['BackupRetentionPeriod'],
                'status': db['DBInstanceStatus'],
                'recommendations': [eol_warning] if eol_warning else []
            })
    except Exception as e:
        print(f"Error collecting RDS: {e}")
    return databases

def collect_s3():
    """Collect S3 buckets"""
    buckets = []
    try:
        response = s3.list_buckets()
        for bucket in response['Buckets'][:10]:  # Limit to 10 for demo
            try:
                versioning = s3.get_bucket_versioning(Bucket=bucket['Name'])
                has_lifecycle = False
                try:
                    s3.get_bucket_lifecycle_configuration(Bucket=bucket['Name'])
                    has_lifecycle = True
                except:
                    pass
                
                buckets.append({
                    'resource_id': bucket['Name'],
                    'resource_type': 'S3',
                    'versioning': versioning.get('Status') == 'Enabled',
                    'lifecycle_policy': has_lifecycle,
                    'creation_date': bucket['CreationDate'].isoformat(),
                    'recommendations': generate_s3_recommendations(has_lifecycle)
                })
            except Exception as e:
                print(f"Error processing bucket {bucket['Name']}: {e}")
    except Exception as e:
        print(f"Error collecting S3: {e}")
    return buckets

def collect_lambda():
    """Collect Lambda functions"""
    functions = []
    try:
        response = lambda_client.list_functions()
        for func in response['Functions']:
            runtime_warning = check_lambda_runtime_eol(func['Runtime'])
            functions.append({
                'resource_id': func['FunctionName'],
                'resource_type': 'Lambda',
                'runtime': func['Runtime'],
                'memory_mb': func['MemorySize'],
                'timeout': func['Timeout'],
                'last_modified': func['LastModified'],
                'recommendations': [runtime_warning] if runtime_warning else []
            })
    except Exception as e:
        print(f"Error collecting Lambda: {e}")
    return functions

def collect_eks():
    """Collect EKS clusters"""
    clusters = []
    try:
        response = eks.list_clusters()
        for cluster_name in response['clusters']:
            cluster = eks.describe_cluster(name=cluster_name)['cluster']
            k8s_warning = check_k8s_version_eol(cluster['version'])
            clusters.append({
                'resource_id': cluster_name,
                'resource_type': 'EKS',
                'version': cluster['version'],
                'status': cluster['status'],
                'endpoint': cluster['endpoint'],
                'created_at': cluster['createdAt'].isoformat(),
                'recommendations': [k8s_warning] if k8s_warning else []
            })
    except Exception as e:
        print(f"Error collecting EKS: {e}")
    return clusters

def check_rds_eol(engine, version):
    """Check RDS engine EOL"""
    eol_map = {
        'mysql-8.0': '2026-04-30',
        'postgres-14': '2026-11-12'
    }
    key = f'{engine}-{version.split(".")[0]}.{version.split(".")[1]}'
    if key in eol_map:
        eol_date = datetime.strptime(eol_map[key], '%Y-%m-%d')
        if eol_date < datetime.now() + timedelta(days=180):
            return f'Engine {engine} {version} EOL on {eol_map[key]}'
    return None

def check_lambda_runtime_eol(runtime):
    """Check Lambda runtime EOL"""
    eol_map = {
        'python3.9': '2025-04-30',
        'nodejs18.x': '2025-04-30'
    }
    if runtime in eol_map:
        eol_date = datetime.strptime(eol_map[runtime], '%Y-%m-%d')
        if eol_date < datetime.now() + timedelta(days=180):
            return f'Runtime {runtime} EOL on {eol_map[runtime]}'
    return None

def check_k8s_version_eol(version):
    """Check Kubernetes version EOL"""
    eol_map = {
        '1.28': '2025-01-31',
        '1.29': '2025-03-31'
    }
    if version in eol_map:
        eol_date = datetime.strptime(eol_map[version], '%Y-%m-%d')
        if eol_date < datetime.now() + timedelta(days=90):
            return f'Kubernetes {version} EOL on {eol_map[version]}'
    return None

def generate_ec2_recommendations(instance):
    """Generate EC2 recommendations"""
    recs = []
    if instance['State']['Name'] == 'stopped':
        recs.append('Instance stopped - consider terminating if unused')
    if not get_tag(instance.get('Tags', []), 'Name'):
        recs.append('Missing Name tag')
    return recs

def generate_s3_recommendations(has_lifecycle):
    """Generate S3 recommendations"""
    if not has_lifecycle:
        return ['Enable lifecycle policy for cost savings']
    return []

def get_tag(tags, key):
    """Get tag value"""
    for tag in tags:
        if tag['Key'] == key:
            return tag['Value']
    return ''

def parse_tags(tags):
    """Parse tags to dict"""
    return {tag['Key']: tag['Value'] for tag in tags}

def convert_decimals(obj):
    """Convert float to Decimal for DynamoDB"""
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_decimals(i) for i in obj]
    return obj
