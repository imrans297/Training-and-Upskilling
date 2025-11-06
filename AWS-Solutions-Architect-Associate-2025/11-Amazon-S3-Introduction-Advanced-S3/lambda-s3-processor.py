import json
import boto3

def lambda_handler(event, context):
    print("S3 Event received:")
    print(json.dumps(event, indent=2))
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        event_name = record['eventName']
        
        print(f"Event: {event_name}")
        print(f"Bucket: {bucket}")
        print(f"Object: {key}")
        
        # Process the event (e.g., resize image, process data, etc.)
        
    return {
        'statusCode': 200,
        'body': json.dumps('Event processed successfully')
    }