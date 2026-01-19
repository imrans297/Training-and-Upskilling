# 04. Terraform Provisioners

## What are Provisioners?

**Provisioners** = Execute scripts on local machine or remote resources after creation.

**Purpose**:
- Bootstrap instances
- Run configuration management
- Execute initialization scripts
- Copy files to instances

**⚠️ Important**: Provisioners are a **last resort**. Use alternatives when possible:
- User data for cloud-init
- Configuration management tools (Ansible, Chef, Puppet)
- Custom AMIs/images
- Container orchestration

---

## Types of Provisioners

### 1. local-exec Provisioner

**What**: Runs commands on the machine running Terraform.

**When to use**:
- Trigger local scripts
- Call external APIs
- Update local files
- Run Ansible playbooks

**Syntax**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ip_address.txt"
  }
}
```

**Examples**:

**Save instance IP**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    command = "echo Instance ${self.id} created with IP ${self.public_ip}"
  }
}
```

**Run Ansible playbook**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' playbook.yml"
  }
}
```

**Working directory**:
```hcl
provisioner "local-exec" {
  command     = "./setup.sh"
  working_dir = "/tmp"
}
```

**Environment variables**:
```hcl
provisioner "local-exec" {
  command = "python script.py"
  
  environment = {
    INSTANCE_ID = self.id
    INSTANCE_IP = self.public_ip
  }
}
```

---

### 2. remote-exec Provisioner

**What**: Runs commands on the remote resource via SSH or WinRM.

**When to use**:
- Install software
- Configure services
- Run initialization scripts
- Bootstrap configuration management

**Requirements**:
- SSH/WinRM access
- Connection block configuration

**Syntax**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"
  
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
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

**Inline commands**:
```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y nginx",
    "sudo systemctl enable nginx",
    "sudo systemctl start nginx"
  ]
}
```

**Script file**:
```hcl
provisioner "remote-exec" {
  script = "scripts/install.sh"
}
```

**Multiple scripts**:
```hcl
provisioner "remote-exec" {
  scripts = [
    "scripts/install.sh",
    "scripts/configure.sh",
    "scripts/start.sh"
  ]
}
```

**Connection types**:

**SSH (Linux)**:
```hcl
connection {
  type        = "ssh"
  user        = "ubuntu"
  private_key = file("~/.ssh/id_rsa")
  host        = self.public_ip
  timeout     = "5m"
}
```

**WinRM (Windows)**:
```hcl
connection {
  type     = "winrm"
  user     = "Administrator"
  password = var.admin_password
  host     = self.public_ip
  timeout  = "10m"
}
```

---

### 3. file Provisioner

**What**: Copies files/directories from local to remote machine.

**When to use**:
- Upload configuration files
- Copy scripts
- Transfer certificates
- Deploy application files

**Syntax**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "my-key"
  
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/my-key.pem")
    host        = self.public_ip
  }
  
  provisioner "file" {
    source      = "app.conf"
    destination = "/tmp/app.conf"
  }
}
```

**Copy single file**:
```hcl
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/tmp/nginx.conf"
}
```

**Copy directory**:
```hcl
provisioner "file" {
  source      = "configs/"
  destination = "/tmp/configs"
}
```

**Upload content directly**:
```hcl
provisioner "file" {
  content     = "Hello from Terraform!"
  destination = "/tmp/hello.txt"
}
```

**Template content**:
```hcl
provisioner "file" {
  content = templatefile("config.tpl", {
    server_name = self.public_ip
    port        = 8080
  })
  destination = "/tmp/config.conf"
}
```

---

## null_resource

**What**: Resource that does nothing but can run provisioners.

**When to use**:
- Run provisioners without creating resources
- Trigger actions based on changes
- Execute scripts independently

**Syntax**:
```hcl
resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "echo Hello World"
  }
}
```

**With triggers** (re-run when values change):
```hcl
resource "null_resource" "cluster" {
  triggers = {
    cluster_instance_ids = join(",", aws_instance.cluster[*].id)
  }
  
  provisioner "local-exec" {
    command = "echo Cluster updated"
  }
}
```

**Depends on other resources**:
```hcl
resource "null_resource" "post_install" {
  depends_on = [aws_instance.web]
  
  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini site.yml"
  }
}
```

---

## Provisioner Behavior

### Creation-time Provisioners

**Default**: Run during resource creation.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    command = "echo Created at $(date)"
  }
}
```

### Destroy-time Provisioners

**Run during resource destruction**:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  provisioner "local-exec" {
    when    = destroy
    command = "echo Destroying instance ${self.id}"
  }
}
```

### Failure Behavior

