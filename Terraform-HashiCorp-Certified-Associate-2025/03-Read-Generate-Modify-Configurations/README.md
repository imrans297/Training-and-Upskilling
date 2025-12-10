# 03. Read, Generate, Modify Configurations

## Terraform State

### What is State?

**State** = Terraform's database tracking real infrastructure.

**Purpose**:
- Maps configuration to real resources
- Tracks metadata (dependencies, resource IDs)
- Performance optimization (caching)
- Collaboration (shared state)

**State File**: `terraform.tfstate` (JSON format)

### State File Structure

```json
{
  "version": 4,
  "terraform_version": "1.7.0",
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t2.micro",
            "public_ip": "54.123.45.67"
          }
        }
      ]
    }
  ]
}
```

### State Commands

**View State**:
```bash
terraform show
terraform show -json
```

**List Resources**:
```bash
terraform state list
```

**Show Specific Resource**:
```bash
terraform state show aws_instance.web
```

**Move Resource** (rename):
```bash
terraform state mv aws_instance.web aws_instance.web_server
```

**Remove Resource** (stop managing):
```bash
terraform state rm aws_instance.web
```

**Replace Resource** (force recreation):
```bash
terraform apply -replace="aws_instance.web"
```

---

## Terraform Import

### What is Import?

**Import** = Bring existing infrastructure under Terraform management.

**Use Cases**:
- Manually created resources
- Migrating to Terraform
- Resources created by other tools

### Import Syntax

```bash
terraform import RESOURCE_TYPE.NAME RESOURCE_ID
```

### Import Examples

**Import EC2 Instance**:
```bash
# 1. Create resource block (without attributes)
# main.tf
resource "aws_instance" "existing" {
  # Attributes will be populated after import
}

# 2. Import
terraform import aws_instance.existing i-1234567890abcdef0

# 3. Run terraform plan to see differences
terraform plan

# 4. Update configuration to match
# main.tf
resource "aws_instance" "existing" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  # ... other attributes from plan output
}
```

**Import S3 Bucket**:
```bash
# 1. Create resource block
resource "aws_s3_bucket" "existing" {
}

# 2. Import
terraform import aws_s3_bucket.existing my-existing-bucket

# 3. Update configuration
resource "aws_s3_bucket" "existing" {
  bucket = "my-existing-bucket"
}
```

**Import Security Group**:
```bash
terraform import aws_security_group.existing sg-1234567890abcdef0
```

### Import Block (Terraform 1.5+)

**New way to import**:
```hcl
import {
  to = aws_instance.existing
  id = "i-1234567890abcdef0"
}

resource "aws_instance" "existing" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

Then run:
```bash
terraform plan -generate-config-out=generated.tf
```

---

## Terraform Refresh

### What is Refresh?

**Refresh** = Update state file with real infrastructure.

**Purpose**:
- Detect drift (manual changes)
- Sync state with reality
- Update metadata

### Refresh Commands

**Explicit Refresh**:
```bash
terraform refresh
```

**Automatic Refresh** (during plan/apply):
```bash
terraform plan    # Refreshes automatically
terraform apply   # Refreshes automatically
```

**Skip Refresh**:
```bash
terraform plan -refresh=false
terraform apply -refresh=false
```

### Drift Detection

**Scenario**: Someone manually changed instance type in AWS Console.

```bash
# Detect drift
terraform plan

# Output shows:
# aws_instance.web will be updated in-place
# ~ instance_type = "t2.small" -> "t2.micro"
```

**Options**:
1. **Apply to fix**: `terraform apply` (revert to t2.micro)
2. **Update config**: Change config to t2.small
3. **Ignore**: Use `lifecycle { ignore_changes = [instance_type] }`

---

## Terraform Graph

### What is Graph?

**Graph** = Visual representation of resource dependencies.

**Purpose**:
- Understand resource relationships
- Debug dependency issues
- Documentation

### Generate Graph

```bash
terraform graph > graph.dot
```

### Visualize Graph

**Using Graphviz**:
```bash
# Install graphviz
sudo apt-get install graphviz  # Linux
brew install graphviz          # macOS

# Generate PNG
terraform graph | dot -Tpng > graph.png

# Generate SVG
terraform graph | dot -Tsvg > graph.svg
```

**Online Visualization**:
```bash
terraform graph | pbcopy  # Copy to clipboard (macOS)
# Paste at: https://dreampuf.github.io/GraphvizOnline/
```

### Graph Example

```hcl
resource "aws_security_group" "web_sg" {
  name = "web-sg"
}

resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
}
```

**Graph shows**: `aws_security_group.web_sg` → `aws_instance.web`

---

## Resource Addressing

### What is Resource Addressing?

**Resource Address** = Unique identifier for resources in state.

**Format**: `RESOURCE_TYPE.NAME[INDEX]`

### Addressing Examples

**Single Resource**:
```
aws_instance.web
```

**Resource with Count**:
```
aws_instance.web[0]
aws_instance.web[1]
aws_instance.web[2]
```

**Resource with For_each**:
```
aws_instance.web["web"]
aws_instance.web["app"]
aws_instance.web["db"]
```

**Module Resource**:
```
module.vpc.aws_vpc.main
module.vpc.aws_subnet.public[0]
```

### Using Addresses

**Target Specific Resource**:
```bash
terraform plan -target=aws_instance.web
terraform apply -target=aws_instance.web[0]
terraform destroy -target=aws_s3_bucket.data
```

**Replace Specific Resource**:
```bash
terraform apply -replace="aws_instance.web[1]"
```

---

## Terraform Taint (Deprecated)

### What is Taint?

**Taint** = Mark resource for recreation (deprecated in Terraform 1.5+).

**Use `-replace` instead**:
```bash
# Old way (deprecated)
terraform taint aws_instance.web
terraform apply

# New way
terraform apply -replace="aws_instance.web"
```

---

## Hands-on Lab 3: State Management & Import

### Objective
- Understand state operations
- Import existing resources
- Detect and fix drift
- Visualize dependencies

### Part 1: State Operations

**Step 1: Create Infrastructure**
```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer-${count.index}"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-state-lab-bucket-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}
```

```bash
terraform init
terraform apply -auto-approve
```

**Step 2: List Resources**
```bash
terraform state list
# Output:
# aws_instance.web[0]
# aws_instance.web[1]
# aws_s3_bucket.data
# random_id.suffix
```

**Step 3: Show Resource Details**
```bash
terraform state show aws_instance.web[0]
```

**Step 4: Rename Resource**
```bash
# Rename in state
terraform state mv aws_instance.web[0] aws_instance.primary

# Update configuration
resource "aws_instance" "primary" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "PrimaryServer"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "WebServer"
  }
}

terraform plan  # Should show no changes
```

**Step 5: Remove from State**
```bash
# Stop managing S3 bucket
terraform state rm aws_s3_bucket.data

# Verify
terraform state list  # Bucket not listed

# Note: Bucket still exists in AWS, just not managed by Terraform
```

### Part 2: Import Existing Resources

**Step 1: Create Resource Manually**
```bash
# Create S3 bucket via AWS CLI
aws s3 mb s3://my-manual-bucket-12345
```

**Step 2: Import into Terraform**
```hcl
# Add to main.tf
resource "aws_s3_bucket" "manual" {
  bucket = "my-manual-bucket-12345"
}
```

```bash
# Import
terraform import aws_s3_bucket.manual my-manual-bucket-12345

# Verify
terraform state show aws_s3_bucket.manual

# Plan should show no changes
terraform plan
```

### Part 3: Drift Detection

**Step 1: Manually Change Resource**
```bash
# Change instance type via AWS Console or CLI
aws ec2 modify-instance-attribute \
  --instance-id $(terraform output -raw instance_id) \
  --instance-type t2.small
```

**Step 2: Detect Drift**
```bash
terraform plan
# Shows: instance_type will change from t2.small to t2.micro
```

**Step 3: Fix Drift**
```bash
# Option 1: Revert to configuration
terraform apply

# Option 2: Update configuration
# Change instance_type = "t2.small" in main.tf
terraform plan  # No changes
```

### Part 4: Visualize Dependencies

```bash
# Generate graph
terraform graph > graph.dot

# View as PNG
terraform graph | dot -Tpng > graph.png
open graph.png  # macOS
xdg-open graph.png  # Linux
```

### Cleanup
```bash
terraform destroy -auto-approve
```

---

## Terraform Workspace Preview

**Workspaces** = Multiple state files for same configuration.

**Quick Example**:
```bash
# Create dev workspace
terraform workspace new dev
terraform apply

# Create prod workspace
terraform workspace new prod
terraform apply

# List workspaces
terraform workspace list

# Switch workspace
terraform workspace select dev
```

*Detailed coverage in Section 05*

---

## Key Takeaways

✅ State tracks real infrastructure  
✅ Import brings existing resources under management  
✅ Refresh syncs state with reality  
✅ Graph visualizes dependencies  
✅ Use `-replace` instead of taint  
✅ Resource addressing for targeted operations  
✅ Always backup state before manual edits  
✅ Never edit state file directly

## Next Section

[04. Terraform Provisioners](../04-Terraform-Provisioners/)
