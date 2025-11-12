import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    """
    SNS-triggered Lambda function for CloudOps automation
    Processes SNS messages from CloudWatch alarms and takes automated actions
    """
    sns = boto3.client('sns')
    ec2 = boto3.client('ec2')
    
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
    
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Check if this is an SNS event
        if 'Records' in event:
            return process_sns_event(event, ec2, sns, sns_topic_arn)
        else:
            # Direct invocation
            return process_direct_invocation(event, ec2, sns, sns_topic_arn)
            
    except Exception as e:
        error_msg = f"Error processing event: {str(e)}"
        print(error_msg)
        
        # Send error notification
        if sns_topic_arn:
            send_notification(sns, sns_topic_arn, "CloudOps Error", error_msg)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })
        }

def process_sns_event(event, ec2, sns, sns_topic_arn):
    """Process SNS event from CloudWatch alarm"""
    results = []
    
    for record in event['Records']:
        if record['EventSource'] == 'aws:sns':
            sns_message = json.loads(record['Sns']['Message'])
            print(f"Processing SNS message: {json.dumps(sns_message)}")
            
            # Check if it's a CloudWatch alarm
            if 'AlarmName' in sns_message:
                result = handle_cloudwatch_alarm(sns_message, ec2, sns, sns_topic_arn)
                results.append(result)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'SNS events processed successfully',
            'results': results,
            'timestamp': datetime.now().isoformat()
        })
    }

def process_direct_invocation(event, ec2, sns, sns_topic_arn):
    """Process direct Lambda invocation"""
    action = event.get('action', 'list_instances')
    tag_filter = event.get('tag', 'Environment=Dev')
    notify = event.get('notify', True)
    
    if action == 'stop_instances':
        result = stop_instances(ec2, tag_filter)
        if notify and sns_topic_arn:
            send_notification(sns, sns_topic_arn, 
                            "CloudOps: Instances Stopped", 
                            result['body'])
        return result
        
    elif action == 'start_instances':
        result = start_instances(ec2, tag_filter)
        if notify and sns_topic_arn:
            send_notification(sns, sns_topic_arn, 
                            "CloudOps: Instances Started", 
                            result['body'])
        return result
        
    elif action == 'list_instances':
        return list_instances(ec2, tag_filter)
    
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid action')
        }

def handle_cloudwatch_alarm(alarm_message, ec2, sns, sns_topic_arn):
    """Handle CloudWatch alarm notifications"""
    alarm_name = alarm_message.get('AlarmName', 'Unknown')
    new_state = alarm_message.get('NewStateValue', 'Unknown')
    reason = alarm_message.get('NewStateReason', 'No reason provided')
    
    print(f"Alarm: {alarm_name}, State: {new_state}, Reason: {reason}")
    
    # Get instance ID from alarm dimensions
    instance_id = None
    if 'Trigger' in alarm_message and 'Dimensions' in alarm_message['Trigger']:
        for dimension in alarm_message['Trigger']['Dimensions']:
            if dimension['name'] == 'InstanceId':
                instance_id = dimension['value']
                break
    
    if new_state == 'ALARM' and instance_id:
        if 'high-cpu' in alarm_name.lower():
            # Stop the instance due to high CPU
            try:
                ec2.stop_instances(InstanceIds=[instance_id])
                message = f"Instance {instance_id} stopped due to high CPU usage"
                print(message)
                
                # Send notification
                if sns_topic_arn:
                    send_notification(sns, sns_topic_arn, 
                                    f"CloudOps Alert: {alarm_name}", 
                                    message)
                
                return {
                    'action': 'stop_instance',
                    'instance_id': instance_id,
                    'reason': 'high_cpu_alarm',
                    'status': 'success'
                }
            except Exception as e:
                error_msg = f"Failed to stop instance {instance_id}: {str(e)}"
                print(error_msg)
                return {
                    'action': 'stop_instance',
                    'instance_id': instance_id,
                    'reason': 'high_cpu_alarm',
                    'status': 'error',
                    'error': str(e)
                }
    
    return {
        'action': 'alarm_processed',
        'alarm_name': alarm_name,
        'state': new_state,
        'status': 'no_action_taken'
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
        message = f'Stopped {len(instance_ids)} instances: {instance_ids}'
        print(message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
                'instances_stopped': instance_ids,
                'timestamp': datetime.now().isoformat()
            })
        }
    else:
        message = 'No running instances found with specified tag'
        print(message)
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
                'instances_stopped': [],
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
        message = f'Started {len(instance_ids)} instances: {instance_ids}'
        print(message)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
                'instances_started': instance_ids,
                'timestamp': datetime.now().isoformat()
            })
        }
    else:
        message = 'No stopped instances found with specified tag'
        print(message)
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': message,
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

def send_notification(sns, topic_arn, subject, message):
    """Send SNS notification"""
    try:
        sns.publish(
            TopicArn=topic_arn,
            Message=message,
            Subject=subject
        )
        print(f"Notification sent: {subject}")
    except Exception as e:
        print(f"Failed to send notification: {str(e)}")