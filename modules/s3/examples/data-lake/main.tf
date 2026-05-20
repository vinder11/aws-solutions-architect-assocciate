# ============================================================
# examples/data-lake/main.tf
# Enterprise Data Lake bucket with:
#   - SSE-KMS with customer-managed key + bucket key
#   - Versioning enabled
#   - Tiered lifecycle (STANDARD → IA → GLACIER → DEEP_ARCHIVE)
#   - Noncurrent version management
#   - Intelligent-Tiering for unpredictable access patterns
#   - Daily inventory (Parquet) sent to a reporting bucket
#   - Storage Class Analysis for all prefixes
#   - Request metrics per data domain (raw/, curated/, analytics/)
#   - CRR to DR region with RTC (15-min SLA)
#   - Deny insecure transport + unencrypted uploads
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.40.0" }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

module "data_lake" {
  source = "../../modules/s3"

  providers = { aws = aws.primary }

  bucket_name = "bsol-datalake-${var.environment}"
  environment = var.environment

  # Never auto-delete — enforce via lifecycle only
  force_destroy = false

  # ── Encryption ──────────────────────────────────────────────
  encryption = {
    sse_algorithm      = "aws:kms"
    kms_key_id         = var.kms_key_arn
    bucket_key_enabled = true # Saves ~99% KMS API calls
  }

  # ── Versioning (required for replication) ────────────────────
  versioning = { enabled = true }

  # ── Security policies ────────────────────────────────────────
  attach_deny_insecure_transport_policy      = true
  attach_deny_unencrypted_object_uploads     = true
  attach_require_latest_tls_policy           = true

  # ── Lifecycle ────────────────────────────────────────────────
  lifecycle_rules = {
    # Raw data zone: aggressive tiering
    raw_data = {
      enabled = true
      filter  = { prefix = "raw/" }
      transitions = [
        { days = 30,  storage_class = "STANDARD_IA" },
        { days = 90,  storage_class = "GLACIER_IR" },
        { days = 365, storage_class = "DEEP_ARCHIVE" },
      ]
      noncurrent_version_transitions = [
        { noncurrent_days = 30, storage_class = "GLACIER" }
      ]
      noncurrent_version_expiration = {
        noncurrent_days           = 365
        newer_noncurrent_versions = 3
      }
      abort_incomplete_multipart_upload_days = 3
    }

    # Curated data zone: keep accessible longer
    curated_data = {
      enabled = true
      filter  = { prefix = "curated/" }
      transitions = [
        { days = 90,  storage_class = "STANDARD_IA" },
        { days = 365, storage_class = "GLACIER_IR" },
      ]
      noncurrent_version_expiration = {
        noncurrent_days           = 180
        newer_noncurrent_versions = 5
      }
      abort_incomplete_multipart_upload_days = 7
    }

    # Analytics outputs: expire after 2 years
    analytics_outputs = {
      enabled = true
      filter  = { prefix = "analytics/" }
      expiration = { days = 730 }
      transitions = [
        { days = 90, storage_class = "STANDARD_IA" }
      ]
      abort_incomplete_multipart_upload_days = 1
    }

    # Cleanup all incomplete multipart uploads bucket-wide as safety net
    global_multipart_cleanup = {
      enabled                                = true
      filter                                 = { prefix = "" }
      abort_incomplete_multipart_upload_days = 7
    }
  }

  # ── Intelligent-Tiering ──────────────────────────────────────
  intelligent_tiering_configurations = {
    # For objects in curated/ that haven't been accessed in 90+ days
    curated_tiering = {
      status = "Enabled"
      filter = { prefix = "curated/ml-features/" }
      tiering = [
        { access_tier = "ARCHIVE_ACCESS",      days = 90  },
        { access_tier = "DEEP_ARCHIVE_ACCESS",  days = 180 },
      ]
    }
  }

