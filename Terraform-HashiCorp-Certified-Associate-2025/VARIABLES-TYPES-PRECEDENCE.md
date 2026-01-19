# Terraform Variables - Complete Guide

## Variable Types

### Primitive Types

#### 1. string
**What**: Text values  
**Usage**:
```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

# Use
instance_type = var.instance_type
```

**Examples**:
```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami_id" {
  type = string
  # No default - must be provided
}
```

---

#### 2. number
**What**: Numeric values (integers and decimals)  
**Usage**:
```hcl
variable "instance_count" {
  type    = number
  default = 3
}

variable "port" {
  type    = number
  default = 8080
}

variable "cpu_credits" {
  type    = number
  default = 0.5
}
```

---

#### 3. bool
**What**: Boolean values (true/false)  
**Usage**:
```hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "create_vpc" {
  type    = bool
  default = false
}

# Use
resource "aws_instance" "web" {
  monitoring = var.enable_monitoring
}
```

---

### Collection Types

#### 4. list(type)
**What**: Ordered collection of values  
**Usage**:
```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ports" {
  type    = list(number)
  default = [80, 443, 8080]
}

# Access by index
availability_zone = var.availability_zones[0]  # us-east-1a

# Iterate
dynamic "ingress" {
  for_each = var.ports
  content {
    from_port = ingress.value
    to_port   = ingress.value
    protocol  = "tcp"
  }
}
```

**Examples**:
```hcl
variable "subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "instance_counts" {
  type    = list(number)
  default = [1, 2, 3]
}
```

---

#### 5. set(type)
**What**: Unordered collection of unique values  
**Usage**:
```hcl
variable "security_group_ids" {
  type = set(string)
  default = [
    "sg-12345678",
    "sg-87654321"
  ]
}

# Use with for_each
resource "aws_security_group_rule" "example" {
  for_each = var.security_group_ids
  
  security_group_id = each.value
}
```

**Difference from list**:
- No duplicate values
- No guaranteed order
- Better for for_each

---

#### 6. map(type)
**What**: Key-value pairs  
**Usage**:
```hcl
variable "tags" {
  type = map(string)
  default = {
    Environment = "Production"
    Project     = "MyApp"
    ManagedBy   = "Terraform"
  }
}

variable "instance_types" {
  type = map(string)
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  }
}

# Access by key
instance_type = var.instance_types["prod"]  # t2.large

# Use
resource "aws_instance" "web" {
  tags = var.tags
}
```

---

### Structural Types

#### 7. object({...})
**What**: Complex structure with named attributes  
**Usage**:
```hcl
variable "instance_config" {
  type = object({
    ami           = string
    instance_type = string
    monitoring    = bool
    tags          = map(string)
  })
  
  default = {
    ami           = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    monitoring    = true
    tags = {
      Name = "WebServer"
    }
  }
}

# Access
resource "aws_instance" "web" {
  ami           = var.instance_config.ami
  instance_type = var.instance_config.instance_type
  monitoring    = var.instance_config.monitoring
  tags          = var.instance_config.tags
}
```

**Complex example**:
```hcl
variable "vpc_config" {
  type = object({
    cidr_block           = string
    enable_dns_hostnames = bool
    enable_dns_support   = bool
    subnets = list(object({
      cidr_block        = string
      availability_zone = string
      public            = bool
    }))
  })
  
  default = {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    subnets = [
      {
        cidr_block        = "10.0.1.0/24"
        availability_zone = "us-east-1a"
        public            = true
      },
      {
        cidr_block        = "10.0.2.0/24"
        availability_zone = "us-east-1b"
        public            = false
      }
    ]
  }
}
```

---

#### 8. tuple([...])
**What**: Fixed-length collection with specific types  
**Usage**:
```hcl
variable "server_config" {
  type = tuple([string, number, bool])
  default = ["t2.micro", 8080, true]
}

# Access by index
instance_type = var.server_config[0]  # t2.micro
port          = var.server_config[1]  # 8080
monitoring    = var.server_config[2]  # true
```

**Difference from list**:
- Fixed length
- Each element can have different type
- Less common in practice

---

