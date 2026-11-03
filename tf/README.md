# Terraform AWS Commands Guide: Basic to Advanced

A comprehensive, step-by-step guide to Terraform commands for provisioning and operating AWS infrastructure. Examples use the `tf/` directory in this repository, which is configured for LocalStack; replace LocalStack settings with normal AWS authentication for a real AWS account.

> **Cost and safety notice:** `terraform apply` can create billable AWS resources and `terraform destroy` removes managed resources. Always inspect a saved plan before applying it, use a non-production account while learning, and never commit credentials or state files.

---

## Table of Contents

1. [Prerequisites & Setup](#prerequisites--setup)
2. [Basic Commands](#basic-commands)
3. [Configuration & Variables](#configuration--variables)
4. [State Management](#state-management)
5. [Planning & Applying Changes](#planning--applying-changes)
6. [AWS Resource Operations](#aws-resource-operations)
7. [Importing Existing AWS Resources](#importing-existing-aws-resources)
8. [Modules & Reusable Infrastructure](#modules--reusable-infrastructure)
9. [Remote State & Team Workflows](#remote-state--team-workflows)
10. [Workspaces & Environments](#workspaces--environments)
11. [Security & IAM](#security--iam)
12. [Debugging & Validation](#debugging--validation)
13. [Advanced Operations](#advanced-operations)
14. [Quick Reference Commands](#quick-reference-commands)
15. [Common AWS Scenarios](#common-aws-scenarios)

---

## Prerequisites & Setup

Before running commands, install:

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.x
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) v2
- An AWS account and IAM credentials, or Docker and LocalStack for the repository configuration

### Step 1: Verify Terraform, AWS CLI, and AWS identity

```bash
# Check installed versions
terraform version
aws --version

# Move to this Terraform root module
cd tf

# Confirm the AWS identity used by the CLI (real AWS only)
aws sts get-caller-identity

# List available AWS profiles
aws configure list-profiles

# Use a named profile for the current shell
export AWS_PROFILE=development
export AWS_REGION=eu-west-2
```

For this repository's LocalStack configuration, start LocalStack before applying:

```bash
# Start LocalStack if the project supplies a Docker Compose service
docker compose up -d

# Check LocalStack health
curl http://localhost:4566/_localstack/health
```

Do not put `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` in `.tf` files. Prefer AWS IAM Identity Center, an IAM role, or a named AWS CLI profile.

---

## Basic Commands

### Step 2: Initialize a Terraform working directory

```bash
# Download the providers and initialize the current directory
terraform init

# Reconfigure backend settings after editing the backend block
terraform init -reconfigure

# Upgrade providers within configured version constraints
terraform init -upgrade

# Display providers required by this configuration
terraform providers

# Display providers recorded in state
terraform providers schema -json | jq '.provider_schemas | keys'
```

### Step 3: Format and validate configuration

```bash
# Format all .tf files recursively
terraform fmt -recursive

# Show files that need formatting; useful in CI
terraform fmt -check -recursive

# Validate configuration syntax and internal references
terraform validate

# Inspect the configuration as JSON
terraform show -json
```

### Step 4: Inspect a configuration without changing AWS

```bash
# Build and display an execution plan
terraform plan

# Include output values in a detailed plan
terraform plan -out=tfplan

# Review a saved plan in human-readable form
terraform show tfplan

# Review a saved plan as JSON for automation
terraform show -json tfplan | jq '.'

# List resources Terraform currently manages
terraform state list

# Show a single managed resource
terraform state show aws_s3_bucket.usweb
```

---

## Configuration & Variables

### Step 5: Set input variables safely

Terraform loads values in this order: defaults, `terraform.tfvars`, `*.auto.tfvars`, environment variables, then `-var` / `-var-file` flags. Later sources take precedence.

```bash
# Pass a one-off value (avoid this for secrets because shell history may retain it)
terraform plan -var='region=eu-west-2'

# Load environment-specific variables
terraform plan -var-file=environments/dev.tfvars

# Set a variable through the environment
export TF_VAR_region=eu-west-2
terraform plan

# Prompt for any variables without values
terraform plan -input=true

# Fail rather than prompt; recommended in CI
terraform plan -input=false
```

Example `variables.tf`:

```hcl
variable "region" {
  description = "AWS region for infrastructure."
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}
```

### Step 6: Use outputs and the Terraform console

```bash
# List output names
terraform output

# Read one output as a plain string for scripts
terraform output -raw s3_bucket_id

# Read complex output as JSON
terraform output -json public_subnet_ids

# Start an interactive expression console
terraform console

# Evaluate an expression non-interactively
terraform console <<< 'cidrsubnet("10.0.0.0/16", 8, 1)'
```

Never mark a value as non-sensitive merely to make scripting easier. Use `sensitive = true` for credentials, tokens, and private keys; retrieve them through an approved secret-management flow.

---

## State Management

### Step 7: Inspect and back up local state

```bash
# Show the current state in a readable format
terraform show

# List all resource addresses in state
terraform state list

# Inspect one resource, including attributes Terraform tracks
terraform state show aws_vpc.us_vpc

# Pull state from the configured backend to stdout
terraform state pull > terraform-state-backup.json

# Display state serial and lineage metadata
terraform state pull | jq '{serial, lineage}'
```

`terraform.tfstate`, state backups, plans, and `*.tfvars` containing secrets should be ignored by Git. State can contain sensitive resource attributes even when outputs are marked sensitive.

### Step 8: Move, remove, and replace state addresses

```bash
# Preview a state move before carrying it out
terraform state mv -dry-run aws_s3_bucket.usweb aws_s3_bucket.website

# Rename a state address after renaming the resource block
terraform state mv aws_s3_bucket.usweb aws_s3_bucket.website

# Stop managing a resource without deleting it from AWS
terraform state rm aws_s3_bucket.website

# Force recreation of one resource in the next plan
terraform plan -replace=aws_s3_bucket.website
```

Run `terraform state` commands carefully: they change Terraform's record of ownership. Take a backup and run `terraform plan` immediately afterward.

---

## Planning & Applying Changes

### Step 9: Create and apply a reviewed plan

```bash
# Create a binary plan artifact
terraform plan -out=tfplan

# Review the exact artifact that will be applied
terraform show tfplan

# Apply only the reviewed plan; Terraform will not prompt
terraform apply tfplan

# Create resources interactively (useful only for experimentation)
terraform apply

# Refresh state and report drift without proposing configuration changes
terraform plan -refresh-only

# Update state to match remote objects after reviewing refresh-only output
terraform apply -refresh-only
```

Avoid `-auto-approve` for production changes. In CI, generate a plan artifact, require review, and apply that exact artifact.

### Step 10: Destroy infrastructure deliberately

```bash
# Preview all managed resources that would be destroyed
terraform plan -destroy

# Destroy after review (prompts for confirmation)
terraform destroy

# Destroy a sandbox without an interactive confirmation
terraform destroy -auto-approve

# Destroy only one address: use only when dependencies are understood
terraform destroy -target=aws_s3_bucket.usweb
```

`-target` is an exceptional recovery or troubleshooting tool, not a normal deployment workflow. A targeted action can leave dependent infrastructure inconsistent.

---

## AWS Resource Operations

### Step 11: Query AWS before and after Terraform changes

```bash
# List S3 buckets in the AWS account
aws s3api list-buckets --query 'Buckets[].Name' --output table

# Inspect the VPC created by this configuration
aws ec2 describe-vpcs --filters 'Name=tag:Name,Values=us-vpc' --output table

# List subnets in a VPC
aws ec2 describe-subnets --filters 'Name=vpc-id,Values=<vpc-id>' --output table

# Inspect route tables
aws ec2 describe-route-tables --filters 'Name=vpc-id,Values=<vpc-id>' --output table

# Inspect an EKS cluster
aws eks describe-cluster --name us-vpc-eks --region eu-west-2

# List EKS node groups
aws eks list-nodegroups --cluster-name us-vpc-eks --region eu-west-2
```

When using LocalStack, add the endpoint and test credentials to AWS CLI calls:

```bash
aws --endpoint-url=http://localhost:4566 s3api list-buckets
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs
aws --endpoint-url=http://localhost:4566 eks list-clusters
```

### Step 12: Use data sources for existing AWS infrastructure

Data sources read infrastructure but do not create it.

```hcl
# Read the current AWS account ID and region.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Find an existing VPC by tag.
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["shared-vpc"]
  }
}
```

```bash
# View data sources that are now recorded in state
terraform state list | grep '^data\.'

# Re-read data sources and identify dependent changes
terraform plan
```

---

## Importing Existing AWS Resources

### Step 13: Bring an existing resource under Terraform management

First write the matching resource configuration. Import only makes Terraform track the remote object; it does not create its configuration.

```bash
# Import an existing S3 bucket by name
terraform import aws_s3_bucket.website my-existing-bucket

# Import a VPC by its vpc-* ID
terraform import aws_vpc.us_vpc vpc-0123456789abcdef0

# Import a subnet by its subnet-* ID
terraform import 'aws_subnet.public["public_a"]' subnet-0123456789abcdef0

# Confirm differences between configuration and imported resource
terraform plan
```

For repeatable imports, use an `import` block:

```hcl
import {
  to = aws_s3_bucket.website
  id = "my-existing-bucket"
}
```

```bash
# Generate a candidate configuration for an import (review before using)
terraform plan -generate-config-out=generated.tf
```

---

## Modules & Reusable Infrastructure

### Step 14: Discover and consume modules

```bash
# Search the public Terraform Registry from a browser or registry UI
# https://registry.terraform.io/browse/modules?provider=aws

# Initialize after adding or updating a module block
terraform init -upgrade

# See the module resource addresses in the plan/state
terraform state list | grep '^module\.'
```

Example AWS VPC module:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "example"
  cidr = "10.0.0.0/16"

  # London availability zones. Check availability before deployment because
  # AZ names can map to different physical zones across AWS accounts.
  azs            = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
```

Pin module and provider versions, review a module's source before use, and expose only the outputs that consumers need.

---

## Remote State & Team Workflows

### Step 15: Configure an S3 backend with DynamoDB state locking

Create the state bucket and locking table through a separately controlled bootstrap process. Enable bucket versioning, encryption, public-access blocking, and restrictive IAM policies.

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "networking/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
```

```bash
# Migrate local state to the newly configured backend
terraform init -migrate-state

# Reconfigure a previously initialized backend
terraform init -reconfigure

# Inspect lock-table records only when troubleshooting a lock
aws dynamodb scan --table-name terraform-state-locks
```

Do not manually delete a state lock unless you have confirmed no Terraform run is active. If a run crashed, use the lock ID printed by Terraform:

```bash
# Dangerous if another apply is active: unlock only a verified stale lock
terraform force-unlock <lock-id>
```

---

## Workspaces & Environments

### Step 16: Create and select CLI workspaces

```bash
# Show current and available workspaces
terraform workspace list

# Create an isolated state workspace
terraform workspace new development

# Switch workspaces
terraform workspace select development

# Print the selected workspace name
terraform workspace show

# Delete an empty, non-current workspace
terraform workspace delete development
```

Use separate AWS accounts and separate backend keys for strong production isolation. Workspaces are useful for low-risk environment separation, but they are not a replacement for account boundaries or access controls.

---

## Security & IAM

### Step 17: Authenticate without embedding credentials

```bash
# Configure and authenticate with AWS IAM Identity Center
aws configure sso
aws sso login --profile development

# Use that profile for Terraform
export AWS_PROFILE=development
terraform plan

# Assume a role with the AWS CLI, then export only short-lived values as needed
aws sts assume-role --role-arn arn:aws:iam::<account-id>:role/TerraformDeployRole \\
  --role-session-name terraform-cli
```

Example provider configuration that relies on standard AWS credential resolution:

```hcl
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
```

### Step 18: Review AWS IAM permissions

```bash
# Confirm the active identity
aws sts get-caller-identity

# List IAM roles matching a name prefix
aws iam list-roles --query 'Roles[?starts_with(RoleName, `Terraform`)].RoleName' --output table

# Retrieve the IAM policy attached to an EKS cluster role
aws iam list-attached-role-policies --role-name us-vpc-eks-cluster

# Use IAM Access Analyzer policy validation where available
aws accessanalyzer validate-policy --policy-type IDENTITY_POLICY --policy-document file://policy.json
```

Apply least privilege. Keep Terraform deployment roles distinct from application runtime roles, and use AWS Secrets Manager or SSM Parameter Store for secrets rather than Terraform variables whenever possible.

---

## Debugging & Validation

### Step 19: Diagnose provider and API failures

```bash
# Enable Terraform's detailed logs; remove when finished
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan
unset TF_LOG TF_LOG_PATH

# Show provider constraints and schema information
terraform providers
terraform providers schema -json > provider-schema.json

# Validate all files after a refactor
terraform fmt -check -recursive
terraform validate

# Refresh state only and inspect drift
terraform plan -refresh-only
```

Logs can include request details or sensitive values. Treat them as sensitive artifacts and do not commit or upload them indiscriminately.

### Step 20: Test Terraform configuration

```bash
# Run native Terraform tests in .tftest.hcl files
terraform test

# Run tests with detailed execution output
terraform test -verbose

# List providers locked for reproducible CI runs
terraform providers lock
```

Example `s3.tftest.hcl`:

```hcl
run "bucket_name_is_available" {
  command = plan

  assert {
    condition     = aws_s3_bucket.usweb.bucket == "usweb"
    error_message = "The expected bucket name changed."
  }
}
```

---

## Advanced Operations

### Step 21: Manage provider versions and dependency locks

```bash
# Review the dependency lock file
sed -n '1,220p' .terraform.lock.hcl

# Upgrade provider versions allowed by the constraint
terraform init -upgrade

# Add checksum entries for common CI platforms
terraform providers lock \\
  -platform=darwin_arm64 \\
  -platform=linux_amd64

# List provider installation details
terraform version
```

Commit `.terraform.lock.hcl` for root modules. Do not commit the `.terraform/` working directory.

### Step 22: Use lifecycle controls carefully

```hcl
resource "aws_s3_bucket" "critical_logs" {
  bucket = "my-company-critical-logs"

  lifecycle {
    prevent_destroy = true
  }
}
```

```bash
# Verify whether Terraform would replace a resource after a lifecycle change
terraform plan

# See why a particular resource is planned for change
terraform plan -out=tfplan
terraform show tfplan
```

`prevent_destroy` protects against Terraform-driven deletion, but it does not prevent deletion from the AWS Console or CLI. Combine it with IAM controls and AWS service-level protections.

### Step 23: Generate machine-readable plans for policy and CI

```bash
# Produce the reviewed plan artifact
terraform plan -out=tfplan -input=false

# Convert the plan to JSON for policy checks or reporting
terraform show -json tfplan > tfplan.json

# Extract planned resource actions
jq -r '.resource_changes[] | "\(.address): \(.change.actions | join(","))"' tfplan.json

# Apply the exact approved plan
terraform apply -input=false tfplan
```

Avoid applying a fresh plan after approval: provider data, remote state, and AWS resources can change between plan and apply.

---

## Quick Reference Commands

### Initialize and inspect

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform state list
terraform output
```

### Change infrastructure

```bash
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
terraform plan -refresh-only
terraform apply -refresh-only
```

### AWS verification

```bash
aws sts get-caller-identity
aws ec2 describe-vpcs --output table
aws s3api list-buckets --output table
aws eks list-clusters --region eu-west-2
```

### Cleanup

```bash
terraform plan -destroy
terraform destroy
```

---

## Common AWS Scenarios

### Provision the repository's AWS stack through LocalStack

```bash
# Step 1: Work from the Terraform root
cd tf

# Step 2: Start LocalStack (when supplied by the project)
docker compose up -d

# Step 3: Initialize, format, and validate
terraform init
terraform fmt -check -recursive
terraform validate

# Step 4: Create and review a plan
terraform plan -out=tfplan
terraform show tfplan

# Step 5: Apply the reviewed plan
terraform apply tfplan

# Step 6: Verify created resources through LocalStack
aws --endpoint-url=http://localhost:4566 s3api list-buckets
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs

# Step 7: Inspect Terraform outputs
terraform output
```

### Deploy safely to a real AWS development account

```bash
# Step 1: Authenticate with short-lived credentials
aws sso login --profile development
export AWS_PROFILE=development
export AWS_REGION=eu-west-2

# Step 2: Confirm the target account before any change
aws sts get-caller-identity

# Step 3: Initialize the approved remote backend and validate code
terraform init -reconfigure
terraform fmt -check -recursive
terraform validate

# Step 4: Create, inspect, then apply the same plan file
terraform plan -input=false -var-file=environments/dev.tfvars -out=tfplan
terraform show tfplan
terraform apply -input=false tfplan

# Step 5: Check outputs and AWS resources
terraform output
aws ec2 describe-vpcs --output table
```

### Investigate unexpected infrastructure drift

```bash
# Step 1: Refresh state and show proposed reconciliation changes
terraform plan -refresh-only -out=refresh.tfplan

# Step 2: Review the changes before accepting them into state
terraform show refresh.tfplan

# Step 3: Apply only if the remote state is now the intended baseline
terraform apply refresh.tfplan

# Step 4: Run a normal plan to see configuration changes still required
terraform plan
```

### Remove a disposable environment

```bash
# Step 1: Confirm the selected workspace/account first
terraform workspace show
aws sts get-caller-identity

# Step 2: Inspect every resource planned for deletion
terraform plan -destroy -out=destroy.tfplan
terraform show destroy.tfplan

# Step 3: Destroy only after confirmation
terraform apply destroy.tfplan
```

---

## Further Reading

- [Terraform CLI documentation](https://developer.hashicorp.com/terraform/cli)
- [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
