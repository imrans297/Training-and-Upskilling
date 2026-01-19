# Terraform Commands Complete Reference

## Core Workflow Commands

### terraform init

**What**: Initializes a Terraform working directory  
**When**: First command to run in any Terraform project  
**Where**: Root directory of Terraform configuration  

**Purpose**:
- Downloads provider plugins
- Initializes backend
- Creates `.terraform` directory
- Prepares working directory

**Usage**:
```bash
terraform init

# Upgrade providers
terraform init -upgrade

# Reconfigure backend
terraform init -reconfigure

# Migrate state
terraform init -migrate-state

# Skip backend initialization
terraform init -backend=false
```

**Example**:
```bash
cd my-terraform-project
terraform init
# Output: Initializing provider plugins...
```

---

### terraform plan

**What**: Creates execution plan showing what will change  
**When**: Before applying changes to preview  
**Where**: After init, before apply  

**Purpose**:
- Preview changes
- Validate configuration
- Check for errors
- Save plan for later

**Usage**:
```bash
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Target specific resource
terraform plan -target=aws_instance.web

# Destroy plan
terraform plan -destroy

# Refresh only
terraform plan -refresh-only

# With variables
terraform plan -var="instance_type=t2.small"
terraform plan -var-file="prod.tfvars"
```

**Example**:
```bash
terraform plan
# Output:
# + aws_instance.web will be created
# ~ aws_instance.db will be updated
# - aws_instance.old will be destroyed
```

---

### terraform apply

**What**: Applies changes to reach desired state  
**When**: After reviewing plan  
**Where**: Root directory  

**Purpose**:
- Create/update/delete resources
- Execute the plan
- Update state file

**Usage**:
```bash
terraform apply

# Auto-approve (skip confirmation)
terraform apply -auto-approve

# Apply saved plan
terraform apply tfplan

# Target specific resource
terraform apply -target=aws_instance.web

# With variables
terraform apply -var="instance_type=t2.small"

# Replace specific resource
terraform apply -replace="aws_instance.web"
```

**Example**:
```bash
terraform apply
# Type 'yes' to confirm
# Output: Apply complete! Resources: 3 added, 1 changed, 0 destroyed.
```

---

### terraform destroy

**What**: Destroys all managed infrastructure  
**When**: Cleanup, decommissioning  
**Where**: Root directory  

**Purpose**:
- Remove all resources
- Clean up infrastructure
- Cost savings

**Usage**:
```bash
terraform destroy

# Auto-approve
terraform destroy -auto-approve

# Target specific resource
terraform destroy -target=aws_instance.web

# With variables
terraform destroy -var-file="prod.tfvars"
```

**Example**:
```bash
terraform destroy
# Type 'yes' to confirm
# Output: Destroy complete! Resources: 5 destroyed.
```

---

## State Management Commands

### terraform state list

**What**: Lists all resources in state  
**When**: Checking what's managed  
**Where**: Any time after init  

**Purpose**:
- View managed resources
- Verify state contents
- Find resource addresses

**Usage**:
```bash
terraform state list

# Filter by resource type
terraform state list aws_instance

# Filter by module
terraform state list module.vpc
```

**Example**:
```bash
terraform state list
# Output:
# aws_instance.web
# aws_s3_bucket.data
# module.vpc.aws_vpc.main
```

---

### terraform state show

**What**: Shows details of a specific resource  
**When**: Inspecting resource attributes  
**Where**: After apply  

**Purpose**:
- View resource details
- Check attributes
- Debug issues

**Usage**:
```bash
terraform state show aws_instance.web

# JSON output
terraform state show -json aws_instance.web
```

**Example**:
```bash
terraform state show aws_instance.web
# Output:
# resource "aws_instance" "web" {
#   ami           = "ami-0c55b159cbfafe1f0"
#   instance_type = "t2.micro"
#   ...
# }
```

---

### terraform state mv

