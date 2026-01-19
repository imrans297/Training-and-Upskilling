# Terraform Interview Questions - 5 Years Experience

## Basic Concepts (Warm-up Questions)

### Q1: What is Terraform and why do we use it?

**Answer**:
Terraform is an Infrastructure as Code (IaC) tool that allows you to define and provision infrastructure using declarative configuration files.

**Why use it**:
- **Version Control**: Infrastructure changes tracked in Git
- **Automation**: Eliminate manual provisioning
- **Consistency**: Same infrastructure every time
- **Multi-cloud**: Works with AWS, Azure, GCP, etc.
- **State Management**: Tracks real infrastructure

**Example**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

---

### Q2: Explain Terraform workflow (init, plan, apply, destroy).

**Answer**:

**1. terraform init**:
- Downloads provider plugins
- Initializes backend
- Prepares working directory

**2. terraform plan**:
- Creates execution plan
- Shows what will change
- No actual changes made

**3. terraform apply**:
- Executes the plan
- Creates/modifies/deletes resources
- Updates state file

**4. terraform destroy**:
- Removes all managed infrastructure
- Cleans up resources

**Real-world example**:
```bash
terraform init
terraform plan -out=tfplan
# Review plan
terraform apply tfplan
# Later...
terraform destroy
```

---

### Q3: What is Terraform state and why is it important?

**Answer**:
State is Terraform's database that maps configuration to real infrastructure.

**Purpose**:
- **Tracking**: Knows what exists
- **Metadata**: Stores resource dependencies
- **Performance**: Caches resource attributes
- **Collaboration**: Shared understanding of infrastructure

**State file** (`terraform.tfstate`):
```json
{
  "version": 4,
  "resources": [{
    "type": "aws_instance",
    "name": "web",
    "instances": [{
      "attributes": {
        "id": "i-1234567890abcdef0",
        "public_ip": "54.123.45.67"
      }
    }]
  }]
}
```

**Best practices**:
- Store remotely (S3, Terraform Cloud)
- Enable state locking
- Never edit manually
- Enable versioning

---

## Intermediate Questions

### Q4: What's the difference between count and for_each?

**Answer**:

**count** - Creates multiple identical resources with index:
```hcl
resource "aws_instance" "server" {
  count         = 3
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "server-${count.index}"  # server-0, server-1, server-2
  }
}

# Access: aws_instance.server[0], aws_instance.server[1]
```

**for_each** - Creates resources from map/set with keys:
```hcl
resource "aws_instance" "server" {
  for_each = {
    web = "t2.micro"
    app = "t2.small"
    db  = "t2.medium"
  }
  
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = each.value
  
  tags = {
    Name = each.key  # web, app, db
  }
}

# Access: aws_instance.server["web"], aws_instance.server["app"]
```

**When to use**:
- **count**: Simple duplication, order doesn't matter
- **for_each**: Named resources, stable identifiers

**Problem with count**:
```hcl
# If you remove middle element, Terraform recreates all after it
count = 3  # [0, 1, 2]
# Remove index 1 → [0, 2] becomes [0, 1] → recreates instance 2
```

---

### Q5: Explain Terraform modules and their benefits.

**Answer**:
Modules are containers for multiple resources used together.

**Benefits**:
- **Reusability**: Write once, use many times
- **Organization**: Logical grouping
- **Encapsulation**: Hide complexity
- **Versioning**: Track changes
- **Sharing**: Team/community modules

**Module structure**:
```
modules/vpc/
├── main.tf       # Resources
├── variables.tf  # Inputs
├── outputs.tf    # Outputs
└── README.md     # Documentation
```

**Using module**:
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name = "production"
  vpc_cidr = "10.0.0.0/16"
}

# Access outputs
resource "aws_instance" "web" {
  subnet_id = module.vpc.public_subnet_ids[0]
}
```

**Module sources**:
- Local: `./modules/vpc`
- Registry: `terraform-aws-modules/vpc/aws`
- GitHub: `github.com/user/repo`
- Git: `git::https://example.com/vpc.git`

---

### Q6: How do you manage secrets in Terraform?

**Answer**:

**❌ Never do this**:
```hcl
variable "db_password" {
  default = "MyPassword123"  # DON'T!
}
```

**✅ Best practices**:

**1. Environment Variables**:
```bash
export TF_VAR_db_password="SecretPassword"
terraform apply
```

**2. AWS Secrets Manager**:
```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "main" {
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
}
```

**3. HashiCorp Vault**:
```hcl
data "vault_generic_secret" "db_password" {
  path = "secret/database/password"
}

resource "aws_db_instance" "main" {
  password = data.vault_generic_secret.db_password.data["password"]
}
```

