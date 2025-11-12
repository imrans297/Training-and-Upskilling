"""
Lambda Function 2: Resource Reporter
Uses the CloudOps Layer for common utilities
"""

import json
import os
from layer_utils import CloudOpsUtils, get_tag_value

def lambda_handler(event, context):
    """
    Resource Reporter Lambda function using shared layer utilities
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Initialize CloudOps utilities from layer
    region = os.environ.get('AWS_REGION', 'us-east-1')
    utils = CloudOpsUtils(region=region)
    
    try:
        report_type = event.get('report_type', 'summary')
        tag_key = event.get('tag_key', 'Environment')
        tag_value = event.get('tag_value', 'Dev')
        
        if report_type == 'summary':
            return handle_resource_summary(utils)
        
        elif report_type == 'detailed':
            return handle_detailed_report(utils, tag_key, tag_value)
        
        elif report_type == 'cost_analysis':
            return handle_cost_analysis(utils, tag_key, tag_value)
        
        else:
            return utils.format_response(400, None, f"Invalid report type: {report_type}")
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return utils.format_response(500, None, f"Internal error: {str(e)}")

def handle_resource_summary(utils):
    """Generate resource summary report"""
    summary = utils.get_resource_summary()
    
    if 'error' in summary:
        return utils.format_response(500, summary, "Failed to generate resource summary")
    
    return utils.format_response(
        200,
        summary,
        f"Resource summary for region {summary['region']}"
    )

def handle_detailed_report(utils, tag_key, tag_value):
    """Generate detailed instance report"""
    instances = utils.get_instances_by_tag(tag_key, tag_value)
    
    # Enhance instance data with additional details
    detailed_instances = []
    for instance in instances:
        detailed_instance = instance.copy()
        
        # Add tag information
        tags_dict = {}
        for tag in instance['Tags']:
            tags_dict[tag['Key']] = tag['Value']
        
        detailed_instance['TagsDict'] = tags_dict
        detailed_instance['Environment'] = get_tag_value(instance['Tags'], 'Environment')
        detailed_instance['Owner'] = get_tag_value(instance['Tags'], 'Owner')
        detailed_instance['Project'] = get_tag_value(instance['Tags'], 'Project')
        
        detailed_instances.append(detailed_instance)
    
    # Group by state
    by_state = {}
    for instance in detailed_instances:
        state = instance['State']
        if state not in by_state:
            by_state[state] = []
        by_state[state].append(instance)
    
    # Group by instance type
    by_type = {}
    for instance in detailed_instances:
        inst_type = instance['InstanceType']
        if inst_type not in by_type:
            by_type[inst_type] = 0
        by_type[inst_type] += 1
    
    report = {
        'filter': f"{tag_key}={tag_value}",
        'total_instances': len(detailed_instances),
        'instances': detailed_instances,
        'summary': {
            'by_state': {state: len(instances) for state, instances in by_state.items()},
            'by_type': by_type
        }
    }
    
    return utils.format_response(
        200,
        report,
        f"Detailed report for {len(detailed_instances)} instances"
    )

def handle_cost_analysis(utils, tag_key, tag_value):
    """Generate cost analysis report"""
    instances = utils.get_instances_by_tag(tag_key, tag_value)
    
    # Simple cost estimation (approximate hourly rates)
    instance_costs = {
        't3.micro': 0.0104,
        't3.small': 0.0208,
        't3.medium': 0.0416,
        't3.large': 0.0832,
        't3.xlarge': 0.1664,
        't3.2xlarge': 0.3328,
        'm5.large': 0.096,
        'm5.xlarge': 0.192,
        'm5.2xlarge': 0.384,
        'c5.large': 0.085,
        'c5.xlarge': 0.17
    }
    
    cost_analysis = {
        'filter': f"{tag_key}={tag_value}",
        'instances': [],
        'total_hourly_cost': 0,
        'monthly_cost_estimate': 0,
        'running_hourly_cost': 0,
        'potential_savings': 0
    }
    
    for instance in instances:
        inst_type = instance['InstanceType']
        hourly_rate = instance_costs.get(inst_type, 0.05)  # Default rate
        
        instance_cost = {
            'instance_id': instance['InstanceId'],
            'instance_type': inst_type,
            'state': instance['State'],
            'hourly_rate': hourly_rate,
            'monthly_estimate': hourly_rate * 24 * 30
        }
        
        cost_analysis['instances'].append(instance_cost)
        cost_analysis['total_hourly_cost'] += hourly_rate
        
        if instance['State'] == 'running':
            cost_analysis['running_hourly_cost'] += hourly_rate
    
    # Calculate estimates
    cost_analysis['monthly_cost_estimate'] = cost_analysis['total_hourly_cost'] * 24 * 30
    cost_analysis['running_monthly_cost'] = cost_analysis['running_hourly_cost'] * 24 * 30
    
    # Potential savings if stopped instances were running
    stopped_cost = cost_analysis['total_hourly_cost'] - cost_analysis['running_hourly_cost']
    cost_analysis['potential_savings'] = stopped_cost * 24 * 30
    
    return utils.format_response(
        200,
        cost_analysis,
        f"Cost analysis for {len(instances)} instances"
    )