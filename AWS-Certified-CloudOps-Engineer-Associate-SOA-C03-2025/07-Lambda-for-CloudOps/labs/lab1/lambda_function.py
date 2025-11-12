import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    """
    CloudOps Lambda function for EC2 instance management
    """
    ec2 = boto3.client('ec2')
    
    action = event.get('action', 'list_instances')
    tag_filter = event.get('tag', 'Environment=Dev')
    
    try:
        if action == 'stop_instances':
            return stop_instances(ec2, tag_filter)
        elif action == 'start_instances':
            return start_instances(ec2, tag_filter)
        elif action == 'list_instances':
            return list_instances(ec2, tag_filter)
        else:
            return {
                'statusCode': 400,
                'body': json.dumps('Invalid action. Use: start_instances, stop_instances, or list_instances')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def stop_instances(ec2, tag_filter):
    """Stop running instances with specific tag"""
    tag_key, tag_value = tag_filter.split('=')
    
    response = ec2.describe_instances(
        Filters=[
            {'Name': f'tag:{tag_key}', 'Values': [tag_value]},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Stopped {len(instance_ids)} instances',
                'instances': instance_ids,
                'timestamp': datetime.now().isoformat()
            })
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'No running instances found with specified tag',
                'instances': [],
                'timestamp': datetime.now().isoformat()
            })
        }

def start_instances(ec2, tag_filter):
    """Start stopped instances with specific tag"""
    tag_key, tag_value = tag_filter.split('=')
    
    response = ec2.describe_instances(
        Filters=[
            {'Name': f'tag:{tag_key}', 'Values': [tag_value]},
            {'Name': 'instance-state-name', 'Values': ['stopped']}
        ]
    )
    
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if instance_ids:
        ec2.start_instances(InstanceIds=instance_ids)
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Started {len(instance_ids)} instances',
                'instances': instance_ids,
                'timestamp': datetime.now().isoformat()
            })
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'No stopped instances found with specified tag',
                'instances': [],
                'timestamp': datetime.now().isoformat()
            })
        }

def list_instances(ec2, tag_filter):
    """List all instances with specific tag"""
    tag_key, tag_value = tag_filter.split('=')
    
    response = ec2.describe_instances(
        Filters=[
            {'Name': f'tag:{tag_key}', 'Values': [tag_value]}
        ]
    )
    
    instances = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instances.append({
                'InstanceId': instance['InstanceId'],
                'State': instance['State']['Name'],
                'InstanceType': instance['InstanceType'],
                'LaunchTime': instance['LaunchTime'].isoformat()
            })
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Found {len(instances)} instances',
            'instances': instances,
            'timestamp': datetime.now().isoformat()
        })
    }