**What**: Moves/renames resources in state  
**When**: Refactoring, renaming  
**Where**: Before changing resource names  

**Purpose**:
- Rename resources
- Move to modules
- Reorganize state

**Usage**:
```bash
# Rename resource
terraform state mv aws_instance.web aws_instance.web_server

# Move to module
terraform state mv aws_instance.web module.ec2.aws_instance.web

# Move from module
terraform state mv module.ec2.aws_instance.web aws_instance.web
```

**Example**:
```bash
terraform state mv aws_instance.old aws_instance.new
# Output: Successfully moved 1 object(s).
```

---

### terraform state rm

**What**: Removes resources from state  
**When**: Stop managing resource  
**Where**: Before manual deletion  

**Purpose**:
- Stop Terraform management
- Remove without destroying
- Clean up state

**Usage**:
```bash
terraform state rm aws_instance.web

# Remove multiple
terraform state rm aws_instance.web aws_instance.db

# Remove module
terraform state rm module.vpc
```

**Example**:
```bash
terraform state rm aws_instance.web
# Output: Removed aws_instance.web
# Note: Resource still exists in AWS
```

---

### terraform state pull

**What**: Downloads remote state  
**When**: Inspecting remote state  
**Where**: With remote backend  

**Purpose**:
- View remote state
- Backup state
- Debug issues

**Usage**:
```bash
terraform state pull > state.json

# View in terminal
terraform state pull | jq
```

---

### terraform state push

**What**: Uploads state to remote backend  
**When**: Restoring state  
**Where**: Emergency recovery  

**Purpose**:
- Restore state
- Fix state issues
- Manual state update

**Usage**:
```bash
terraform state push terraform.tfstate
```

⚠️ **Warning**: Use with extreme caution!

---

## Import & Refresh Commands

### terraform import

**What**: Imports existing infrastructure  
**When**: Bringing existing resources under management  
**Where**: After creating resource block  

**Purpose**:
- Import existing resources
- Migrate to Terraform
- Adopt manual resources

**Usage**:
```bash
# Import EC2 instance
terraform import aws_instance.web i-1234567890abcdef0

# Import S3 bucket
terraform import aws_s3_bucket.data my-bucket-name

# Import with module
terraform import module.vpc.aws_vpc.main vpc-12345678
```

**Example**:
```bash
# 1. Create resource block
resource "aws_instance" "web" {
  # Configuration will be filled after import
}

# 2. Import
terraform import aws_instance.web i-1234567890abcdef0

# 3. Run plan to see differences
terraform plan
```

---

### terraform refresh

**What**: Updates state with real infrastructure  
**When**: Detecting drift  
**Where**: After manual changes  

**Purpose**:
- Sync state with reality
- Detect drift
- Update metadata

**Usage**:
```bash
terraform refresh

# With variables
terraform refresh -var-file="prod.tfvars"
```

**Note**: Deprecated in favor of `terraform apply -refresh-only`

---

## Validation & Formatting Commands

### terraform validate

**What**: Validates configuration syntax  
**When**: Before plan/apply  
**Where**: After writing configuration  

**Purpose**:
- Check syntax errors
- Validate references
- Ensure consistency

**Usage**:
```bash
terraform validate

# JSON output
terraform validate -json
```

**Example**:
```bash
terraform validate
# Output: Success! The configuration is valid.
```

---

### terraform fmt

**What**: Formats configuration files  
**When**: Before committing code  
**Where**: Any time  

**Purpose**:
- Consistent formatting
- Code readability
- Team standards

**Usage**:
```bash
# Format current directory
terraform fmt

# Format recursively
terraform fmt -recursive

# Check without modifying
terraform fmt -check

# Show diff
terraform fmt -diff
```

**Example**:
```bash
terraform fmt -recursive
# Output: main.tf
#         variables.tf
```

---

## Output Commands

### terraform output

