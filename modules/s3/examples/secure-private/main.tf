# ============================================================
# examples/secure-private/main.tf
# Hardened compliance bucket with:
#   - Object Lock (WORM) - COMPLIANCE mode (regulaciones financieras)
#   - DSSE-KMS (dual-layer encryption)
#   - All public access blocked
#   - Custom bucket policy (SOC2/PCI-DSS pattern)
#   - Versioning required by Object Lock
#   - MFA Delete (extra protection)
#   - Inventory diario en Parquet
#   - Logging con partitioned prefix
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.40.0" }
  }
}

provider "aws" { region = var.aws_region }

data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "compliance_policy" {
  # Deny delete of any object version (belt-and-suspenders with COMPLIANCE lock)
  statement {
    sid    = "DenyDeleteObjectVersion"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:DeleteObjectVersion"]
    resources = ["arn:aws:s3:::bsol-compliance-${var.environment}/*"]
  }

  # Deny disabling versioning
  statement {
    sid    = "DenyDisableVersioning"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:PutBucketVersioning"]
    resources = ["arn:aws:s3:::bsol-compliance-${var.environment}"]
    condition {
      test     = "StringEquals"
      variable = "s3:VersionStatus"
      values   = ["Suspended"]
    }
  }

  # Allow only specific IAM roles to write
  statement {
    sid    = "AllowCompliantWriters"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.writer_role_name}",
      ]
    }
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::bsol-compliance-${var.environment}",
      "arn:aws:s3:::bsol-compliance-${var.environment}/*",
    ]
  }

  # Deny insecure transport
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals { type = "*"; identifiers = ["*"] }
    actions   = ["s3:*"]
    resources = [
      "arn:aws:s3:::bsol-compliance-${var.environment}",
      "arn:aws:s3:::bsol-compliance-${var.environment}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

module "compliance_bucket" {
  source = "../../modules/s3"

  bucket_name = "bsol-compliance-${var.environment}"
  environment = var.environment
  force_destroy = false # NEVER allow force-destroy on compliance buckets

  # Object Lock — must be set at bucket creation (immutable)
  object_lock_enabled = true

  # DSSE-KMS: dual-layer encryption
  encryption = {
    sse_algorithm      = "aws:kms:dsse"
    kms_key_id         = var.compliance_kms_key_arn
    bucket_key_enabled = true
  }

  # Versioning required by Object Lock
  versioning = {
    enabled    = true
    mfa_delete = var.environment == "prod" # MFA delete in prod only
  }

  # Maximum public access lockdown
  block_public_access = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  # Custom policy (overrides managed policies)
  bucket_policy = data.aws_iam_policy_document.compliance_policy.json

  # WORM retention — COMPLIANCE mode (cannot be overridden by anyone)
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode  = "COMPLIANCE"
        years = 7  # 7-year retention for financial records
      }
    }
  }

  # Inventory for auditing
  inventory_configurations = {
    compliance_inventory = {
      enabled                  = true
      included_object_versions = "All"
      schedule_frequency       = "Daily"
      destination_bucket_arn   = var.audit_bucket_arn
      destination_prefix       = "inventory/compliance/"
      destination_format       = "Parquet"
      destination_encryption = {
        sse_kms = { key_id = var.compliance_kms_key_arn }
      }
      optional_fields = [
        "Size", "LastModifiedDate", "StorageClass", "ETag",
        "EncryptionStatus", "IsMultipartUploaded", "ReplicationStatus",
        "ObjectLockMode", "ObjectLockRetainUntilDate", "ObjectLockLegalHoldStatus",
        "ChecksumAlgorithm",
      ]
    }
  }

  # Access logging with partitioned prefix for Athena queries
  logging = {
    target_bucket = var.audit_log_bucket
    target_prefix = "s3-access-logs/compliance/"
    target_object_key_format = {
      partitioned_prefix = { partition_date_source = "DeliveryTime" }
    }
  }

  # Metrics for security monitoring
  metrics_configurations = {
    all_requests = {}
  }

  tags = {
    Project       = "bsol-compliance"
    Owner         = "security-team"
    CostCenter    = "security"
    DataClass     = "restricted"
    ComplianceTag = "PCI-DSS,SOC2"
    BackupPolicy  = "object-lock-compliance"
    Immutable     = "true"
  }
}

# ── Variables ─────────────────────────────────────────────────
variable "aws_region"               { type = string; default = "us-east-1" }
variable "environment"              { type = string; default = "prod" }
variable "compliance_kms_key_arn"   { type = string }
variable "writer_role_name"         { type = string }
variable "audit_bucket_arn"         { type = string }
variable "audit_log_bucket"         { type = string }

# ── Outputs ───────────────────────────────────────────────────
output "bucket_arn"           { value = module.compliance_bucket.bucket_arn }
output "bucket_id"            { value = module.compliance_bucket.bucket_id }
output "object_lock_enabled"  { value = module.compliance_bucket.object_lock_enabled }
output "object_lock_config"   { value = module.compliance_bucket.object_lock_configuration }
output "encryption_algorithm" { value = module.compliance_bucket.encryption_sse_algorithm }
