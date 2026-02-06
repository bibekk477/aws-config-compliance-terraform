variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "terraform-governance-demo"
}

variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  type        = string
  default     = "http://localhost:4566"
} 
variable "bucket_name" {
  description = "Name of the S3 bucket to store config history"
  type        = string
  default     = "config-bucket"
}