**4. Sensitive variables**:
```hcl
variable "db_password" {
  type      = string
  sensitive = true  # Hidden from output
}

output "db_password" {
  value     = var.db_password
  sensitive = true  # Hidden from console
}
```

---

### Q7: What is remote state and why use it?

**Answer**:

**Remote state** = State stored in remote backend (S3, Terraform Cloud).

**Why use it**:
- **Collaboration**: Team access
- **Locking**: Prevents concurrent modifications
- **Encryption**: Secure storage
- **Versioning**: State history
- **Backup**: Automatic backups

**S3 Backend with DynamoDB locking**:
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

**Setup**:
```hcl
# 1. Create S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state"
}

# 2. Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Create DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## Advanced Questions

### Q8: How do you handle Terraform state file corruption?

**Answer**:

**Prevention**:
- Enable S3 versioning
- Regular backups
- State locking
- Never edit manually

**Recovery steps**:

**1. From S3 versions**:
```bash
# List versions
aws s3api list-object-versions \
  --bucket my-terraform-state \
  --prefix terraform.tfstate

# Download previous version
aws s3api get-object \
  --bucket my-terraform-state \
  --key terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.recovered

# Restore
cp terraform.tfstate.recovered terraform.tfstate
terraform plan  # Verify
```

**2. From local backup**:
```bash
cp terraform.tfstate.backup terraform.tfstate
terraform refresh
terraform plan
```

**3. Rebuild state** (last resort):
```bash
# Import each resource
terraform import aws_instance.web i-1234567890abcdef0
terraform import aws_s3_bucket.data my-bucket-name
```

---

### Q9: Explain Terraform workspaces and when to use them.

**Answer**:

**Workspaces** = Multiple state files for same configuration.

**Use cases**:
- ✅ Multiple environments (dev, staging, prod)
- ✅ Testing changes
- ✅ Temporary deployments
- ❌ Different configurations (use separate directories)
- ❌ Different regions (use separate backends)

**Commands**:
```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace list
terraform workspace select dev
```

**Configuration**:
```hcl
locals {
  env_config = {
    dev = {
      instance_type = "t2.micro"
      instance_count = 1
    }
    prod = {
      instance_type = "t2.large"
      instance_count = 5
    }
  }
  
  config = local.env_config[terraform.workspace]
}

resource "aws_instance" "web" {
  count         = local.config.instance_count
  instance_type = local.config.instance_type
  
  tags = {
    Environment = terraform.workspace
  }
}
```

**State files**:
```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

---

### Q10: How do you import existing infrastructure into Terraform?

**Answer**:

**Steps**:

**1. Create resource block** (empty):
```hcl
resource "aws_instance" "existing" {
  # Will be populated after import
}
```

**2. Import resource**:
```bash
terraform import aws_instance.existing i-1234567890abcdef0
```

**3. Run plan** to see differences:
```bash
terraform plan
# Shows what attributes are missing
```

**4. Update configuration** to match:
```hcl
resource "aws_instance" "existing" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  # ... other attributes from plan output
}
```

**5. Verify**:
```bash
terraform plan
# Should show: No changes
```

**Bulk import script**:
```bash
#!/bin/bash
# Import multiple instances
for instance_id in $(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text); do
  terraform import "aws_instance.imported[\"$instance_id\"]" "$instance_id"
done
```

---

### Q11: What are provisioners and when should you use them?

**Answer**:

**Provisioners** = Execute scripts on local/remote machines after resource creation.

**Types**:
- **local-exec**: Runs on machine running Terraform
- **remote-exec**: Runs on remote resource (SSH/WinRM)
- **file**: Copies files to remote resource

**Example**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd"
    ]
  }
}
```

**When to use**:
- ❌ Configuration management (use Ansible/Chef)
- ❌ Application deployment (use CI/CD)
- ✅ Bootstrap config management tools
- ✅ One-time initialization
- ✅ Trigger external systems

**Better alternatives**:
```hcl
# Use user_data instead
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              EOF
}
```

---

### Q12: How do you handle circular dependencies in Terraform?

**Answer**:

**Problem**:
```hcl
resource "aws_security_group" "app" {
  ingress {
    security_groups = [aws_security_group.db.id]  # Depends on db
  }
}

