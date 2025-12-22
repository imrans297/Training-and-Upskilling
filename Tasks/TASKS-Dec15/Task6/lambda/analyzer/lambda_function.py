import boto3
import json
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
sns = boto3.client('sns')

TABLE_NAME = 'aws-inventory'
SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:860839673297:inventory-alerts'
MODEL_ID = 'anthropic.claude-3-sonnet-20240229-v1:0'

def lambda_handler(event, context):
    """AI-powered inventory analysis"""
    print("Starting AI analysis...")
    
    # Get recent inventory
    inventory = get_recent_inventory()
    
    if not inventory:
        return {'statusCode': 200, 'body': 'No inventory data found'}
    
    # Analyze with AI
    analysis = analyze_with_bedrock(inventory)
    
    # Always send alert with analysis results
    send_alert(analysis, inventory)
    
    print(f"Analysis complete for {len(inventory)} resources")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Analysis complete',
            'resources_analyzed': len(inventory),
            'analysis': analysis[:500]  # Truncate for response
        })
    }

def get_recent_inventory():
    """Get inventory from last 24 hours"""
    table = dynamodb.Table(TABLE_NAME)
    
    try:
        response = table.scan(
            FilterExpression='scan_date = :today',
            ExpressionAttributeValues={
                ':today': datetime.utcnow().strftime('%Y-%m-%d')
            }
        )
        return response.get('Items', [])
    except Exception as e:
        print(f"Error getting inventory: {e}")
        return []

def analyze_with_bedrock(inventory):
    """Use Bedrock for AI analysis"""
    
    summary = generate_summary(inventory)
    
    prompt = f"""You are an AWS FinOps expert. Analyze this infrastructure inventory and provide:

1. Top 3 cost optimization opportunities
2. Critical EOS/EOL warnings
3. Compliance issues
4. Actionable recommendations

Inventory Summary:
{json.dumps(summary, indent=2)}

Be concise and prioritize by impact."""

    try:
        response = bedrock.invoke_model(
            modelId=MODEL_ID,
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "messages": [{
                    "role": "user",
                    "content": prompt
                }]
            })
        )
        
        result = json.loads(response['body'].read())
        return result['content'][0]['text']
    
    except Exception as e:
        print(f"Bedrock error: {e}")
        return generate_fallback_analysis(summary)

def generate_summary(inventory):
    """Generate inventory summary"""
    summary = {
        'total_resources': len(inventory),
        'by_type': {},
        'stopped_ec2': 0,
        'eol_warnings': 0,
        's3_no_lifecycle': 0,
        'critical_issues': []
    }
    
    for resource in inventory:
        rtype = resource.get('resource_type', 'Unknown')
        summary['by_type'][rtype] = summary['by_type'].get(rtype, 0) + 1
        
        if rtype == 'EC2' and resource.get('state') == 'stopped':
            summary['stopped_ec2'] += 1
            summary['critical_issues'].append(f"Stopped EC2: {resource['resource_id']}")
        
        if rtype == 'S3' and not resource.get('lifecycle_policy'):
            summary['s3_no_lifecycle'] += 1
        
        if resource.get('recommendations'):
            for rec in resource['recommendations']:
                if 'EOL' in rec or 'eol' in rec:
                    summary['eol_warnings'] += 1
                    summary['critical_issues'].append(f"{rtype} {resource['resource_id']}: {rec}")
    
    return summary

def generate_fallback_analysis(summary):
    """Fallback analysis without Bedrock"""
    analysis = f"""
AWS Infrastructure Analysis Report
Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}

SUMMARY:
- Total Resources: {summary['total_resources']}
- Resource Types: {', '.join(f"{k}({v})" for k, v in summary['by_type'].items())}

CRITICAL FINDINGS:
- Stopped EC2 Instances: {summary['stopped_ec2']}
- S3 Buckets without Lifecycle: {summary['s3_no_lifecycle']}
- EOS/EOL Warnings: {summary['eol_warnings']}

TOP RECOMMENDATIONS:
1. Terminate {summary['stopped_ec2']} stopped EC2 instances to save costs
2. Enable lifecycle policies on {summary['s3_no_lifecycle']} S3 buckets
3. Address {summary['eol_warnings']} EOS/EOL warnings immediately

CRITICAL ISSUES:
{chr(10).join(summary['critical_issues'][:5])}
"""
    return analysis

def has_critical_issues(inventory):
    """Check if there are critical issues"""
    for resource in inventory:
        if resource.get('state') == 'stopped':
            return True
        if resource.get('recommendations'):
            for rec in resource['recommendations']:
                if 'EOL' in rec or 'eol' in rec:
                    return True
    return False

def send_alert(analysis, inventory):
    """Send SNS alert"""
    try:
        subject = f"AWS Inventory Alert - {len(inventory)} Resources Scanned"
        message = f"""
AWS Infrastructure Inventory Alert

{analysis}

View full details in DynamoDB table: {TABLE_NAME}
Scan Date: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}
"""
        
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=subject,
            Message=message
        )
        print("Alert sent successfully")
    except Exception as e:
        print(f"Error sending alert: {e}")
