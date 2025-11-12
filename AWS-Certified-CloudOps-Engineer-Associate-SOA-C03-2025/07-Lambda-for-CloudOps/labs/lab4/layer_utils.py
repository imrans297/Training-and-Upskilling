"""
Common utilities for CloudOps Lambda functions
This file will be packaged in the Lambda Layer
"""

import json
import boto3
from datetime import datetime
from typing import List, Dict, Any

class CloudOpsUtils:
    """Common utilities for CloudOps operations"""
    
    def __init__(self, region='us-east-1'):
        self.ec2 = boto3.client('ec2', region_name=region)
        self.region = region
    
    def get_instances_by_tag(self, tag_key: str, tag_value: str, states: List[str] = None) -> List[Dict]:
        """Get EC2 instances filtered by tag and optionally by state"""
        filters = [
            {'Name': f'tag:{tag_key}', 'Values': [tag_value]}
        ]
        
        if states:
            filters.append({'Name': 'instance-state-name', 'Values': states})
        
        response = self.ec2.describe_instances(Filters=filters)
        
        instances = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances.append({
                    'InstanceId': instance['InstanceId'],
                    'InstanceType': instance['InstanceType'],
                    'State': instance['State']['Name'],
                    'LaunchTime': instance['LaunchTime'].isoformat(),
                    'PrivateIpAddress': instance.get('PrivateIpAddress', 'N/A'),
                    'PublicIpAddress': instance.get('PublicIpAddress', 'N/A'),
                    'Tags': instance.get('Tags', [])
                })
        
        return instances
    
    def bulk_instance_operation(self, instance_ids: List[str], operation: str) -> Dict[str, Any]:
        """Perform bulk operations on instances"""
        if not instance_ids:
            return {
                'success': False,
                'message': 'No instance IDs provided',
                'affected_instances': []
            }
        
        try:
            if operation == 'start':
                response = self.ec2.start_instances(InstanceIds=instance_ids)
            elif operation == 'stop':
                response = self.ec2.stop_instances(InstanceIds=instance_ids)
            elif operation == 'reboot':
                response = self.ec2.reboot_instances(InstanceIds=instance_ids)
            else:
                return {
                    'success': False,
                    'message': f'Invalid operation: {operation}',
                    'affected_instances': []
                }
            
            return {
                'success': True,
                'message': f'Successfully {operation}ed {len(instance_ids)} instances',
                'operation': operation,
                'affected_instances': instance_ids,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                'success': False,
                'message': f'Error performing {operation}: {str(e)}',
                'affected_instances': []
            }
    
    def get_resource_summary(self) -> Dict[str, Any]:
        """Get summary of AWS resources in the region"""
        try:
            # Get all instances
            instances_response = self.ec2.describe_instances()
            
            instance_summary = {
                'total': 0,
                'running': 0,
                'stopped': 0,
                'pending': 0,
                'terminating': 0,
                'by_type': {}
            }
            
            for reservation in instances_response['Reservations']:
                for instance in reservation['Instances']:
                    instance_summary['total'] += 1
                    state = instance['State']['Name']
                    instance_type = instance['InstanceType']
                    
                    # Count by state
                    if state in instance_summary:
                        instance_summary[state] += 1
                    
                    # Count by type
                    if instance_type not in instance_summary['by_type']:
                        instance_summary['by_type'][instance_type] = 0
                    instance_summary['by_type'][instance_type] += 1
            
            # Get VPCs
            vpcs_response = self.ec2.describe_vpcs()
            vpc_count = len(vpcs_response['Vpcs'])
            
            # Get Security Groups
            sgs_response = self.ec2.describe_security_groups()
            sg_count = len(sgs_response['SecurityGroups'])
            
            return {
                'region': self.region,
                'instances': instance_summary,
                'vpcs': vpc_count,
                'security_groups': sg_count,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                'error': f'Failed to get resource summary: {str(e)}',
                'timestamp': datetime.now().isoformat()
            }
    
    def format_response(self, status_code: int, data: Any, message: str = None) -> Dict[str, Any]:
        """Format standardized Lambda response"""
        response = {
            'statusCode': status_code,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({
                'data': data,
                'message': message,
                'timestamp': datetime.now().isoformat()
            })
        }
        
        return response

def get_tag_value(tags: List[Dict], key: str) -> str:
    """Extract tag value from tags list"""
    for tag in tags:
        if tag['Key'] == key:
            return tag['Value']
    return 'N/A'

def validate_instance_ids(instance_ids: List[str]) -> bool:
    """Validate instance ID format"""
    if not instance_ids:
        return False
    
    for instance_id in instance_ids:
        if not instance_id.startswith('i-') or len(instance_id) != 19:
            return False
    
    return True