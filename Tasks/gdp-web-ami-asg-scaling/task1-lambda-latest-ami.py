import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Task 1: Lambda function to get latest AMI for each GDP-Web application
    Returns the most recent AMI backup for gdp-web-1, gdp-web-2, gdp-web-3
    """
    ec2 = boto3.client('ec2')
    
    apps = ['gdp-web-1', 'gdp-web-2', 'gdp-web-3']
    result = {}
    
    for app in apps:
        try:
            # Get AMIs for this application
            response = ec2.describe_images(
                Owners=['self'],
                Filters=[
                    {'Name': 'name', 'Values': [f'{app}-*']},
                    {'Name': 'state', 'Values': ['available']}
                ]
            )
            
            if response['Images']:
                # Sort by creation date, get latest
                latest_ami = sorted(
                    response['Images'], 
                    key=lambda x: x['CreationDate'], 
                    reverse=True
                )[0]
                
                result[app] = {
                    'ami_id': latest_ami['ImageId'],
                    'name': latest_ami['Name'],
                    'creation_date': latest_ami['CreationDate'],
                    'status': 'found'
                }
            else:
                result[app] = {
                    'status': 'no_ami_found',
                    'message': f'No available AMI found for {app}'
                }
                
        except Exception as e:
            result[app] = {
                'status': 'error',
                'message': str(e)
            }
    
    return {
        'statusCode': 200,
        'body': result,
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }

# For local testing
if __name__ == '__main__':
    result = lambda_handler({}, {})
    print(json.dumps(result, indent=2, default=str))