#### 9. any
**What**: Accepts any type (use sparingly)  
**Usage**:
```hcl
variable "custom_config" {
  type    = any
  default = {}
}

# Can be string, number, list, map, etc.
```

⚠️ **Warning**: Avoid using `any` - be specific about types!

---

## Variable Precedence (Highest to Lowest)

### Order of Precedence

**1. Command-line flags** (Highest)
```bash
terraform apply -var="instance_type=t2.large"
terraform apply -var="region=us-west-2"
```

**2. *.auto.tfvars or *.auto.tfvars.json files** (alphabetical order)
```hcl
# production.auto.tfvars
instance_type = "t2.large"
region        = "us-east-1"
```

**3. terraform.tfvars or terraform.tfvars.json**
```hcl
# terraform.tfvars
instance_type = "t2.medium"
region        = "us-east-1"
```

**4. Environment variables** (TF_VAR_name)
```bash
export TF_VAR_instance_type="t2.small"
export TF_VAR_region="us-west-2"
```

**5. Default values in variable declarations** (Lowest)
```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"  # Used if no other value provided
}
```

---

## Precedence Examples

### Example 1: All Methods Combined

**variables.tf**:
```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"  # Priority 5 (lowest)
}
```

**terraform.tfvars**:
```hcl
instance_type = "t2.small"  # Priority 3
```

**Environment variable**:
```bash
export TF_VAR_instance_type="t2.medium"  # Priority 4
```

**Command line**:
```bash
terraform apply -var="instance_type=t2.large"  # Priority 1 (highest)
```

**Result**: `t2.large` (command line wins)

---

### Example 2: Multiple .auto.tfvars Files

**a.auto.tfvars**:
```hcl
instance_type = "t2.small"
region        = "us-east-1"
```

**z.auto.tfvars**:
```hcl
instance_type = "t2.large"  # Loaded after a.auto.tfvars
```

**Result**: `instance_type = "t2.large"` (z.auto.tfvars loaded last)

---

### Example 3: Precedence Test

**Setup**:
```hcl
# variables.tf
variable "environment" {
  type    = string
  default = "default"
}

# terraform.tfvars
environment = "tfvars"

# dev.auto.tfvars
environment = "auto-tfvars"
```

**Test 1** - No flags:
```bash
terraform plan
# Result: environment = "auto-tfvars"
```

**Test 2** - With environment variable:
```bash
export TF_VAR_environment="env-var"
terraform plan
# Result: environment = "auto-tfvars" (auto.tfvars wins over env var)
```

**Test 3** - With command line:
```bash
terraform plan -var="environment=cli"
# Result: environment = "cli" (CLI wins over everything)
```

---

## Understanding .tfvars Files

### What are .tfvars files?

**.tfvars files** = Variable definition files that provide values for variables declared in variables.tf

**Purpose**:
- Separate variable values from configuration
- Environment-specific values
- Keep sensitive data out of main config
- Reusable configurations

---

## Types of .tfvars Files

### 1. terraform.tfvars (Auto-loaded)

**What**: Default variable file, automatically loaded  
**When**: Always loaded if present  
**Precedence**: Medium (after *.auto.tfvars, before environment variables)

**Example**:
```hcl
# terraform.tfvars
instance_type  = "t2.medium"
region         = "us-east-1"
instance_count = 3

tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
}
```

**Usage**:
```bash
terraform apply  # Automatically uses terraform.tfvars
```

**Best for**:
- Default values for project
- Common settings
- Development environment

---

### 2. terraform.tfvars.json (Auto-loaded)

**What**: JSON format of terraform.tfvars  
**When**: Alternative to HCL format

**Example**:
```json
{
  "instance_type": "t2.medium",
  "region": "us-east-1",
  "instance_count": 3,
  "tags": {
    "Environment": "Production",
    "ManagedBy": "Terraform"
  }
}
```

**Best for**:
- Generated configurations
- Integration with JSON-based tools

---

### 3. *.auto.tfvars (Auto-loaded)

**What**: Any file ending in .auto.tfvars, automatically loaded  
**When**: All .auto.tfvars files loaded in alphabetical order  
**Precedence**: High (after CLI, before terraform.tfvars)

