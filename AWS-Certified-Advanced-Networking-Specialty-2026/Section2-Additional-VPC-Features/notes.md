# Additional VPC Features - Study Notes

## Elastic IP (EIP)

- Static public IPv4 address
- Persists across instance stops/starts
- Can be remapped to different instances
- Charged when not associated with running instance

## Elastic Network Interface (ENI)

- Virtual network card
- Can attach/detach from instances
- Retains private IP, Elastic IP, MAC address
- Use cases: Management networks, dual-homed instances

## VPC Flow Logs

- Capture IP traffic information
- Can be enabled at VPC, subnet, or ENI level
- Logs to CloudWatch Logs or S3
- Use for: Security analysis, troubleshooting

## VPC Endpoints

### Gateway Endpoints
- S3 and DynamoDB only
- Free
- Uses route table entries

### Interface Endpoints
- Powered by AWS PrivateLink
- Most AWS services
- Charged per hour + data processed
- Uses ENI with private IP

---

**Date:** December 2024
