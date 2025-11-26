# Project 4: AWS EC2 Instance Manager

## Objective
Build a CLI tool to manage AWS EC2 instances using boto3.

## Prerequisites
- AWS account
- AWS CLI configured
- boto3 installed: `pip3 install boto3`

## Features to Implement

### 1. List Instances
- Display all EC2 instances
- Show: Instance ID, Type, State, Name tag

### 2. Start Instance
- Start a stopped instance by ID
- Confirm action before starting

### 3. Stop Instance
- Stop a running instance by ID
- Confirm action before stopping

### 4. Instance Details
- Show detailed info for specific instance
- Include: VPC, subnet, security groups, IP addresses

### 5. Filter by Tag
- List instances with specific tag
- Example: Environment=production

## Project Structure
```
ec2_manager.py      # Main script
config.py           # AWS configuration
utils.py            # Helper functions
README.md           # This file
```

## Sample Usage
```bash
python3 ec2_manager.py list
python3 ec2_manager.py start i-1234567890abcdef0
python3 ec2_manager.py stop i-1234567890abcdef0
python3 ec2_manager.py details i-1234567890abcdef0
python3 ec2_manager.py filter Environment production
```

## Bonus Features
- Reboot instance
- Create new instance
- Terminate instance
- Export to CSV
- Cost estimation

## Learning Outcomes
- AWS SDK (boto3) usage
- API interaction
- Error handling
- CLI argument parsing
- Real-world automation
