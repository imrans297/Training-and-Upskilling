import json
import boto3
import os
from datetime import datetime, timedelta
import re

bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
logs_client = boto3.client('logs')
ssm_client = boto3.client('ssm')
sns_client = boto3.client('sns')

CLUSTER_NAME = os.environ['EKS_CLUSTER_NAME']
LOG_GROUP = f'/aws/containerinsights/{CLUSTER_NAME}/application'

def lambda_handler(event, context):
    """Main Lambda handler for AI-powered remediation"""
    
    print(f"Event received: {json.dumps(event)}")
    
    alarm_name = event['detail']['alarmName']
    alarm_state = event['detail']['state']['value']
    
    if alarm_state != 'ALARM':
        print(f"Alarm state is {alarm_state}, no action needed")
        return {'statusCode': 200, 'body': 'No action needed'}
    
    # Fetch recent logs
    log_events = fetch_logs(LOG_GROUP, minutes=10)
    log_text = '\n'.join([e['message'] for e in log_events[:100]])
    
    print(f"Fetched {len(log_events)} log events")
    
    # AI Analysis
    analysis = analyze_with_ai(log_text, alarm_name)
    print(f"AI Analysis: {json.dumps(analysis)}")
    
    # Execute remediation
    action_taken = execute_remediation(analysis)
    print(f"Action taken: {action_taken}")
    
    # Send notification
    send_notification(alarm_name, analysis, action_taken)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'alarm': alarm_name,
            'analysis': analysis,
            'action': action_taken
        })
    }

def fetch_logs(log_group, minutes=10):
    """Fetch recent logs from CloudWatch"""
    start_time = int((datetime.now() - timedelta(minutes=minutes)).timestamp() * 1000)
    
    try:
        response = logs_client.filter_log_events(
            logGroupName=log_group,
            startTime=start_time,
            limit=100
        )
        return response.get('events', [])
    except Exception as e:
        print(f"Error fetching logs: {str(e)}")
        return []

def analyze_with_ai(logs, alarm_name):
    """Use AWS Bedrock Claude 3 to analyze logs"""
    
    prompt = f"""You are a Kubernetes DevOps expert analyzing application failures.

Alarm: {alarm_name}

Recent Application Logs:
{logs}

Analyze the logs and provide:
1. Root cause (one concise sentence)
2. Remediation action: Choose ONE from [restart_pods, rollback_deployment, scale_up, none]
3. Confidence level: [high, medium, low]

Respond ONLY with valid JSON in this exact format:
{{"root_cause": "description", "action": "restart_pods", "confidence": "high"}}"""

    try:
        response = bedrock.invoke_model(
            modelId='anthropic.claude-3-sonnet-20240229-v1:0',
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 500,
                "temperature": 0.3,
                "messages": [{"role": "user", "content": prompt}]
            })
        )
        
        result = json.loads(response['body'].read())
        content = result['content'][0]['text']
        
        # Parse JSON from response
        json_match = re.search(r'\{.*\}', content, re.DOTALL)
        if json_match:
            return json.loads(json_match.group())
        
        return {
            "root_cause": "Unable to parse AI response",
            "action": "none",
            "confidence": "low"
        }
        
    except Exception as e:
        print(f"Error in AI analysis: {str(e)}")
        return {
            "root_cause": f"AI analysis failed: {str(e)}",
            "action": "none",
            "confidence": "low"
        }

def execute_remediation(analysis):
    """Execute remediation action based on AI analysis"""
    
    action = analysis.get('action', 'none')
    confidence = analysis.get('confidence', 'low')
    
    if confidence == 'low':
        return 'No action taken - confidence too low'
    
    if action == 'restart_pods':
        return restart_pods()
    elif action == 'rollback_deployment':
        return rollback_deployment()
    elif action == 'scale_up':
        return scale_deployment(5)
    
    return 'No action taken'

def restart_pods():
    """Restart pods using SSM to execute kubectl command"""
    try:
        # This assumes you have an EC2 instance with kubectl configured
        # In production, use Kubernetes Python client or EKS API
        command = f"kubectl rollout restart deployment/devops-platform -n prod"
        
        # For demo purposes, we'll just log the action
        print(f"Would execute: {command}")
        return f"Pods restart initiated"
        
    except Exception as e:
        return f"Failed to restart pods: {str(e)}"

def rollback_deployment():
    """Rollback deployment"""
    try:
        command = f"kubectl rollout undo deployment/devops-platform -n prod"
        print(f"Would execute: {command}")
        return f"Deployment rollback initiated"
        
    except Exception as e:
        return f"Failed to rollback: {str(e)}"

def scale_deployment(replicas):
    """Scale deployment"""
    try:
        command = f"kubectl scale deployment/devops-platform --replicas={replicas} -n prod"
        print(f"Would execute: {command}")
        return f"Scaled to {replicas} replicas"
        
    except Exception as e:
        return f"Failed to scale: {str(e)}"

def send_notification(alarm_name, analysis, action_taken):
    """Send SNS notification"""
    try:
        message = f"""
AI-Powered Remediation Alert

Alarm: {alarm_name}
Root Cause: {analysis.get('root_cause', 'Unknown')}
Recommended Action: {analysis.get('action', 'none')}
Confidence: {analysis.get('confidence', 'low')}
Action Taken: {action_taken}

Timestamp: {datetime.utcnow().isoformat()}
        """
        
        # In production, replace with actual SNS topic ARN
        print(f"Notification: {message}")
        
    except Exception as e:
        print(f"Failed to send notification: {str(e)}")
