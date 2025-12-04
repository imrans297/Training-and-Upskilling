import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to update ASG Launch Template with latest AMI
    Triggers when new GDP-Web AMI is created
    """
    
    print(f"Received event: {json.dumps(event)}")
    
    ec2 = boto3.client('ec2')
    autoscaling = boto3.client('autoscaling')
    
    try:
        # Extract AMI ID from EventBridge event
        detail = event.get('detail', {})
        ami_id = detail.get('responseElements', {}).get('imageId')
        ami_name = detail.get('requestParameters', {}).get('name', '')
        
        print(f"Processing AMI: {ami_id}, Name: {ami_name}")
        
        # Only process GDP-Web AMIs
        if not ami_name.startswith('gdp-web-'):
            print(f"Skipping non-GDP-Web AMI: {ami_name}")
            return {'statusCode': 200, 'body': 'Not a GDP-Web AMI'}
        
        # Get latest GDP-Web AMI (in case multiple AMIs exist)
        response = ec2.describe_images(
            Owners=['self'],
            Filters=[
                {'Name': 'name', 'Values': ['gdp-web-*']},
                {'Name': 'state', 'Values': ['available']}
            ]
        )
        
        if not response['Images']:
            print("No GDP-Web AMIs found")
            return {'statusCode': 404, 'body': 'No GDP-Web AMIs found'}
        
        # Sort by creation date and get latest
        latest_ami = sorted(response['Images'], key=lambda x: x['CreationDate'])[-1]
        latest_ami_id = latest_ami['ImageId']
        
        print(f"Latest GDP-Web AMI: {latest_ami_id}")
        print(f"Latest AMI Name: {latest_ami['Name']}")
        print(f"Latest AMI Creation Date: {latest_ami['CreationDate']}")
        
        # Update Launch Template
        launch_template_name = 'gdp-web-asg-lt'
        
        # Get current launch template
        lt_response = ec2.describe_launch_template_versions(
            LaunchTemplateName=launch_template_name,
            Versions=['$Latest']
        )
        
        current_version = lt_response['LaunchTemplateVersions'][0]
        current_ami = current_version['LaunchTemplateData']['ImageId']
        
        print(f"Current Launch Template AMI: {current_ami}")
        print(f"Current Launch Template Version: {current_version['VersionNumber']}")
        
        if current_ami == latest_ami_id:
            print("Launch Template already uses latest AMI")
            return {'statusCode': 200, 'body': 'Launch Template already up to date'}
        
        # Create new launch template version with latest AMI
        new_version_response = ec2.create_launch_template_version(
            LaunchTemplateName=launch_template_name,
            LaunchTemplateData={
                'ImageId': latest_ami_id,
                'InstanceType': current_version['LaunchTemplateData']['InstanceType'],
                'KeyName': current_version['LaunchTemplateData']['KeyName'],
                'SecurityGroupIds': current_version['LaunchTemplateData']['SecurityGroupIds'],
                'IamInstanceProfile': current_version['LaunchTemplateData'].get('IamInstanceProfile', {}),
                'UserData': current_version['LaunchTemplateData'].get('UserData', '')
            },
            SourceVersion='$Latest'
        )
        
        new_version = new_version_response['LaunchTemplateVersion']['VersionNumber']
        print(f"Created new launch template version: {new_version}")
        print(f"New version uses AMI: {latest_ami_id}")
        
        # Set new version as default
        ec2.modify_launch_template(
            LaunchTemplateName=launch_template_name,
            DefaultVersion=str(new_version)
        )
        
        print(f"Set version {new_version} as default")
        print(f"Launch template {launch_template_name} now uses AMI {latest_ami_id}")
        
        # Update Auto Scaling Group to use new version
        asg_name = "gdp-web-asg-final"
        
        autoscaling.update_auto_scaling_group(
            AutoScalingGroupName=asg_name,
            LaunchTemplate={
                'LaunchTemplateName': launch_template_name,
                'Version': '$Latest'
            }
        )
        
        print(f"Updated ASG {asg_name} to use latest launch template version")
        
        # Trigger instance refresh to replace instances with new AMI
        refresh_response = autoscaling.start_instance_refresh(
            AutoScalingGroupName=asg_name,
            Strategy='Rolling',
            Preferences={
                'InstanceWarmup': 300,
                'MinHealthyPercentage': 50
            }
        )
        
        refresh_id = refresh_response['InstanceRefreshId']
        print(f"Started instance refresh: {refresh_id}")
        
        result = {
            'statusCode': 200,
            'body': {
                'message': 'Launch Template updated successfully',
                'previous_ami': current_ami,
                'new_ami': latest_ami_id,
                'launch_template': launch_template_name,
                'previous_version': current_version['VersionNumber'],
                'new_version': new_version,
                'instance_refresh_id': refresh_id
            }
        }
        
        print(f"=== UPDATE SUMMARY ===")
        print(f"Previous AMI: {current_ami}")
        print(f"New AMI: {latest_ami_id}")
        print(f"Launch Template: {launch_template_name}")
        print(f"New Version: {new_version}")
        print(f"Instance Refresh ID: {refresh_id}")
        print(f"Result: {json.dumps(result)}")
        return result
        
    except Exception as e:
        error_msg = f"Error updating launch template: {str(e)}"
        print(error_msg)
        return {
            'statusCode': 500,
            'body': {'error': error_msg}
        }