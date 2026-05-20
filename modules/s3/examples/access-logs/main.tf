# ============================================================
# examples/access-logs/main.tf
# Centralized S3 access logs destination bucket with:
#   - log-delivery-write ACL (legacy requirement for access log delivery)
#   - BucketOwnerPreferred ownership (log delivery writes as LogDelivery group)
#   - attach_inventory_destination_policy = true (allow S3 Inventory writes)
#   - Lifecycle: auto-expire logs after 90 days, GLACIER after 30
#   - Transfer to INTELLIGENT_TIERING
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.40.0" }
  }
}

provider "aws" { region = var.aws_region }

module "access_logs_bucket" {
  source = "../../modules/s3"

  bucket_name = "bsol-access-logs-${data.aws_caller_identity.current.account_id}"
  environment = var.environment

  # S3 access log delivery requires BucketOwnerPreferred + log-delivery-write ACL
  object_ownership = "BucketOwnerPreferred"

  block_public_access = {
    block_public_acls       = false  # Required for log delivery ACL
    block_public_policy     = true
    ignore_public_acls      = false  # Required for log delivery ACL
    restrict_public_buckets = true
  }

  acl = "log-delivery-write"

  # Allow S3 Inventory to write to this bucket
  attach_inventory_destination_policy   = true
  attach_deny_insecure_transport_policy = true

  encryption = {
    sse_algorithm = "AES256" # SSE-S3 (log delivery doesn't support SSE-KMS)
  }

  lifecycle_rules = {
    log_retention = {
      enabled = true
      filter  = { prefix = "" }
      transitions = [
        { days = 30,  storage_class = "STANDARD_IA" },
        { days = 60,  storage_class = "GLACIER" },
      ]
      expiration = { days = 365 }
      abort_incomplete_multipart_upload_days = 1
    }

    s3_access_logs = {
      enabled = true
      filter  = { prefix = "s3-access-logs/" }
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" }
      ]
      expiration = { days = 90 }
    }

    elb_access_logs = {
      enabled = true
      filter  = { prefix = "alb/" }
      transitions = [
        { days = 30, storage_class = "STANDARD_IA" }
      ]
      expiration = { days = 180 }
    }
  }

  tags = {
    Project    = "bsol-logging"
    Owner      = "platform-engineering"
    CostCenter = "infra"
    Purpose    = "centralized-access-logs"
  }
}

data "aws_caller_identity" "current" {}

variable "aws_region"  { type = string; default = "us-east-1" }
variable "environment" { type = string; default = "prod" }

output "bucket_id"  { value = module.access_logs_bucket.bucket_id }
output "bucket_arn" { value = module.access_logs_bucket.bucket_arn }
output "s3_uri"     { value = module.access_logs_bucket.s3_uri }
