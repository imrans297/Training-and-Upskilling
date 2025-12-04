import boto3
import json
from datetime import datetime

def lambda_handler(event, context):
    """
    Event-driven Lambda: Triggered when AMI backup is created
    Returns latest AMI only for the specific application that triggered the event
    """
    print(f"Lambda triggered with event: {json.dumps(event)}")
    ec2 = boto3.client('ec2')
    
    try:
        # Extract AMI ID from EventBridge event
        ami_id = event['detail']['responseElements']['imageId']
        
        # Get AMI details to identify which application it belongs to
        response = ec2.describe_images(ImageIds=[ami_id])
        
        if not response['Images']:
            return {
                'statusCode': 404,
                'message': 'AMI not found'
            }
        
        ami_info = response['Images'][0]
        ami_name = ami_info['Name']
        
        # Determine which GDP-Web application this AMI belongs to
        app_name = None
        if ami_name.startswith('gdp-web-1-'):
            app_name = 'gdp-web-1'
        elif ami_name.startswith('gdp-web-2-'):
            app_name = 'gdp-web-2'
        elif ami_name.startswith('gdp-web-3-'):
            app_name = 'gdp-web-3'
        
        if not app_name:
            return {
                'statusCode': 400,
                'message': f'AMI {ami_name} does not match GDP-Web naming pattern'
            }
        
        # Get latest AMI for this specific application
        app_response = ec2.describe_images(
            Owners=['self'],
            Filters=[
                {'Name': 'name', 'Values': [f'{app_name}-*']},
                {'Name': 'state', 'Values': ['available']}
            ]
        )
        
        if app_response['Images']:
            # Sort by creation date, get latest
            latest_ami = sorted(
                app_response['Images'],
                key=lambda x: x['CreationDate'],
                reverse=True
            )[0]
            
            result = {
                'statusCode': 200,
                'triggered_by_ami': ami_id,
                'application': app_name,
                'latest_ami': {
                    'ami_id': latest_ami['ImageId'],
                    'ami_name': latest_ami['Name'],
                    'creation_date': latest_ami['CreationDate'],
                    'is_new_backup': latest_ami['ImageId'] == ami_id
                },
                'timestamp': datetime.utcnow().isoformat() + 'Z'
            }
            print(f"Lambda result: {json.dumps(result, default=str)}")
            return result
        else:
            return {
                'statusCode': 404,
                'message': f'No AMIs found for {app_name}'
            }
            
    except KeyError as e:
        return {
            'statusCode': 400,
            'message': f'Invalid event structure: {str(e)}'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'message': f'Error: {str(e)}'
        }

# For manual testing with AMI ID
def test_with_ami_id(ami_id):
    """Test function with specific AMI ID"""
    test_event = {
        'detail': {
            'responseElements': {
                'imageId': ami_id
            }
        }
    }
    return lambda_handler(test_event, {})