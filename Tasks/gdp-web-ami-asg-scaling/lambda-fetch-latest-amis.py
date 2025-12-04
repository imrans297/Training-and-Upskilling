import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Fetch Latest AMIs for GDP-Web Applications
    Returns the most recent AMI for each application: gdp-web-1, gdp-web-2, gdp-web-3
    """
    ec2 = boto3.client('ec2')
    
    applications = ['gdp-web-1', 'gdp-web-2', 'gdp-web-3']
    latest_amis = {}
    
    for app in applications:
        try:
            # Get all AMIs for this application
            response = ec2.describe_images(
                Owners=['self'],
                Filters=[
                    {'Name': 'name', 'Values': [f'{app}-*']},
                    {'Name': 'state', 'Values': ['available']}
                ]
            )
            
            if response['Images']:
                # Sort by creation date and get the latest
                sorted_amis = sorted(
                    response['Images'],
                    key=lambda x: x['CreationDate'],
                    reverse=True
                )
                
                latest_ami = sorted_amis[0]
                
                latest_amis[app] = latest_ami['ImageId']
            else:
                latest_amis[app] = {
                    'status': 'not_found',
                    'message': f'No available AMI found for {app}'
                }
                
        except Exception as e:
            latest_amis[app] = {
                'status': 'error',
                'error_message': str(e)
            }
    
    return latest_amis

# For local testing
if __name__ == '__main__':
    result = lambda_handler({}, {})
    print(json.dumps(result, indent=2, default=str))