**What**: Displays output values  
**When**: After apply  
**Where**: Any time after resources created  

**Purpose**:
- View output values
- Get resource IDs
- Use in scripts

**Usage**:
```bash
# Show all outputs
terraform output

# Specific output
terraform output instance_ip

# Raw value (no quotes)
terraform output -raw instance_ip

# JSON format
terraform output -json
```

**Example**:
```bash
terraform output
# Output:
# instance_id = "i-1234567890abcdef0"
# instance_ip = "54.123.45.67"

terraform output -raw instance_ip
# Output: 54.123.45.67
```

---

## Workspace Commands

### terraform workspace list

**What**: Lists all workspaces  
**When**: Managing environments  
**Where**: Any time  

**Purpose**:
- View available workspaces
- Check current workspace
- Manage environments

**Usage**:
```bash
terraform workspace list
# Output:
#   default
# * dev
#   prod
```

---

### terraform workspace new

**What**: Creates new workspace  
**When**: Setting up new environment  
**Where**: Before deploying to new env  

**Purpose**:
- Create environment
- Isolate state
- Separate deployments

**Usage**:
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

---

### terraform workspace select

**What**: Switches to workspace  
**When**: Changing environments  
**Where**: Before plan/apply  

**Purpose**:
- Switch environment
- Change state file
- Deploy to different env

**Usage**:
```bash
terraform workspace select dev
terraform workspace select prod
```

---

### terraform workspace show

**What**: Shows current workspace  
**When**: Verifying environment  
**Where**: Any time  

**Usage**:
```bash
terraform workspace show
# Output: dev
```

---

### terraform workspace delete

**What**: Deletes workspace  
**When**: Cleanup  
**Where**: After destroying resources  

**Purpose**:
- Remove environment
- Clean up workspaces
- Delete state

**Usage**:
```bash
terraform workspace delete dev

# Force delete (with resources)
terraform workspace delete -force dev
```

---

## Advanced Commands

### terraform graph

**What**: Generates dependency graph  
**When**: Visualizing dependencies  
**Where**: Debugging, documentation  

**Purpose**:
- Visualize resources
- Understand dependencies
- Debug issues

**Usage**:
```bash
# Generate DOT format
terraform graph > graph.dot

# Generate PNG
terraform graph | dot -Tpng > graph.png

# Generate SVG
terraform graph | dot -Tsvg > graph.svg
```

---

### terraform show

**What**: Shows current state or plan  
**When**: Inspecting state/plan  
**Where**: After apply or plan  

**Purpose**:
- View state contents
- Inspect plan details
- Debug issues

**Usage**:
```bash
# Show current state
terraform show

# Show saved plan
terraform show tfplan

# JSON output
terraform show -json
terraform show -json tfplan
```

---

### terraform providers

**What**: Shows provider requirements  
**When**: Checking providers  
**Where**: Any time  

**Purpose**:
- List providers
- Check versions
- Verify requirements

**Usage**:
```bash
# List providers
terraform providers

# Show provider tree
terraform providers schema

# Lock providers
terraform providers lock
```

---

### terraform version

**What**: Shows Terraform version  
**When**: Checking version  
**Where**: Any time  

**Purpose**:
- Verify version
- Check compatibility
- Troubleshooting

**Usage**:
```bash
terraform version
# Output: Terraform v1.7.0

# JSON output
terraform version -json
```

---

### terraform force-unlock

**What**: Manually unlocks state  
**When**: Lock is stuck  
**Where**: Emergency only  

**Purpose**:
- Remove stuck lock
- Recover from errors
- Emergency access

**Usage**:
```bash
terraform force-unlock LOCK_ID
```

⚠️ **Warning**: Only use if no other process is running!

---

### terraform console

**What**: Interactive console for expressions  
**When**: Testing expressions  
**Where**: Development, debugging  

**Purpose**:
- Test expressions
- Debug functions
- Explore data

