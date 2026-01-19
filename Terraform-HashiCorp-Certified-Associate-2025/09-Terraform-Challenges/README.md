# 09. Terraform Challenges & Exam Preparation

## Real-World Scenarios

### Scenario 1: Multi-Tier Application

**Requirement**: Deploy 3-tier web application (web, app, database) with high availability.

**Solution**:
```hcl
# VPC with public and private subnets
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

# Auto Scaling Group for web tier
resource "aws_autoscaling_group" "web" {
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
  vpc_zone_identifier = module.vpc.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

# RDS Multi-AZ
resource "aws_db_instance" "main" {
  identifier          = "app-database"
  engine              = "mysql"
  instance_class      = "db.t3.medium"
  multi_az            = true
  db_subnet_group_name = aws_db_subnet_group.main.name
}
```

---

### Scenario 2: State File Corruption

**Problem**: State file corrupted, Terraform can't proceed.

**Solution**:
```bash
# 1. Backup current state
cp terraform.tfstate terraform.tfstate.backup

# 2. If using S3, download previous version
aws s3api list-object-versions \
  --bucket my-terraform-state \
  --prefix terraform.tfstate

aws s3api get-object \
  --bucket my-terraform-state \
  --key terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.recovered

# 3. Restore state
cp terraform.tfstate.recovered terraform.tfstate

# 4. Verify
terraform plan
```

---

### Scenario 3: Circular Dependency

**Problem**: Two resources depend on each other.

**Bad**:
```hcl
resource "aws_security_group" "app" {
  ingress {
    security_groups = [aws_security_group.db.id]
  }
}

resource "aws_security_group" "db" {
  ingress {
    security_groups = [aws_security_group.app.id]
  }
}
# Error: Cycle detected
```

**Solution**: Use separate security group rules
```hcl
resource "aws_security_group" "app" {
  name = "app-sg"
}

resource "aws_security_group" "db" {
  name = "db-sg"
}

resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.db.id
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
}
```

---

## Common Errors & Solutions

### Error 1: Provider Configuration Not Found

**Error**:
```
Error: Provider configuration not present
```

**Solution**:
```hcl
# Add provider block
provider "aws" {
  region = "us-east-1"
}
```

### Error 2: Resource Already Exists

**Error**:
```
Error: resource already exists
```

**Solution**:
```bash
# Import existing resource
terraform import aws_instance.web i-1234567890abcdef0
```

### Error 3: State Lock Timeout

**Error**:
```
Error acquiring the state lock
```

**Solution**:
```bash
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### Error 4: Invalid Count Argument

**Error**:
```
Error: Invalid count argument
The "count" value depends on resource attributes that cannot be determined until apply
```

**Solution**: Use `-target` or separate into multiple applies
```bash
terraform apply -target=aws_vpc.main
terraform apply
```

---

## Troubleshooting Guide

### Debug Mode

```bash
# Enable debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

terraform apply

# View logs
cat terraform.log
```

**Log Levels**: TRACE, DEBUG, INFO, WARN, ERROR

### Validate Configuration

```bash
# Check syntax
terraform validate

# Format code
terraform fmt -recursive

# Check for issues
terraform plan
```

### Refresh State

```bash
# Sync state with reality
terraform refresh