**Examples**:
```hcl
# common.auto.tfvars (loaded first)
region = "us-east-1"

tags = {
  ManagedBy = "Terraform"
}

# environment.auto.tfvars (loaded second)
instance_type = "t2.micro"
environment   = "dev"

# z-override.auto.tfvars (loaded last - overrides previous)
instance_type = "t2.large"  # This wins!
```

**Usage**:
```bash
terraform apply  # All .auto.tfvars files loaded automatically
```

**Best for**:
- Multiple configuration layers
- Shared settings across environments
- Override patterns

---

### 4. *.auto.tfvars.json (Auto-loaded)

**What**: JSON format of .auto.tfvars  
**When**: Loaded with other .auto.tfvars files

**Example**:
```json
// config.auto.tfvars.json
{
  "instance_type": "t2.medium",
  "region": "us-east-1"
}
```

---

### 5. Custom .tfvars Files (Manual)

**What**: Any .tfvars file with custom name  
**When**: Must be explicitly specified with -var-file  
**Precedence**: Highest (when used with CLI)

**Examples**:
```hcl
# dev.tfvars
instance_type  = "t2.micro"
instance_count = 1
environment    = "development"

# staging.tfvars
instance_type  = "t2.small"
instance_count = 2
environment    = "staging"

# prod.tfvars
instance_type  = "t2.large"
instance_count = 5
environment    = "production"
```

**Usage**:
```bash
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="staging.tfvars"
terraform apply -var-file="prod.tfvars"

# Multiple files
terraform apply -var-file="common.tfvars" -var-file="prod.tfvars"
```

**Best for**:
- Environment-specific configurations
- Explicit control over which values to use
- CI/CD pipelines

---

## Complete Example: variables.tf vs .tfvars

### variables.tf (Variable Declarations)
```hcl
# variables.tf - Declares variables with types and defaults

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"  # Fallback if not provided
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  # No default - must be provided
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}
```

### terraform.tfvars (Variable Values)
```hcl
# terraform.tfvars - Provides values for variables

region         = "us-west-2"  # Overrides default
instance_type  = "t2.medium"  # Required, no default
instance_count = 3            # Overrides default

tags = {
  Environment = "Production"
  Project     = "MyApp"
  ManagedBy   = "Terraform"
}

enable_monitoring = true  # Overrides default
```

### dev.tfvars (Development Environment)
```hcl
# dev.tfvars - Development-specific values

region         = "us-east-1"
instance_type  = "t2.micro"
instance_count = 1

tags = {
  Environment = "Development"
  Project     = "MyApp"
}

enable_monitoring = false
```

### prod.tfvars (Production Environment)
```hcl
# prod.tfvars - Production-specific values

region         = "us-west-2"
instance_type  = "t2.large"
instance_count = 5

tags = {
  Environment = "Production"
  Project     = "MyApp"
  CostCenter  = "Engineering"
}

enable_monitoring = true
```

---

## .tfvars File Loading Order

### Automatic Loading (in order):
1. `terraform.tfvars`
2. `terraform.tfvars.json`
3. `*.auto.tfvars` (alphabetical order)
4. `*.auto.tfvars.json` (alphabetical order)

### Example with Multiple Files:
```
project/
├── variables.tf
├── terraform.tfvars          # Loaded 1st
├── common.auto.tfvars        # Loaded 2nd
├── environment.auto.tfvars   # Loaded 3rd
├── z-override.auto.tfvars    # Loaded 4th (last wins)
├── dev.tfvars                # NOT auto-loaded
└── prod.tfvars               # NOT auto-loaded
```

**Result**: Later files override earlier files for same variables

---

## Variable Definition Methods

### 1. Command Line (-var)
```bash
terraform apply -var="instance_type=t2.large"
terraform apply -var="region=us-west-2" -var="instance_count=5"
```

**Pros**: Override any value, highest precedence  
**Cons**: Not persistent, must type every time

---

### 2. Variable Files (-var-file)
```bash
terraform apply -var-file="production.tfvars"
terraform apply -var-file="dev.tfvars"

# Multiple files (loaded in order)
terraform apply -var-file="common.tfvars" -var-file="prod.tfvars"
```

**Pros**: Reusable, environment-specific, explicit control  
**Cons**: Must specify file each time

