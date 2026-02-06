# AWS Config and IAM Governance with Terraform

A Terraform project demonstrating AWS Config setup with compliance rules and IAM governance policies.

## Architecture Diagram

```
                        +------------------------+
                        |  AWS Config Service    |
                        | (config.amazonaws.com) |
                        +-----------+------------+
                                    |
                                    | Assumes role
                                    v
                        +------------------------+
                        |  IAM Role: config_role |
                        |------------------------|
                        | - AWS-managed policy   |
                        |   AWS_ConfigRole       |
                        | - Inline policy:       |
                        |   config_s3_policy     | <-- access to S3 bucket
                        +-----------+------------+
                                    |
                                    v
                        +------------------------+
                        |  S3 Bucket: config_bucket |
                        |------------------------|
                        | - Versioning enabled   |
                        | - AES-256 Encryption  |
                        | - Block public access |
                        | - Bucket policy allows|
                        |   AWS Config to:      |
                        |   GetBucketAcl,       |
                        |   ListBucket,         |
                        |   PutObject (ACL)     |
                        |   Deny non-HTTPS      |
                        +-----------+------------+
                                    ^
                                    |
                +-------------------+-------------------+
                |                                       |
+-----------------------------+          +-----------------------------+
| IAM User: demo_user         |          | Custom IAM Policies          |
|-----------------------------|          |-----------------------------|
| - Attached:                 |          | 1. mfa_delete_policy        | <-- MFA required for deletes
|   - mfa_delete_policy       |          | 2. enforce_s3_encryption_transit | <-- only HTTPS
|                             |          | 3. require_tags_policy      | <-- tags required on EC2/S3
+-----------------------------+          +-----------------------------+
                                    ^
                                    |
                        +-----------+------------+
                        | AWS Config Recorder      |
                        |------------------------|
                        | - Records all resources|
                        | - Includes global types|
                        +-----------+------------+
                                    |
                                    v
                        +------------------------+
                        | AWS Config Delivery    |
                        | Channel                |
                        |------------------------|
                        | - Delivers config data |
                        |   to S3 bucket         |
                        +-----------+------------+
                                    |
                                    v
                        +------------------------+
                        | AWS Config Rules       |
                        |------------------------|
                        | - S3 Public Write Prohibited |
                        | - S3 Encryption Enabled      |
                        | - S3 Public Read Prohibited  |
                        | - EBS Volumes Encrypted      |
                        | - Required Tags (EC2, S3)   |
                        | - Root MFA Enabled           |
                        +-----------------------------+
```

## Features

### AWS Config

- **Configuration Recorder**: Tracks all AWS resource configurations
- **Delivery Channel**: Stores configuration history in S3
- **Config Rules**: Automated compliance checks

### IAM Policies

- **MFA Delete Policy**: Requires MFA for S3 object deletion
- **S3 Encryption Transit**: Enforces HTTPS for S3 operations
- **Resource Tagging**: Requires specific tags on EC2 and S3 resources

### S3 Bucket Security

- Server-side encryption (AES-256)
- Versioning enabled
- Public access blocked
- HTTPS-only access enforced

## Compliance Rules

| Rule                                       | Purpose                                       |
| ------------------------------------------ | --------------------------------------------- |
| `s3-bucket-public-write-prohibited`        | Prevents public write access to S3 buckets    |
| `s3-bucket-server-side-encryption-enabled` | Ensures S3 buckets are encrypted              |
| `s3-bucket-public-read-prohibited`         | Prevents public read access to S3 buckets     |
| `encrypted-volumes`                        | Ensures EBS volumes are encrypted             |
| `required-tags`                            | Enforces Environment and Owner tags on EC2/S3 |
| `root-account-mfa-enabled`                 | Ensures root account has MFA enabled          |

## File Structure

```
.
├── main.tf           # S3 bucket configuration
├── config.tf         # AWS Config recorder, delivery channel, and rules
├── iam.tf            # IAM roles, policies, and users
├── variables.tf      # Input variables
├── outputs.tf        # Output values
└── provider.tf       # Provider configuration
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured (or LocalStack for local testing)
- Appropriate AWS permissions

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review the Plan

```bash
terraform plan
```

### 3. Apply the Configuration

```bash
terraform apply
```

### 4. View Outputs

```bash
terraform output
```

## Configuration

### Variables

| Variable              | Description                       | Default                     |
| --------------------- | --------------------------------- | --------------------------- |
| `aws_region`          | AWS region                        | `us-east-1`                 |
| `project_name`        | Project name prefix               | `terraform-governance-demo` |
| `localstack_endpoint` | LocalStack endpoint (for testing) | `http://localhost:4566`     |

### Example: Custom Values

Create a `terraform.tfvars` file:

```hcl
aws_region   = "us-west-2"
project_name = "my-governance"
```

## Outputs

After applying, Terraform provides:

- Config bucket name and ARN
- IAM policy ARNs
- Demo user name and ARN
- Config recorder status
- List of active Config rules

## Testing with LocalStack

This project is configured to work with LocalStack for local testing:

```bash
# Start LocalStack
docker run -d -p 4566:4566 localstack/localstack

# Apply Terraform
terraform apply
```

## Clean Up

```bash
terraform destroy
```

## Testing and Validation

### Quick Status Check

```bash
# View all outputs
terraform output

# List all provisioned resources
terraform state list
```

### Validate S3 Bucket

```bash
# List buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Check bucket versioning
aws --endpoint-url=http://localhost:4566 s3api get-bucket-versioning `
  --bucket `terraform output -raw config_bucket_name`

# Check bucket encryption
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption `
  --bucket `terraform output -raw config_bucket_name`
```

### Validate AWS Config

```bash
# Check configuration recorder
aws --endpoint-url=http://localhost:4566 configservice describe-configuration-recorders

# Check recorder status
aws --endpoint-url=http://localhost:4566 configservice describe-configuration-recorder-status

# List all Config rules
aws --endpoint-url=http://localhost:4566 configservice describe-config-rules

# Check delivery channel
aws --endpoint-url=http://localhost:4566 configservice describe-delivery-channels
```

### Validate IAM Resources

```bash
# List IAM roles
aws --endpoint-url=http://localhost:4566 iam list-roles

# Get Config role details
aws --endpoint-url=http://localhost:4566 iam get-role `
  --role-name terraform-governance-demo-config-role

# List custom IAM policies
aws --endpoint-url=http://localhost:4566 iam list-policies --scope Local

# Get demo user details
aws --endpoint-url=http://localhost:4566 iam get-user `
  --user-name `terraform output -raw demo_user_name`
```
