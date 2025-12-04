import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Terraform Lambda: Get latest AMI for each GDP-Web application
    """
    ec2 = boto3.client('ec2')
    
    apps = ['gdp-web-1', 'gdp-web-2', 'gdp-web-3']
    result = {}
    
    for app in apps:
        try:
            response = ec2.describe_images(
                Owners=['self'],
                Filters=[
                    {'Name': 'name', 'Values': [f'{app}-*']},
                    {'Name': 'state', 'Values': ['available']}
                ]
            )
            
            if response['Images']:
                latest = sorted(response['Images'], 
                              key=lambda x: x['CreationDate'], 
                              reverse=True)[0]
                
                result[app] = {
                    'ami_id': latest['ImageId'],
                    'name': latest['Name'],
                    'creation_date': latest['CreationDate'],
                    'status': 'found'
                }
            else:
                result[app] = {
                    'status': 'not_found'
                }
                
        except Exception as e:
            result[app] = {
                'status': 'error',
                'message': str(e)
            }
    
    return {
        'statusCode': 200,
        'body': result,
        'deployment': 'terraform'
    }