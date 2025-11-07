import json
import boto3
from datetime import datetime

def lambda_handler(event, context):
    # Determine event source
    event_source = 'unknown'
    
    if 'httpMethod' in event:
        event_source = 'api-gateway'
        return handle_api_request(event, context)
    elif 'Records' in event:
        if event['Records'][0].get('eventSource') == 'aws:s3':
            event_source = 's3'
            return handle_s3_event(event, context)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Event processed from {event_source}',
            'timestamp': datetime.now().isoformat()
        })
    }

def handle_api_request(event, context):
    method = event['httpMethod']
    path = event['path']
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': f'{method} request to {path}',
            'requestId': context.aws_request_id,
            'timestamp': datetime.now().isoformat()
        })
    }

def handle_s3_event(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Processed S3 object {key} from bucket {bucket}'
        })
    }