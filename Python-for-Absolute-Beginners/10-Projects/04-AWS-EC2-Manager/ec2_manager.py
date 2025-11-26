#!/usr/bin/env python3
"""
AWS EC2 Instance Manager - Starter Code
"""

import boto3
import sys

# Initialize EC2 client
ec2 = boto3.client('ec2', region_name='ap-south-1')

def list_instances():
    """List all EC2 instances"""
    # TODO: Implement
    pass

def start_instance(instance_id):
    """Start an EC2 instance"""
    # TODO: Implement
    pass

def stop_instance(instance_id):
    """Stop an EC2 instance"""
    # TODO: Implement
    pass

def get_instance_details(instance_id):
    """Get detailed information about an instance"""
    # TODO: Implement
    pass

def filter_by_tag(tag_key, tag_value):
    """Filter instances by tag"""
    # TODO: Implement
    pass

def main():
    """Main CLI interface"""
    if len(sys.argv) < 2:
        print("Usage: python3 ec2_manager.py [command] [args]")
        print("Commands: list, start, stop, details, filter")
        return
    
    command = sys.argv[1]
    
    # TODO: Implement command routing
    if command == "list":
        list_instances()
    elif command == "start":
        # TODO: Get instance_id from sys.argv[2]
        pass
    elif command == "stop":
        # TODO: Get instance_id from sys.argv[2]
        pass
    # Add more commands...

if __name__ == "__main__":
    main()
