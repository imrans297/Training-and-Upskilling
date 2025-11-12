import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    """
    Scheduled CloudOps Lambda function for EC2 instance management
    Triggered by EventBridge rules for automated start/stop operations
    """
    ec2 = boto3.client('ec2')
    
    # Get parameters from event or environment
    action = event.get('action', 'list_instances')
    tag_filter = event.get('tag', 'Environment=Dev')
    source = event.get('source', 'manual')
    
    print(f"Lambda triggered by: {source}")
    print(f"Action: {action}, Tag Filter: {tag_filter}")
    
    try:
        if action == 'stop_instances':
            return stop_instances(ec2, tag_filter, source)
        elif action == 'start_instances':
            return start_instances(ec2, tag_filter, source)
        elif action == 'list_instances':
            return list_instances(ec2, tag_filter)
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid action',
                    'valid_actions': ['start_instances', 'stop_instances', 'list_instances']
                })
            }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })
        }

def stop_instances(ec2, tag_filter, source):
    """Stop running instances with specific tag"""
    tag_key, tag_value = tag_filter.split('=')
    
    response = ec2.describe_instances(
        Filters=[
            {'Name': f'tag:{tag_key}', 'Values': [tag_value]},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    instance_ids = []
    instance_details = []
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
            instance_details.append({
                'InstanceId': instance['InstanceId'],
                'InstanceType': instance['InstanceType'],
                'LaunchTime': instance['LaunchTime'].isoformat()
            })
    
    if instance_ids:
        ec2.stop_instances(InstanceIds=instance_ids)
        print(f"Stopped {len(instance_ids)} instances: {instance_ids}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully stopped {len(instance_ids)} instances',
                'action': 'stop_instances',
                'source': source,
                'instances_stopped': instance_ids,
                'instance_details': instance_details,
                'timestamp': datetime.now().isoformat()
            })
        }
    else:
        print("No running instances found with specified tag")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'No running instances found with specified tag',
                'action': 'stop_instances',
                'source': source,
                'instances_stopped': [],
                'timestamp': datetime.now().isoformat()
            })
        }

def start_instances(ec2, tag_filter, source):
    """Start stopped instances with specific tag"""
    tag_key, tag_value = tag_filter.split('=')
    
    response = ec2.describe_instances(
        Filters=[
            {'Name': f'tag:{tag_key}', 'Values': [tag_value]},
            {'Name': 'instance-state-name', 'Values': ['stopped']}
        ]
    )
    
    instance_ids = []
    instance_details = []
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
            instance_details.append({
                'InstanceId': instance['InstanceId'],
                'InstanceType': instance['InstanceType'],
                'LaunchTime': instance['LaunchTime'].isoformat()
            })
    
    if instance_ids:
        ec2.start_instances(InstanceIds=instance_ids)
        print(f"Started {len(instance_ids)} instances: {instance_ids}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully started {len(instance_ids)} instances',
                'action': 'start_instances',
                'source': source,
                'instances_started': instance_ids,
                'instance_details': instance_details,
                'timestamp': datetime.now().isoformat()
            })
        }
    else:
        print("No stopped instances found with specified tag")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'No stopped instances found with specified tag',
                'action': 'start_instances',
                'source': source,
                'instances_started': [],
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
                'LaunchTime': instance['LaunchTime'].isoformat(),
                'Tags': instance.get('Tags', [])
            })
    
    print(f"Found {len(instances)} instances with tag {tag_filter}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Found {len(instances)} instances',
            'action': 'list_instances',
            'instances': instances,
            'timestamp': datetime.now().isoformat()
        })
    }