resource "aws_security_group" "db" {
  ingress {
    security_groups = [aws_security_group.app.id]  # Depends on app
  }
}
# Error: Cycle detected
```

**Solution 1: Separate rules**:
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

**Solution 2: Use depends_on** (if implicit dependency):
```hcl
resource "aws_instance" "web" {
  # ...
  depends_on = [aws_security_group.web_sg]
}
```

---

## Scenario-Based Questions

### Q13: You need to deploy infrastructure to multiple AWS accounts. How would you design this?

**Answer**:

**Approach 1: Multiple provider aliases**:
```hcl
provider "aws" {
  alias  = "account1"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::111111111111:role/TerraformRole"
  }
}

provider "aws" {
  alias  = "account2"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::222222222222:role/TerraformRole"
  }
}

resource "aws_instance" "web_account1" {
  provider = aws.account1
  # ...
}

resource "aws_instance" "web_account2" {
  provider = aws.account2
  # ...
}
```

**Approach 2: Separate directories**:
```
terraform/
├── account1/
│   ├── main.tf
│   ├── backend.tf  # S3 bucket in account1
│   └── terraform.tfvars
└── account2/
    ├── main.tf
    ├── backend.tf  # S3 bucket in account2
    └── terraform.tfvars
```

**Approach 3: Terraform Cloud workspaces**:
- Separate workspace per account
- Different AWS credentials per workspace
- VCS-driven workflow

---

### Q14: Production database was manually modified. How do you detect and fix drift?

**Answer**:

**Detection**:
```bash
# 1. Run plan to detect drift
terraform plan
# Output shows:
# ~ aws_db_instance.main will be updated in-place
# ~ instance_class = "db.t3.large" -> "db.t3.medium"
```

**Options**:

**Option 1: Revert to Terraform config** (recommended):
```bash
terraform apply
# Reverts database to db.t3.medium
```

**Option 2: Update Terraform to match reality**:
```hcl
resource "aws_db_instance" "main" {
  instance_class = "db.t3.large"  # Update config
}

terraform plan  # No changes
```

**Option 3: Ignore specific attributes**:
```hcl
resource "aws_db_instance" "main" {
  instance_class = "db.t3.medium"
  
  lifecycle {
    ignore_changes = [instance_class]  # Allow manual changes
  }
}
```

**Prevention**:
- Use Terraform Cloud with Sentinel policies
- Enable CloudTrail for audit
- Restrict manual access
- Regular drift detection (scheduled plans)

---

### Q15: How would you implement blue-green deployment with Terraform?

**Answer**:

**Strategy**:
```hcl
variable "active_environment" {
  description = "Active environment (blue or green)"
  type        = string
  default     = "blue"
}

# Blue environment
module "blue" {
  source = "./modules/app"
  
  environment = "blue"
  ami_version = "v1.0"
  enabled     = var.active_environment == "blue"
}

# Green environment
module "green" {
  source = "./modules/app"
  
  environment = "green"
  ami_version = "v2.0"
  enabled     = var.active_environment == "green"
}

# ALB target group
resource "aws_lb_target_group_attachment" "active" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.active_environment == "blue" ? module.blue.instance_id : module.green.instance_id
}
```

**Deployment process**:
```bash
# 1. Deploy green (new version)
terraform apply -var="active_environment=blue"
# Both blue and green exist

# 2. Test green environment
curl http://green.example.com

# 3. Switch traffic to green
terraform apply -var="active_environment=green"

# 4. Destroy blue (old version)
# Update module to destroy when not enabled
```

**Using Route53 weighted routing**:
```hcl
resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  weighted_routing_policy {
    weight = var.active_environment == "blue" ? 100 : 0
  }
  
  alias {
    name    = module.blue.alb_dns_name
    zone_id = module.blue.alb_zone_id
  }
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  weighted_routing_policy {
    weight = var.active_environment == "green" ? 100 : 0
  }
  
  alias {
    name    = module.green.alb_dns_name
    zone_id = module.green.alb_zone_id
  }
}
```

---

## Troubleshooting Questions

### Q16: Terraform apply is stuck. What do you check?

**Answer**:

**1. Check for state lock**:
```bash
# Error message shows lock ID
terraform force-unlock <LOCK_ID>
```

**2. Enable debug logging**:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
cat terraform.log
```

**3. Check provider API limits**:
- AWS rate limiting
- Too many concurrent requests
- API throttling

**4. Check resource dependencies**:
```bash
terraform graph | dot -Tpng > graph.png
# Look for circular dependencies
```

**5. Check network connectivity**:
- VPN connection
- AWS credentials
- Internet access

**6. Target specific resource**:
```bash
terraform apply -target=aws_instance.web
```

---

### Q17: How do you recover from "Error: resource already exists"?

**Answer**:

**Cause**: Resource exists in AWS but not in state.

