terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  endpoints {
    ec2      = var.localstack_endpoint
    s3       = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    sts      = var.localstack_endpoint
    iam      = var.localstack_endpoint
    kms      = var.localstack_endpoint
    cloudwatch = var.localstack_endpoint
    eks= var.localstack_endpoint
    configservice = var.localstack_endpoint
    secretsmanager = var.localstack_endpoint

}

}