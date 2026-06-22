# INFRASTRUCTURE AS CODE (IaC)

## OVERVIEW
Infrastructure as Code (IaC) automates infrastructure provisioning and management through code, enabling repeatable, versionable, and auditable infrastructure.

## IaC PRINCIPLES

### 1. Idempotency
**Definition**: Running the same code multiple times produces the same result.

**Example (Terraform)**:
```hcl
# BAD: Not idempotent (creates new EC2 instance every apply)
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

**Fixed**: Use consistent naming and resource IDs
```hcl
# GOOD: Idempotent (creates once, updates on changes)
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-server-${var.environment}"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

---

### 2. Declarative vs Imperative

**Declarative**: Describe desired state (Terraform, Kubernetes)
```hcl
# Terraform: Declarative - "I want these resources"
resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs"
  versioning {
    enabled = true
  }
}
```

**Imperative**: Describe how to create resources (Ansible, Bash scripts)
```yaml
# Ansible: Imperative - "Run these commands"
- name: Create S3 bucket
  aws_s3:
    bucket: my-app-logs
    versioning: true
```

**Best Practice**: Prefer declarative for infrastructure state management.

---

## TERRAFORM PATTERNS

### 1. Module Structure

**Directory Structure**:
```
terraform/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── variables.tf
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       └── variables.tf
└── global/
    ├── main.tf
    └── variables.tf
```

**Module Usage**:
```hcl
# environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
}

module "rds" {
  source = "../../modules/rds"
  subnet_ids = module.vpc.private_subnet_ids
}

module "ec2" {
  source = "../../modules/ec2"
  subnet_id = module.vpc.public_subnet_ids[0]
}
```

---

### 2. Variables and Outputs

**variables.tf**:
```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "instance_types" {
  description = "Instance types per environment"
  type = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}
```

**outputs.tf**:
```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "db_endpoint" {
  description     = "Database endpoint"
  value         = aws_db_instance.main.endpoint
  sensitive     = true
}
```

---

### 3. State Management

**Backend Configuration (S3)**:
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-${var.environment}"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**State Locking**: DynamoDB table prevents concurrent state corruption.

---

### 4. Workspaces

**Workspace per Environment**:
```bash
# Create dev workspace
terraform workspace new dev

# Select dev workspace
terraform workspace select dev

# Apply to dev environment
terraform apply

# Switch to prod workspace
terraform workspace select prod

# Apply to prod environment
terraform apply
```

---

## ANSIBLE PATTERNS

### 1. Playbook Structure

**site.yml**:
```yaml
---
- name: Configure application servers
  hosts: webservers
  become: yes

  vars_files:
    - vars/common.yml
    - "vars/{{ ansible_os_family }}.yml"

  roles:
    - common
    - nginx
    - php-fpm
    - application
```

**Role Structure**:
```
roles/
├── common/
│   ├── tasks/
│   │   └── main.yml
│   ├── handlers/
│   │   └── main.yml
│   ├── templates/
│   │   └── config.j2
│   └── vars/
│       └── main.yml
└── php-fpm/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    │   └── php-fpm.conf.j2
    └── vars/
        └── main.yml
```

---

### 2. Idempotent Tasks

```yaml
# BAD: Not idempotent (runs every time)
- name: Copy configuration
  command: cp /source/config.ini /etc/app/config.ini

# GOOD: Idempotent (checks state first)
- name: Copy configuration
  copy:
    src: /source/config.ini
    dest: /etc/app/config.ini
  notify: restart php-fpm
```

---

### 3. Handlers

```yaml
# roles/php-fpm/handlers/main.yml
---
- name: restart php-fpm
  systemd:
    name: php-fpm
    state: restarted
  listen: "php-fpm restart"
```

**Usage in Tasks**:
```yaml
# roles/php-fpm/tasks/main.yml
- name: Copy PHP-FPM configuration
  template:
    src: php-fpm.conf.j2
    dest: /etc/php-fpm.d/custom.conf
  notify: restart php-fpm  # Trigger handler on change
```

---

## CLOUDFORMATION PATTERNS

### 1. Nested Stacks

```yaml
# main.yaml
AWSTemplateFormatVersion: "2010-09-09"
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - staging
      - prod

Resources:
  VPCStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: ./vpc.yaml
      Parameters:
        Environment: !Ref Environment

  RDSStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: ./rds.yaml
      Parameters:
        Environment: !Ref Environment
        VpcId: !GetAtt VPCStack.Outputs.VpcId
        SubnetIds: !GetAtt VPCStack.Outputs.SubnetIds
```

---

### 2. Outputs for Cross-Stack References

```yaml
# vpc.yaml
Outputs:
  VpcId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub "${AWS::StackName}-VpcId"

  SubnetIds:
    Description: Subnet IDs
    Value: !Join [",", !GetAtt Subnets.SubnetIds]
    Export:
      Name: !Sub "${AWS::StackName}-SubnetIds"
```

**Reference in Other Stack**:
```yaml
# app.yaml
Resources:
  LoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Subnets: !Split
        - ","
        - !ImportValue myapp-vpc-SubnetIds
```

---

## BEST PRACTICES

### 1. Version Control
- All infrastructure code in Git
- Review changes via pull requests
- Tag releases
- Track state changes

### 2. Separation of Concerns
```bash
# Network stack
terraform apply -target=module.vpc
terraform apply -target=module.rds

# Compute stack
terraform apply -target=module.ec2
terraform apply -target=module.asg
```

### 3. Environment Parity
```hcl
# variables.tf - same structure for all environments
variable "instance_types" {
  type = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }
}

# Usage in code
resource "aws_instance" "web" {
  instance_type = var.instance_types[var.environment]
}
```

### 4. Sensitive Data Management
```hcl
# BAD: Secrets in code
variable "db_password" {
  default = "secret123"  # Never commit this!
}

# GOOD: Load from environment variable
variable "db_password" {
  type = string
  sensitive = true
}

# Usage
resource "aws_db_instance" "main" {
  password = var.db_password
}

# Pass via environment
export TF_VAR_db_password=$(cat ~/.secrets/db_password)
terraform apply
```

### 5. Drift Detection
```bash
# Detect differences between state and actual resources
terraform plan -refresh-only

# Update state to match reality (use with caution)
terraform refresh
```

---

## SECURITY CONSIDERATIONS

### 1. State Encryption
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "infrastructure/terraform.tfstate"
    encrypt        = true  # Encrypt state at rest
    region         = "us-east-1"
  }
}
```

### 2. IAM Least Privilege
```hcl
# Create minimal IAM role
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # Minimal permissions
  inline_policy {
    name = "minimal_permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "arn:aws:s3:::my-bucket/*"
        }
      ]
    })
  }
}
```

---

## CROSS-REFERENCES
- For CI/CD patterns: @infrastructure/CI-CD.md
- For container patterns: @infrastructure/CONTAINERIZATION.md
- For release strategies: @release/RELEASE-STRATEGIES.md
- For container security: @security/CONTAINER-SECURITY.md