  # ── Inventory (compliance & auditing) ────────────────────────
  inventory_configurations = {
    daily_full_inventory = {
      enabled                  = true
      included_object_versions = "All"
      schedule_frequency       = "Daily"
      destination_bucket_arn   = var.inventory_bucket_arn
      destination_prefix       = "inventory/bsol-datalake/"
      destination_format       = "Parquet"
      destination_encryption   = { sse_s3 = true }
      optional_fields = [
        "Size", "LastModifiedDate", "StorageClass", "ETag",
        "IsMultipartUploaded", "ReplicationStatus", "EncryptionStatus",
        "IntelligentTieringAccessTier", "ChecksumAlgorithm",
      ]
    }
  }

  # ── Request Metrics per domain ────────────────────────────────
  metrics_configurations = {
    raw_metrics      = { filter_prefix = "raw/" }
    curated_metrics  = { filter_prefix = "curated/" }
    analytics_metrics = { filter_prefix = "analytics/" }
    all_bucket       = {} # no filter = entire bucket
  }

  # ── Storage Class Analysis ────────────────────────────────────
  analytics_configurations = {
    raw_analysis = {
      filter_prefix = "raw/"
      destination = {
        bucket_arn = var.analytics_bucket_arn
        prefix     = "analysis/raw/"
      }
    }
    curated_analysis = {
      filter_prefix = "curated/"
      destination = {
        bucket_arn = var.analytics_bucket_arn
        prefix     = "analysis/curated/"
      }
    }
  }

  # ── CRR to DR region with RTC ─────────────────────────────────
  replication_configuration = {
    role_arn = var.replication_role_arn
    rules = {
      full_replication = {
        status   = "Enabled"
        priority = 1
        destination = {
          bucket             = var.dr_bucket_arn
          storage_class      = "STANDARD_IA"
          replica_kms_key_id = var.dr_kms_key_arn
          replication_time = {
            status  = "Enabled"
            minutes = 15
          }
          metrics = {
            status  = "Enabled"
            minutes = 15
          }
        }
        delete_marker_replication = { status = "Enabled" }
        source_selection_criteria = {
          sse_kms_encrypted_objects = { status = "Enabled" }
          replica_modifications     = { status = "Enabled" }
        }
      }
    }
  }

  # ── Access logs ───────────────────────────────────────────────
  logging = {
    target_bucket = var.access_log_bucket
    target_prefix = "s3-access-logs/bsol-datalake/"
    target_object_key_format = {
      partitioned_prefix = { partition_date_source = "EventTime" }
    }
  }

  # ── SQS notification for new raw data ────────────────────────
  notifications = {
    eventbridge = false
    queues = {
      raw_ingestion = {
        queue_arn     = var.raw_ingestion_queue_arn
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "raw/"
        filter_suffix = ".parquet"
      }
    }
    lambda_functions = {}
    topics           = {}
  }

  tags = {
    Project      = "bsol-datalake"
    Owner        = "data-platform"
    CostCenter   = "data"
    DataClass    = "confidential"
    BackupPolicy = "crr-enabled"
  }
}

# ── Variables ─────────────────────────────────────────────────
variable "primary_region"         { type = string; default = "us-east-1" }
variable "dr_region"              { type = string; default = "us-west-2" }
variable "environment"            { type = string; default = "prod" }
variable "kms_key_arn"            { type = string }
variable "dr_kms_key_arn"         { type = string }
variable "dr_bucket_arn"          { type = string }
variable "replication_role_arn"   { type = string }
variable "inventory_bucket_arn"   { type = string }
variable "analytics_bucket_arn"   { type = string }
variable "access_log_bucket"      { type = string }
variable "raw_ingestion_queue_arn" { type = string }

# ── Outputs ───────────────────────────────────────────────────
output "bucket_arn"              { value = module.data_lake.bucket_arn }
output "bucket_id"               { value = module.data_lake.bucket_id }
output "s3_uri"                  { value = module.data_lake.s3_uri }
output "replication_enabled"     { value = module.data_lake.replication_configuration_id != null }
output "inventory_configs"       { value = module.data_lake.inventory_configuration_ids }