# Or during plan
terraform plan -refresh-only
```

---

## Best Practices Checklist

### Code Organization
- [ ] Use modules for reusability
- [ ] Separate environments (dev/staging/prod)
- [ ] Consistent naming conventions
- [ ] Meaningful resource names
- [ ] Comments for complex logic

### State Management
- [ ] Use remote state (S3/Terraform Cloud)
- [ ] Enable state locking
- [ ] Encrypt state files
- [ ] Regular state backups
- [ ] Version control for code (not state)

### Security
- [ ] No hardcoded secrets
- [ ] Use Secrets Manager/Vault
- [ ] Mark sensitive variables
- [ ] Proper .gitignore
- [ ] Least privilege IAM
- [ ] Enable encryption

### Collaboration
- [ ] Code reviews
- [ ] Consistent formatting (terraform fmt)
- [ ] Documentation (README)
- [ ] Version pinning
- [ ] CI/CD integration

### Performance
- [ ] Use data sources wisely
- [ ] Minimize provider calls
- [ ] Parallel resource creation
- [ ] Target specific resources when needed
- [ ] Use workspaces for environments

---

## Exam Preparation

### Exam Details

**HashiCorp Certified: Terraform Associate (003)**
- **Duration**: 60 minutes
- **Questions**: 57 multiple choice/multiple select
- **Passing Score**: Not disclosed
- **Cost**: $70.50 USD
- **Validity**: 2 years
- **Format**: Online proctored

### Exam Objectives

**1. Understand Infrastructure as Code (IaC) concepts**
- Benefits of IaC
- IaC vs traditional approaches

**2. Understand Terraform's purpose**
- Multi-cloud and provider-agnostic
- Terraform workflow

**3. Understand Terraform basics**
- Terraform vs other IaC tools
- Terraform Cloud benefits

**4. Use the Terraform CLI**
- init, validate, plan, apply, destroy
- fmt, taint, import, workspace

**5. Interact with Terraform modules**
- Module sources and versions
- Module inputs and outputs
- Public and private registries

**6. Navigate Terraform workflow**
- Terraform workflow steps
- Initialize working directory
- Validate and format

**7. Implement and maintain state**
- State purpose and storage
- State locking
- Backend configuration
- State commands

**8. Read, generate, and modify configuration**
- Variables and outputs
- Resource addressing
- Built-in functions
- Dynamic blocks

**9. Understand Terraform Cloud capabilities**
- Remote state and execution
- VCS integration
- Sentinel policies
- Private registry

### Sample Questions

**Q1**: What is the purpose of `terraform init`?
- A) Apply configuration changes
- B) Download provider plugins and initialize backend
- C) Validate configuration syntax
- D) Destroy infrastructure

**Answer**: B

**Q2**: Which command shows the execution plan without making changes?
- A) terraform show
- B) terraform apply
- C) terraform plan
- D) terraform validate

**Answer**: C

**Q3**: What is the default workspace name?
- A) main
- B) default
- C) master
- D) prod

**Answer**: B

**Q4**: Which meta-argument creates multiple resource instances?
- A) for_each or count
- B) multiple
- C) replicate
- D) instances

**Answer**: A

**Q5**: Where is state stored by default?
- A) Terraform Cloud
- B) S3 bucket
- C) Local file (terraform.tfstate)
- D) DynamoDB

**Answer**: C

### Study Tips

**1. Hands-on Practice** (Most Important)
- Complete all labs in this course
- Build real projects
- Practice on AWS free tier

**2. Review Documentation**
- Terraform.io official docs
- Provider documentation
- Best practices guides

**3. Understand Concepts**
- Don't just memorize commands
- Understand WHY, not just HOW
- Know when to use each feature

**4. Practice Exam Questions**
- HashiCorp sample questions
- Practice tests online
- Review incorrect answers

**5. Time Management**
- 60 minutes for 57 questions
- ~1 minute per question
- Flag difficult questions, return later

---

## Final Lab: Production-Ready Application

### Objective
Deploy complete production application using all concepts learned.

### Architecture
```
Internet → ALB → ASG (Web Tier) → RDS (Database)
                  ↓
              S3 (Static Files)
                  ↓
              CloudFront (CDN)
```

### Project Structure
```
final-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── asg/
│   └── rds/
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

### Implementation Highlights

**Remote State**:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

**Modules**:
```hcl
module "vpc" {
  source = "./modules/vpc"
  # ...
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  # ...
}
```

**Workspaces**:
```bash
terraform workspace new prod
terraform apply -var-file=environments/prod.tfvars
```

**Security**:
```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}
```

---

## Key Takeaways

✅ **Foundation**: IaC, Terraform basics, HCL syntax  
✅ **Core Skills**: Resources, variables, state management  
✅ **Advanced**: Modules, workspaces, remote state  
✅ **Production**: Security, collaboration, best practices  
✅ **Certification**: 75%+ exam coverage in this course  

---

## Congratulations! 🎉

You've completed the **Terraform HashiCorp Certified Associate 2025** course!

**What You've Learned**:
- ✅ 9 comprehensive sections
- ✅ 9 hands-on labs
- ✅ 300+ code examples
- ✅ Production-ready skills
- ✅ Certification preparation

**Next Steps**:
1. Practice with real projects
2. Take practice exams
3. Schedule certification exam
4. Join Terraform community

**Good luck with your certification! 🚀**

---

## Additional Resources

**Official**:
- [Terraform Documentation](https://www.terraform.io/docs)
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [Terraform Registry](https://registry.terraform.io)

**Community**:
- [Terraform GitHub](https://github.com/hashicorp/terraform)
- [Terraform Discuss](https://discuss.hashicorp.com/c/terraform-core)
- [r/Terraform](https://reddit.com/r/Terraform)

**Practice**:
- [Terraform Tutorials](https://learn.hashicorp.com/tutorials/terraform)
- [AWS Free Tier](https://aws.amazon.com/free)
- [Terraform Examples](https://github.com/terraform-aws-modules)
