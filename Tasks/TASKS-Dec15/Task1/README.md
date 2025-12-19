# Task 1: Highly Available Web Application

## Overview

This task creates a production-ready web application that automatically scales based on traffic and stays available even when servers fail.

## What This Does

Creates a highly available web application using:
- Application Load Balancer
- EC2 Auto Scaling Group
- Multi-AZ deployment
- Automatic scaling based on CPU

## Quick Start

```bash
cd /home/einfochips/TrainingPlanNew/Tasks/TASKS-Dec15/Task1/terraform

terraform init
terraform plan
terraform apply

# Get URL
terraform output alb_url
```

## Files

- `terraform/` - Terraform infrastructure code
  - `main.tf` - Main infrastructure code
  - `variables.tf` - Configuration variables
  - `outputs.tf` - Output values
  - `terraform.tfvars` - Variable values
  - `user_data.sh` - Web server setup script
  - `deploy.sh` - Deployment automation script
- `screenshots/` - Screenshots directory
- `DOCUMENTATION.md` - Detailed documentation with screenshots
- `SCREENSHOT_GUIDE.md` - Screenshot capture guide
- `test-scaling.sh` - Auto scaling monitoring script

## Architecture

```
Internet → ALB → EC2 Instances (2 AZs) → Auto Scaling
```

## Auto Scaling Rules

- **Scale Out**: CPU > 60% → Add 1 instance
- **Scale In**: CPU < 20% → Remove 1 instance
- **Min**: 1 instance
- **Max**: 3 instances
- **Desired**: 2 instances

## Testing

1. **Failover**: Stop one instance, app stays up
2. **Scale Out**: Increase CPU, watch it scale
3. **Scale In**: Decrease CPU, watch it scale down

## Cleanup

```bash
cd terraform
terraform destroy
```

## Documentation

See [DOCUMENTATION.md](./DOCUMENTATION.md) for:
- Step-by-step deployment
- Screenshots guide
- Testing procedures
- Troubleshooting

## Cost

~$0.05/hour (~$1.20/day) for testing

---

**Status**: Ready to deploy