---

### 3. terraform.tfvars (Auto-loaded)
```hcl
# terraform.tfvars
instance_type = "t2.medium"
region        = "us-east-1"
```

**Pros**: Automatically loaded, no CLI flags needed  
**Cons**: Only one file, not environment-specific

---

### 4. *.auto.tfvars (Auto-loaded)
```hcl
# dev.auto.tfvars
instance_type = "t2.micro"

# prod.auto.tfvars
instance_type = "t2.large"
```

**Pros**: Automatically loaded, multiple files, layered config  
**Cons**: All loaded (last one wins), can be confusing

---

### 5. Environment Variables
```bash
export TF_VAR_instance_type="t2.small"
export TF_VAR_region="us-west-2"
export TF_VAR_instance_count=3

terraform apply
```

**Pros**: Good for CI/CD, secrets  
**Cons**: Not visible in code

---

### 6. Default Values
```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
}
```

**Pros**: Fallback value, documented in code  
**Cons**: Lowest precedence

---

## Variable Validation

### Basic Validation
```hcl
variable "instance_type" {
  type = string
  
  validation {
    condition     = contains(["t2.micro", "t2.small", "t2.medium"], var.instance_type)
    error_message = "Instance type must be t2.micro, t2.small, or t2.medium."
  }
}
```

### Multiple Validations
```hcl
variable "port" {
  type = number
  
  validation {
    condition     = var.port > 0 && var.port < 65536
    error_message = "Port must be between 1 and 65535."
  }
  
  validation {
    condition     = var.port != 22
    error_message = "Port 22 is reserved for SSH."
  }
}
```

### Complex Validation
```hcl
variable "cidr_block" {
  type = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "tags" {
  type = map(string)
  
  validation {
    condition     = contains(keys(var.tags), "Environment")
    error_message = "Tags must include 'Environment' key."
  }
}
```

---

## Variable Best Practices

### 1. Always Specify Type
```hcl
# Good
variable "instance_type" {
  type = string
}

# Bad
variable "instance_type" {}
```

### 2. Add Descriptions
```hcl
variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t2.micro"
}
```

### 3. Use Validation
```hcl
variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 4. Sensitive Variables
```hcl
variable "db_password" {
  type      = string
  sensitive = true  # Hidden from output
}
```

### 5. Organize Variables
```hcl
# variables.tf
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Group related variables
variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    cidr_block = string
    name       = string
  })
}
```

---

## Quick Reference

### Variable Precedence (High → Low)
1. `-var` or `-var-file` (CLI)
2. `*.auto.tfvars` (alphabetical)
3. `terraform.tfvars`
4. `TF_VAR_*` (environment variables)
5. Default values

### Variable Types Summary
| Type | Example | Use Case |
|------|---------|----------|
| string | `"t2.micro"` | Text values |
| number | `8080` | Numeric values |
| bool | `true` | Boolean flags |
| list(type) | `["a", "b"]` | Ordered collection |
| set(type) | `["a", "b"]` | Unique values |
| map(type) | `{key = "value"}` | Key-value pairs |
| object({}) | Complex structure | Nested config |
| tuple([]) | `["a", 1, true]` | Fixed-length mixed |
| any | Any type | Avoid if possible |

### Common Patterns
```hcl
# Environment-specific
variable "instance_types" {
  type = map(string)
  default = {
    dev  = "t2.micro"
    prod = "t2.large"
  }
}

# Multi-region
variable "regions" {
  type = list(string)
  default = ["us-east-1", "us-west-2"]
}

# Complex config
variable "app_config" {
  type = object({
    name    = string
    version = string
    ports   = list(number)
  })
}
```

---

## Interview Questions on Variables

**Q: What's the precedence order for Terraform variables?**  
A: CLI flags > *.auto.tfvars > terraform.tfvars > Environment variables > Default values

**Q: Difference between list and set?**  
A: List is ordered and allows duplicates, set is unordered and unique values only

**Q: When to use object vs map?**  
A: Object for fixed structure with different types, map for flexible key-value pairs of same type

**Q: How to pass secrets securely?**  
A: Use environment variables (TF_VAR_*), mark as sensitive, or use external secret managers
