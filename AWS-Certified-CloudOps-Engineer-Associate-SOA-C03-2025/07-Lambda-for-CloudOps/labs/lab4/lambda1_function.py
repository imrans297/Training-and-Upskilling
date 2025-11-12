"""
Lambda Function 1: Instance Manager
Uses the CloudOps Layer for common utilities
"""

import json
import os
from layer_utils import CloudOpsUtils, validate_instance_ids

def lambda_handler(event, context):
    """
    Instance Manager Lambda function using shared layer utilities
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Initialize CloudOps utilities from layer
    region = os.environ.get('AWS_REGION', 'us-east-1')
    utils = CloudOpsUtils(region=region)
    
    try:
        action = event.get('action', 'list')
        tag_key = event.get('tag_key', 'Environment')
        tag_value = event.get('tag_value', 'Dev')
        instance_ids = event.get('instance_ids', [])
        
        if action == 'list':
            return handle_list_instances(utils, tag_key, tag_value)
        
        elif action == 'list_by_state':
            states = event.get('states', ['running'])
            return handle_list_by_state(utils, tag_key, tag_value, states)
        
        elif action in ['start', 'stop', 'reboot']:
            return handle_bulk_operation(utils, action, tag_key, tag_value, instance_ids)
        
        else:
            return utils.format_response(400, None, f"Invalid action: {action}")
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return utils.format_response(500, None, f"Internal error: {str(e)}")

def handle_list_instances(utils, tag_key, tag_value):
    """List all instances with specified tag"""
    instances = utils.get_instances_by_tag(tag_key, tag_value)
    
    return utils.format_response(
        200, 
        {
            'instances': instances,
            'count': len(instances),
            'filter': f"{tag_key}={tag_value}"
        },
        f"Found {len(instances)} instances"
    )

def handle_list_by_state(utils, tag_key, tag_value, states):
    """List instances filtered by tag and state"""
    instances = utils.get_instances_by_tag(tag_key, tag_value, states)
    
    return utils.format_response(
        200,
        {
            'instances': instances,
            'count': len(instances),
            'filter': f"{tag_key}={tag_value}",
            'states': states
        },
        f"Found {len(instances)} instances in states: {', '.join(states)}"
    )

def handle_bulk_operation(utils, operation, tag_key, tag_value, instance_ids):
    """Handle bulk instance operations"""
    
    # If no specific instance IDs provided, get instances by tag
    if not instance_ids:
        # Get appropriate instances based on operation
        if operation == 'start':
            target_states = ['stopped']
        elif operation == 'stop':
            target_states = ['running']
        else:  # reboot
            target_states = ['running']
        
        instances = utils.get_instances_by_tag(tag_key, tag_value, target_states)
        instance_ids = [inst['InstanceId'] for inst in instances]
    
    # Validate instance IDs
    if not validate_instance_ids(instance_ids):
        return utils.format_response(400, None, "Invalid instance IDs provided")
    
    # Perform bulk operation
    result = utils.bulk_instance_operation(instance_ids, operation)
    
    if result['success']:
        return utils.format_response(200, result, result['message'])
    else:
        return utils.format_response(400, result, result['message'])