**Usage**:
```bash
terraform console

# In console:
> var.instance_type
"t2.micro"

> aws_instance.web.public_ip
"54.123.45.67"

> length(var.availability_zones)
2
```

---

### terraform login

**What**: Logs in to Terraform Cloud  
**When**: Using Terraform Cloud  
**Where**: First time setup  

**Purpose**:
- Authenticate
- Access remote state
- Use Terraform Cloud

**Usage**:
```bash
terraform login
# Opens browser for authentication
```

---

### terraform logout

**What**: Logs out from Terraform Cloud  
**When**: Switching accounts  
**Where**: Any time  

**Usage**:
```bash
terraform logout
```

---

## Deprecated Commands

### terraform taint

**What**: Marks resource for recreation  
**Status**: Deprecated (use -replace)  

**Replacement**:
```bash
# Old way
terraform taint aws_instance.web
terraform apply

# New way
terraform apply -replace="aws_instance.web"
```

---

### terraform untaint

**What**: Removes taint mark  
**Status**: Deprecated  

**Replacement**: Not needed with -replace

---

## Command Flags Reference

### Common Flags

**-auto-approve**: Skip confirmation
```bash
terraform apply -auto-approve
terraform destroy -auto-approve
```

**-var**: Set variable value
```bash
terraform plan -var="instance_type=t2.small"
terraform apply -var="region=us-west-2"
```

**-var-file**: Load variables from file
```bash
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="staging.tfvars"
```

**-target**: Target specific resource
```bash
terraform plan -target=aws_instance.web
terraform apply -target=module.vpc
terraform destroy -target=aws_s3_bucket.data
```

**-out**: Save plan to file
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

**-json**: JSON output
```bash
terraform show -json
terraform output -json
terraform validate -json
```

**-refresh=false**: Skip refresh
```bash
terraform plan -refresh=false
terraform apply -refresh=false
```

**-lock=false**: Disable state locking
```bash
terraform apply -lock=false
```

⚠️ **Warning**: Only use in emergencies!

---

## Environment Variables

**TF_LOG**: Enable logging
```bash
export TF_LOG=DEBUG
export TF_LOG=TRACE
export TF_LOG=INFO
```

**TF_LOG_PATH**: Log file path
```bash
export TF_LOG_PATH=terraform.log
```

**TF_VAR_**: Set variable
```bash
export TF_VAR_instance_type=t2.micro
export TF_VAR_region=us-east-1
```

**TF_CLI_ARGS**: Default CLI arguments
```bash
export TF_CLI_ARGS="-no-color"
export TF_CLI_ARGS_plan="-refresh=false"
```

---

## Quick Reference

### Daily Workflow
```bash
terraform init          # Initialize
terraform validate      # Validate syntax
terraform fmt          # Format code
terraform plan         # Preview changes
terraform apply        # Apply changes
terraform output       # View outputs
```

### State Management
```bash
terraform state list                    # List resources
terraform state show aws_instance.web   # Show resource
terraform state mv OLD NEW              # Rename
terraform state rm aws_instance.web     # Remove
```

### Workspace Management
```bash
terraform workspace list        # List workspaces
terraform workspace new dev     # Create workspace
terraform workspace select dev  # Switch workspace
terraform workspace show        # Current workspace
```

### Troubleshooting
```bash
terraform validate              # Check syntax
terraform plan                  # Preview changes
terraform refresh              # Sync state
terraform show                 # View state
terraform graph | dot -Tpng > graph.png  # Visualize
```

---

## Best Practices

✅ **Always run** `terraform plan` before `apply`  
✅ **Use** `-auto-approve` only in automation  
✅ **Save plans** for production deployments  
✅ **Format code** before committing  
✅ **Validate** before pushing  
✅ **Use workspaces** for environments  
✅ **Enable logging** for troubleshooting  
✅ **Target resources** carefully  
✅ **Backup state** before major changes  
✅ **Use version control** for configurations