**continue** (default): Continue even if provisioner fails.
**fail**: Stop and mark resource as tainted.

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y nginx"
  ]
  
  on_failure = continue  # or fail
}
```

---

## When to Use Provisioners

### ✅ Good Use Cases

1. **Bootstrap configuration management**:
```hcl
provisioner "remote-exec" {
  inline = [
    "curl -L https://omnitruck.chef.io/install.sh | sudo bash",
    "sudo chef-client"
  ]
}
```

2. **Trigger external systems**:
```hcl
provisioner "local-exec" {
  command = "curl -X POST https://api.example.com/notify"
}
```

3. **One-time initialization**:
```hcl
provisioner "remote-exec" {
  inline = ["sudo /opt/app/initialize.sh"]
}
```

### ❌ Avoid Provisioners For

1. **Configuration management** → Use Ansible/Chef/Puppet
2. **Application deployment** → Use CI/CD pipelines
3. **Complex orchestration** → Use dedicated tools
4. **Ongoing management** → Use configuration management

---

## Alternatives to Provisioners

### 1. User Data (Cloud-Init)

**Better approach**:
```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF
}
```

### 2. Custom AMI/Image

**Best approach**:
```bash
# Build custom AMI with Packer
packer build web-server.json
```

```hcl
# Use custom AMI
resource "aws_instance" "web" {
  ami           = "ami-custom-web-server"
  instance_type = "t2.micro"
}
```

### 3. Configuration Management

**Ansible**:
```hcl
resource "null_resource" "configure" {
  depends_on = [aws_instance.web]
  
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.web.public_ip}, playbook.yml"
  }
}
```

---

## Hands-on Lab 4: Provisioners in Action

### Objective
Deploy web server using different provisioner types.

### Project Structure
```
lab4-provisioners/
├── main.tf
├── variables.tf
├── scripts/
│   ├── install.sh
│   └── configure.sh
└── files/
    └── index.html
```

### main.tf
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Key Pair (create manually or use existing)
resource "aws_key_pair" "deployer" {
  key_name   = "terraform-lab4"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "lab4-web-sg"
  description = "Allow HTTP and SSH"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with Provisioners
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  
  tags = {
    Name = "Lab4-WebServer"
  }
  
  # Connection for remote provisioners
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
  
  # 1. local-exec: Log instance creation
  provisioner "local-exec" {
    command = "echo Instance ${self.id} created at $(date) >> creation.log"
  }
  
  # 2. file: Upload installation script
  provisioner "file" {
    source      = "scripts/install.sh"
    destination = "/tmp/install.sh"
  }
  
  # 3. file: Upload custom index.html
  provisioner "file" {
    source      = "files/index.html"
    destination = "/tmp/index.html"
  }
  
  # 4. remote-exec: Run installation
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install.sh",
      "sudo /tmp/install.sh",
      "sudo mv /tmp/index.html /var/www/html/index.html"
    ]
  }
  
  # 5. local-exec: Test website
  provisioner "local-exec" {
    command = "sleep 30 && curl -s http://${self.public_ip} > test_output.html"
  }
  
  # 6. Destroy-time provisioner
  provisioner "local-exec" {
    when    = destroy
    command = "echo Instance ${self.id} destroyed at $(date) >> destruction.log"
  }
}

# null_resource: Post-deployment tasks
resource "null_resource" "post_deploy" {
  depends_on = [aws_instance.web]
  
  triggers = {
    instance_id = aws_instance.web.id
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Deployment Summary" > deployment_summary.txt
      echo "Instance ID: ${aws_instance.web.id}" >> deployment_summary.txt
      echo "Public IP: ${aws_instance.web.public_ip}" >> deployment_summary.txt
      echo "URL: http://${aws_instance.web.public_ip}" >> deployment_summary.txt
    EOT
  }
}
```

### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### scripts/install.sh
```bash
#!/bin/bash
set -e

# Update system
yum update -y

# Install Apache
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Configure firewall
systemctl start firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

echo "Installation completed successfully"
```

### files/index.html
```html
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Provisioners Lab</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        h1 { font-size: 3em; }
        p { font-size: 1.5em; }
    </style>
</head>
<body>
    <h1>🚀 Terraform Provisioners Lab</h1>
    <p>This server was configured using Terraform provisioners!</p>
    <p>Instance deployed successfully ✅</p>
</body>
</html>
```

### Deployment Steps

```bash
# 1. Create project directory
mkdir -p lab4-provisioners/{scripts,files}
cd lab4-provisioners

# 2. Create all files (main.tf, variables.tf, scripts/install.sh, files/index.html)

# 3. Make script executable
chmod +x scripts/install.sh

# 4. Generate SSH key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 5. Initialize Terraform
terraform init

# 6. Plan
terraform plan

# 7. Apply
terraform apply -auto-approve

# 8. Wait for provisioners to complete (watch output)

# 9. Check logs
cat creation.log
cat deployment_summary.txt

# 10. Test website
INSTANCE_IP=$(terraform output -raw instance_public_ip)
curl http://$INSTANCE_IP

# Or open in browser
open http://$INSTANCE_IP  # macOS
xdg-open http://$INSTANCE_IP  # Linux

# 11. Destroy
terraform destroy -auto-approve

# 12. Check destruction log
cat destruction.log
```

---

## Best Practices

✅ **Use provisioners sparingly** - Last resort only  
✅ **Prefer user data** for cloud-init  
✅ **Use custom images** (AMI/Packer) when possible  
✅ **Handle failures** with on_failure  
✅ **Use null_resource** for independent tasks  
✅ **Test scripts** before using in provisioners  
✅ **Add timeouts** for connection blocks  
✅ **Log provisioner output** for debugging  

❌ **Don't use for**:
- Ongoing configuration management
- Complex orchestration
- Application deployment
- State management

---

## Key Takeaways

✅ Provisioners execute scripts after resource creation  
✅ Three types: local-exec, remote-exec, file  
✅ null_resource runs provisioners without creating resources  
✅ Use destroy-time provisioners for cleanup  
✅ Prefer alternatives (user data, custom AMIs, config management)  
✅ Provisioners are last resort, not first choice  
✅ Always handle failures appropriately

## Next Section

[05. Modules and Workspaces](../05-Modules-and-Workspaces/)