**Solution 1: Import existing resource**:
```bash
terraform import aws_instance.web i-1234567890abcdef0
terraform plan  # Should show no changes
```

**Solution 2: Remove from AWS and recreate**:
```bash
# Manually delete from AWS Console/CLI
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Then apply
terraform apply
```

**Solution 3: Rename in Terraform**:
```hcl
# Change resource name
resource "aws_instance" "web_new" {  # Changed from "web"
  # ...
}
```

**Prevention**:
- Always import before creating
- Use unique names
- Check existing resources first

---

## Best Practices Questions

### Q18: What are Terraform best practices you follow?

**Answer**:

**1. Code Organization**:
```
project/
├── main.tf          # Main resources
├── variables.tf     # Input variables
├── outputs.tf       # Outputs
├── versions.tf      # Provider versions
├── backend.tf       # Backend config
├── modules/         # Reusable modules
└── environments/    # Environment configs
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

**2. State Management**:
- Remote state (S3 + DynamoDB)
- State locking enabled
- Encryption at rest
- Versioning enabled
- Regular backups

**3. Security**:
- No hardcoded secrets
- Sensitive variables marked
- Proper .gitignore
- Least privilege IAM
- Secrets in Vault/Secrets Manager

**4. Version Control**:
- Pin provider versions
- Use semantic versioning for modules
- Tag releases
- Code reviews

**5. Naming Conventions**:
```hcl
# Resource naming: <project>-<environment>-<resource>-<purpose>
resource "aws_instance" "web" {
  tags = {
    Name        = "myapp-prod-web-server"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

**6. Documentation**:
- README for each module
- Comments for complex logic
- Variable descriptions
- Output descriptions

---

### Q19: How do you implement CI/CD for Terraform?

**Answer**:

**Pipeline stages**:

**1. Validate**:
```yaml
# .github/workflows/terraform.yml
validate:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - uses: hashicorp/setup-terraform@v1
    - run: terraform init
    - run: terraform validate
    - run: terraform fmt -check
```

**2. Plan**:
```yaml
plan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - uses: hashicorp/setup-terraform@v1
    - run: terraform init
    - run: terraform plan -out=tfplan
    - uses: actions/upload-artifact@v2
      with:
        name: tfplan
        path: tfplan
```

**3. Apply** (manual approval):
```yaml
apply:
  runs-on: ubuntu-latest
  needs: plan
  environment: production  # Requires approval
  steps:
    - uses: actions/checkout@v2
    - uses: hashicorp/setup-terraform@v1
    - uses: actions/download-artifact@v2
      with:
        name: tfplan
    - run: terraform init
    - run: terraform apply tfplan
```

**Best practices**:
- Separate pipelines for each environment
- Manual approval for production
- Store state in remote backend
- Use Terraform Cloud for remote runs
- Implement policy checks (Sentinel)

---

### Q20: Explain your experience with a complex Terraform project.

**Answer** (Customize based on your experience):

**Project**: Multi-region, multi-account AWS infrastructure

**Architecture**:
- 3 AWS accounts (dev, staging, prod)
- 2 regions per account (us-east-1, us-west-2)
- VPC with public/private subnets
- EKS clusters
- RDS Multi-AZ databases
- S3 buckets with replication
- CloudFront distributions

**Structure**:
```
terraform/
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   └── s3/
├── accounts/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── shared/
    └── terraform-backend/
```

**Challenges & Solutions**:

**1. State management**:
- Problem: Multiple teams, state conflicts
- Solution: Separate state files per account/region, DynamoDB locking

**2. Secrets management**:
- Problem: Database passwords, API keys
- Solution: AWS Secrets Manager integration, no secrets in code

**3. Module versioning**:
- Problem: Breaking changes in modules
- Solution: Semantic versioning, private module registry

**4. Drift detection**:
- Problem: Manual changes in production
- Solution: Scheduled Terraform plans, Sentinel policies

**5. Cost optimization**:
- Problem: Over-provisioned resources
- Solution: Terraform Cloud cost estimation, right-sizing

**Results**:
- 500+ resources managed
- 99.9% uptime
- 40% cost reduction
- 10-minute deployments
- Zero manual changes

---

## Key Takeaways for Interview

✅ **Understand concepts**, not just commands  
✅ **Explain WHY**, not just HOW  
✅ **Use real examples** from your experience  
✅ **Know best practices** and when to apply them  
✅ **Be honest** about what you don't know  
✅ **Show problem-solving** approach  
✅ **Discuss trade-offs** in your decisions  
✅ **Mention security** and compliance  
✅ **Talk about team collaboration**  
✅ **Demonstrate continuous learning**

Good luck with your interview! 🚀
