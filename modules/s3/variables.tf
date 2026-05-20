# ============================================================
# variables.tf — terraform-aws-s3 module
# ============================================================

# ─────────────────────────────────────────────────────────────
# CORE BUCKET
# ─────────────────────────────────────────────────────────────

variable "bucket_name" {
  description = <<-EOT
    Globally unique S3 bucket name.
    Rules: 3–63 chars, lowercase alphanumeric + hyphens, must start/end with
    alphanumeric, no consecutive hyphens, no IP-address format.
    Leave null to let AWS generate a name (use with bucket_prefix).
  EOT
  type        = string
  default     = null

  validation {
    condition = var.bucket_name == null || (
      can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name)) &&
      !can(regex("\\.\\.|-$|^-|^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.bucket_name))
    )
    error_message = "bucket_name must be 3–63 chars, lowercase alphanumeric/hyphens, start/end with alphanumeric, no IP format."
  }
}

variable "bucket_prefix" {
  description = "Creates a unique bucket name beginning with this prefix (max 37 chars). Mutually exclusive with bucket_name."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_prefix == null || can(regex("^[a-z0-9][a-z0-9-]{0,36}$", var.bucket_prefix))
    error_message = "bucket_prefix must be lowercase alphanumeric/hyphens, start with alphanumeric, max 37 chars."
  }
}

variable "force_destroy" {
  description = "Allow Terraform to delete the bucket and ALL contents when destroying. DANGEROUS in production."
  type        = bool
  default     = false
}

variable "object_lock_enabled" {
  description = "Enable S3 Object Lock on bucket creation (immutable; cannot be disabled after creation)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod). Merged into tags."
  type        = string
  default     = ""

  validation {
    condition     = var.environment == "" || contains(["dev", "staging", "prod", "sandbox", "qa"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, sandbox, qa (or empty string)."
  }
}

# ─────────────────────────────────────────────────────────────
# OWNERSHIP & ACLs
# ─────────────────────────────────────────────────────────────

variable "object_ownership" {
  description = <<-EOT
    S3 Object Ownership control:
    - BucketOwnerEnforced: ACLs disabled (recommended default, AWS default since April 2023)
    - BucketOwnerPreferred: objects uploaded by other accounts belong to bucket owner if ACL set
    - ObjectWriter: uploader retains ownership
  EOT
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "object_ownership must be: BucketOwnerEnforced, BucketOwnerPreferred, or ObjectWriter."
  }
}

variable "acl" {
  description = "Canned ACL. Only valid when object_ownership != BucketOwnerEnforced. Set null to skip."
  type        = string
  default     = null

  validation {
    condition = var.acl == null || contains([
      "private", "public-read", "public-read-write", "authenticated-read",
      "aws-exec-read", "bucket-owner-read", "bucket-owner-full-control", "log-delivery-write"
    ], var.acl)
    error_message = "acl must be a valid S3 canned ACL value or null."
  }
}

# ─────────────────────────────────────────────────────────────
# VERSIONING
# ─────────────────────────────────────────────────────────────

variable "versioning" {
  description = "S3 bucket versioning configuration."
  type = object({
    enabled    = optional(bool, false)
    mfa_delete = optional(bool, false) # Requires MFA + versioning enabled
  })
  default = {}

  validation {
    condition     = !var.versioning.mfa_delete || var.versioning.enabled
    error_message = "versioning.mfa_delete requires versioning.enabled = true."
  }
}

# ─────────────────────────────────────────────────────────────
# ENCRYPTION
# ─────────────────────────────────────────────────────────────

variable "encryption" {
  description = <<-EOT
    Server-side encryption configuration.
    sse_algorithm: AES256 (SSE-S3) | aws:kms (SSE-KMS) | aws:kms:dsse (DSSE-KMS)
    kms_key_id: KMS key ARN or alias. Required for aws:kms / aws:kms:dsse.
    bucket_key_enabled: reduces KMS API calls and costs (recommended with SSE-KMS).
  EOT
  type = object({
    sse_algorithm      = optional(string, "aws:kms")
    kms_key_id         = optional(string, null)
    bucket_key_enabled = optional(bool, true)
  })
  default = {}

  validation {
    condition     = contains(["AES256", "aws:kms", "aws:kms:dsse"], var.encryption.sse_algorithm)
    error_message = "encryption.sse_algorithm must be: AES256, aws:kms, or aws:kms:dsse."
  }

  validation {
    condition = var.encryption.sse_algorithm == "AES256" || (
      var.encryption.sse_algorithm != "AES256" && (
        var.encryption.kms_key_id == null ||
        can(regex("^(arn:aws[a-z-]*:kms:|alias/)", var.encryption.kms_key_id))
      )
    )
    error_message = "encryption.kms_key_id must be a valid KMS key ARN or alias (e.g. alias/my-key) or null (uses AWS-managed key)."
  }

  validation {
    condition     = !var.encryption.bucket_key_enabled || contains(["aws:kms", "aws:kms:dsse"], var.encryption.sse_algorithm)
    error_message = "encryption.bucket_key_enabled is only valid with aws:kms or aws:kms:dsse."
  }
}

# ─────────────────────────────────────────────────────────────
# PUBLIC ACCESS BLOCK
# ─────────────────────────────────────────────────────────────

variable "block_public_access" {
  description = <<-EOT
    S3 Block Public Access settings.
    All default to true (maximum protection). Relax ONLY for intentional public buckets.
  EOT
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {}
}

# ─────────────────────────────────────────────────────────────
# BUCKET POLICY
# ─────────────────────────────────────────────────────────────

variable "bucket_policy" {
  description = "JSON bucket policy document. Use aws_iam_policy_document data source and encode with jsonencode()."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_policy == null || can(jsondecode(var.bucket_policy))
    error_message = "bucket_policy must be valid JSON (use jsonencode() or aws_iam_policy_document)."
  }
}

variable "attach_deny_insecure_transport_policy" {
  description = "Attach a policy that denies all HTTP (non-TLS) requests to the bucket."
  type        = bool
  default     = true
}

variable "attach_deny_unencrypted_object_uploads" {
  description = "Attach a policy that denies PutObject requests without server-side encryption headers."
  type        = bool
  default     = false
}

variable "attach_require_latest_tls_policy" {
  description = "Attach a policy requiring TLS 1.2 or higher for all requests."
  type        = bool
  default     = false
}

variable "attach_inventory_destination_policy" {
  description = "Attach policy allowing S3 Inventory to write to this bucket (use when this bucket is an inventory destination)."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────────────────────────
# LIFECYCLE RULES
# ─────────────────────────────────────────────────────────────

variable "lifecycle_rules" {
  description = <<-EOT
    Map of lifecycle rules. Key = rule ID (must be unique).
    transition.storage_class valid values:
      STANDARD_IA | ONEZONE_IA | INTELLIGENT_TIERING | GLACIER_IR | GLACIER | DEEP_ARCHIVE
  EOT
  type = map(object({
    enabled = optional(bool, true)
    prefix  = optional(string, null) # deprecated in favour of filter; use filter_prefix
    tags    = optional(map(string), {})

    filter = optional(object({
      prefix                   = optional(string, null)
      tags                     = optional(map(string), {})
      object_size_greater_than = optional(number, null) # bytes
      object_size_less_than    = optional(number, null) # bytes
    }), null)

    expiration = optional(object({
      days                         = optional(number, null)
      date                         = optional(string, null) # RFC3339 date
      expired_object_delete_marker = optional(bool, null)
    }), null)

    transitions = optional(list(object({
      days          = optional(number, null)
      date          = optional(string, null)
      storage_class = string
    })), [])

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = optional(number, null)
      newer_noncurrent_versions = optional(number, null)
    }), null)

    noncurrent_version_transitions = optional(list(object({
      noncurrent_days           = optional(number, null)
      newer_noncurrent_versions = optional(number, null)
      storage_class             = string
    })), [])

    abort_incomplete_multipart_upload_days = optional(number, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, r in var.lifecycle_rules : alltrue([
        for t in r.transitions :
        contains(["STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER_IR", "GLACIER", "DEEP_ARCHIVE"], t.storage_class)
      ])
    ])
    error_message = "lifecycle_rules[*].transitions[*].storage_class must be a valid S3 storage class."
  }

  validation {
    condition = alltrue([
      for k, r in var.lifecycle_rules : alltrue([
        for t in r.noncurrent_version_transitions :
        contains(["STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER_IR", "GLACIER", "DEEP_ARCHIVE"], t.storage_class)
      ])
    ])
    error_message = "lifecycle_rules[*].noncurrent_version_transitions[*].storage_class must be a valid S3 storage class."
  }

  validation {
    condition = alltrue([
      for k, r in var.lifecycle_rules :
      r.abort_incomplete_multipart_upload_days == null ||
      (r.abort_incomplete_multipart_upload_days >= 1 && r.abort_incomplete_multipart_upload_days <= 365)
    ])
    error_message = "abort_incomplete_multipart_upload_days must be between 1 and 365."
  }
}

# ─────────────────────────────────────────────────────────────
# REPLICATION
# ─────────────────────────────────────────────────────────────

variable "replication_configuration" {
  description = <<-EOT
    Cross-Region or Same-Region Replication (CRR/SRR) configuration.
    Requires versioning enabled on source bucket.
    role_arn: IAM role ARN with s3:ReplicateObject permissions.
  EOT
  type = object({
    role_arn = string
    rules = map(object({
      id       = optional(string, null)
      status   = optional(string, "Enabled")
      priority = optional(number, null)

      filter = optional(object({
        prefix = optional(string, null)
        tags   = optional(map(string), {})
      }), null)

      destination = object({
        bucket             = string # destination bucket ARN
        storage_class      = optional(string, null)
        account            = optional(string, null) # for cross-account replication
        replica_kms_key_id = optional(string, null) # KMS key in destination region
        access_control_translation = optional(object({
          owner = string # Destination
        }), null)
        replication_time = optional(object({
          status  = optional(string, "Enabled")
          minutes = optional(number, 15) # RTC: 15 minutes SLA
        }), null)
        metrics = optional(object({
          status  = optional(string, "Enabled")
          minutes = optional(number, 15)
        }), null)
      })

      delete_marker_replication = optional(object({
        status = optional(string, "Enabled")
      }), { status = "Disabled" })

      source_selection_criteria = optional(object({
        replica_modifications = optional(object({
          status = optional(string, "Enabled")
        }), null)
        sse_kms_encrypted_objects = optional(object({
          status = optional(string, "Enabled")
        }), null)
      }), null)

      existing_object_replication = optional(object({
        status = optional(string, "Enabled")
      }), null)
    }))
  })
  default = null

  validation {
    condition = var.replication_configuration == null || (
      can(regex("^arn:aws[a-z-]*:iam::", var.replication_configuration.role_arn))
    )
    error_message = "replication_configuration.role_arn must be a valid IAM role ARN."
  }

  validation {
    condition = var.replication_configuration == null || alltrue([
      for k, r in var.replication_configuration.rules :
      contains(["Enabled", "Disabled"], r.status)
    ])
    error_message = "replication_configuration.rules[*].status must be Enabled or Disabled."
  }

  validation {
    condition = var.replication_configuration == null || alltrue([
      for k, r in var.replication_configuration.rules :
      r.destination.storage_class == null ||
      contains(["STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "GLACIER_IR", "DEEP_ARCHIVE"], r.destination.storage_class)
    ])
    error_message = "replication destination.storage_class must be a valid S3 storage class or null."
  }
}

# ─────────────────────────────────────────────────────────────
# OBJECT LOCK (WORM)
# ─────────────────────────────────────────────────────────────

variable "object_lock_configuration" {
  description = <<-EOT
    Default Object Lock retention configuration. Requires object_lock_enabled = true.
    Set to null to disable default retention (Object Lock still enabled, but no automatic retention).
    
    mode: GOVERNANCE (can be overridden with permissions) | COMPLIANCE (irreversible, even root cannot override)
    
    Exactly one of days or years must be specified.
  EOT

  type = object({
    rule = object({
      default_retention = object({
        mode  = string # GOVERNANCE | COMPLIANCE
        days  = optional(number)
        years = optional(number)
      })
    })
  })

  default = null

  validation {
    condition = var.object_lock_configuration == null || contains(
      ["GOVERNANCE", "COMPLIANCE"],
      var.object_lock_configuration.rule.default_retention.mode
    )
    error_message = "object_lock_configuration.rule.default_retention.mode must be GOVERNANCE or COMPLIANCE."
  }

  validation {
    condition = var.object_lock_configuration == null || (
      (var.object_lock_configuration.rule.default_retention.days != null) !=
      (var.object_lock_configuration.rule.default_retention.years != null)
    )
    error_message = "Specify exactly one of days or years, not both, not neither."
  }

  validation {
    condition = var.object_lock_configuration == null || (
      (var.object_lock_configuration.rule.default_retention.days == null || var.object_lock_configuration.rule.default_retention.days > 0) &&
      (var.object_lock_configuration.rule.default_retention.years == null || var.object_lock_configuration.rule.default_retention.years > 0)
    )
    error_message = "days and years must be positive integers greater than 0."
  }
}

# ─────────────────────────────────────────────────────────────
# CORS
# ─────────────────────────────────────────────────────────────

variable "cors_rules" {
  description = "CORS rules for the bucket. Typically needed for static websites or SPA assets."
  type = list(object({
    id              = optional(string, null)
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string) # GET | PUT | POST | DELETE | HEAD
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.cors_rules : alltrue([
        for m in r.allowed_methods :
        contains(["GET", "PUT", "POST", "DELETE", "HEAD"], m)
      ])
    ])
    error_message = "cors_rules[*].allowed_methods must only contain: GET, PUT, POST, DELETE, HEAD."
  }

  validation {
    condition = alltrue([
      for r in var.cors_rules :
      r.max_age_seconds >= 0 && r.max_age_seconds <= 86400
    ])
    error_message = "cors_rules[*].max_age_seconds must be between 0 and 86400."
  }

  validation {
    condition = alltrue([
      for r in var.cors_rules : length(r.allowed_origins) > 0
    ])
    error_message = "cors_rules[*].allowed_origins must contain at least one origin."
  }
}

# ─────────────────────────────────────────────────────────────
# STATIC WEBSITE
# ─────────────────────────────────────────────────────────────

variable "website" {
  description = <<-EOT
    Static website hosting configuration.
    Mutually exclusive: index_document (standard hosting) vs redirect_all_requests_to (redirect-only).
    Set to null to disable website hosting entirely.
  EOT
  type = object({
    index_document = optional(string) # e.g. "index.html"
    error_document = optional(string) # e.g. "error.html"
    redirect_all_requests_to = optional(object({
      host_name = string
      protocol  = optional(string) # http | https
    }))
    routing_rules = optional(string) # JSON array of routing rules
  })

  default = null

  # Validación 1: index_document y redirect_all_requests_to son mutuamente exclusivos
  # Opción A: Ambos opcionales (pueden ser ambos null)
  # validation {
  #   condition = var.website == null || (
  #     (var.website.index_document == null && var.website.redirect_all_requests_to == null) ||
  #     (var.website.index_document != null && var.website.redirect_all_requests_to == null) ||
  #     (var.website.index_document == null && var.website.redirect_all_requests_to != null)
  #   )
  #   error_message = "website: use either index_document or redirect_all_requests_to exclusively, or leave both null."
  # }

  # Opción B (alternativa): Exactamente uno debe estar presente cuando website no es null
  validation {
    condition = var.website == null || (
      (var.website.index_document != null) != (var.website.redirect_all_requests_to != null)
    )
    error_message = "website: specify exactly one of index_document or redirect_all_requests_to."
  }

  # Validación 2: protocol debe ser http, https, o null
  validation {
    condition = (
      var.website == null
      ) || (
      var.website.redirect_all_requests_to == null
      ) || (
      var.website.redirect_all_requests_to.protocol == null
      ) || (
      contains(["http", "https"], var.website.redirect_all_requests_to.protocol)
    )
    error_message = "website.redirect_all_requests_to.protocol must be 'http', 'https', or null."
  }

  # Validación 3: routing_rules debe ser JSON válido si se proporciona
  validation {
    condition = (
      var.website == null
      ) || (
      var.website.routing_rules == null
      ) || (
      can(jsondecode(var.website.routing_rules))
    )
    error_message = "website.routing_rules must be a valid JSON string, e.g. '[{\"Condition\":...}]'."
  }

  # Validación 4: error_document solo si index_document está presente
  validation {
    condition = (
      var.website == null
      ) || (
      var.website.index_document != null
      ) || (
      var.website.error_document == null
    )
    error_message = "website.error_document can only be set when index_document is also set."
  }
}

# ─────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────

variable "logging" {
  description = "S3 server access logging configuration."
  type = object({
    target_bucket = string # Bucket name (not ARN) to receive logs
    target_prefix = optional(string, "logs/")
    target_object_key_format = optional(object({
      partitioned_prefix = optional(object({
        partition_date_source = optional(string, "EventTime") # EventTime | DeliveryTime
      }))
      simple_prefix = optional(bool, false)
    }))
  })

  default = null

  # Validación 1: bucket name válido
  validation {
    condition = (
      var.logging == null
      ) || (
      can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.logging.target_bucket))
    )
    error_message = "logging.target_bucket must be a valid S3 bucket name (3-63 chars, lowercase, alphanumeric, hyphens)."
  }

  # Validación 2: partition_date_source válido (si se usa partitioned_prefix)
  validation {
    condition = (
      var.logging == null
      ) || (
      var.logging.target_object_key_format == null
      ) || (
      var.logging.target_object_key_format.partitioned_prefix == null
      ) || (
      contains(
        ["EventTime", "DeliveryTime"],
        var.logging.target_object_key_format.partitioned_prefix.partition_date_source
      )
    )
    error_message = "logging.target_object_key_format.partitioned_prefix.partition_date_source must be EventTime or DeliveryTime."
  }

  # Validación 3: no usar partitioned_prefix y simple_prefix simultáneamente
  validation {
    condition = (
      var.logging == null
      ) || (
      var.logging.target_object_key_format == null
      ) || (
      var.logging.target_object_key_format.partitioned_prefix == null
      ) || (
      var.logging.target_object_key_format.simple_prefix == null
    )
    error_message = "logging.target_object_key_format: use either partitioned_prefix or simple_prefix, not both."
  }
}

# ─────────────────────────────────────────────────────────────
# NOTIFICATIONS
# ─────────────────────────────────────────────────────────────

variable "notifications" {
  description = <<-EOT
    S3 event notifications configuration.
    Supports Lambda, SQS, SNS, and EventBridge destinations.
    event_types: https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-how-to-event-types-and-destinations.html
  EOT
  type = object({
    eventbridge = optional(bool, false) # route all events to EventBridge

    lambda_functions = optional(map(object({
      lambda_function_arn = string
      events              = list(string)
      filter_prefix       = optional(string, null)
      filter_suffix       = optional(string, null)
    })), {})

    queues = optional(map(object({
      queue_arn     = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), {})

    topics = optional(map(object({
      topic_arn     = string
      events        = list(string)
      filter_prefix = optional(string, null)
      filter_suffix = optional(string, null)
    })), {})
  })
  default = null

  validation {
    condition = var.notifications == null || alltrue([
      for k, fn in(var.notifications.lambda_functions != null ? var.notifications.lambda_functions : {}) :
      can(regex("^arn:aws[a-z-]*:lambda:", fn.lambda_function_arn))
    ])
    error_message = "notifications.lambda_functions[*].lambda_function_arn must be a valid Lambda ARN."
  }

  validation {
    condition = var.notifications == null || alltrue([
      for k, q in(var.notifications.queues != null ? var.notifications.queues : {}) :
      can(regex("^arn:aws[a-z-]*:sqs:", q.queue_arn))
    ])
    error_message = "notifications.queues[*].queue_arn must be a valid SQS ARN."
  }

  validation {
    condition = var.notifications == null || alltrue([
      for k, t in(var.notifications.topics != null ? var.notifications.topics : {}) :
      can(regex("^arn:aws[a-z-]*:sns:", t.topic_arn))
    ])
    error_message = "notifications.topics[*].topic_arn must be a valid SNS ARN."
  }
}

# ─────────────────────────────────────────────────────────────
# INTELLIGENT TIERING
# ─────────────────────────────────────────────────────────────

variable "intelligent_tiering_configurations" {
  description = <<-EOT
    S3 Intelligent-Tiering archive configurations.
    Moves objects not accessed for N days to Archive or Deep Archive tiers.
    access_tier: ARCHIVE_ACCESS | DEEP_ARCHIVE_ACCESS
    days: ARCHIVE_ACCESS min 90, DEEP_ARCHIVE_ACCESS min 180.
  EOT
  type = map(object({
    status = optional(string, "Enabled")
    filter = optional(object({
      prefix = optional(string, null)
      tags   = optional(map(string), {})
    }), null)
    tiering = list(object({
      access_tier = string
      days        = number
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, c in var.intelligent_tiering_configurations :
      contains(["Enabled", "Disabled"], c.status)
    ])
    error_message = "intelligent_tiering_configurations[*].status must be Enabled or Disabled."
  }

  validation {
    condition = alltrue([
      for k, c in var.intelligent_tiering_configurations : alltrue([
        for t in c.tiering :
        contains(["ARCHIVE_ACCESS", "DEEP_ARCHIVE_ACCESS"], t.access_tier)
      ])
    ])
    error_message = "intelligent_tiering_configurations[*].tiering[*].access_tier must be ARCHIVE_ACCESS or DEEP_ARCHIVE_ACCESS."
  }

  validation {
    condition = alltrue([
      for k, c in var.intelligent_tiering_configurations : alltrue([
        for t in c.tiering :
        (t.access_tier == "ARCHIVE_ACCESS" && t.days >= 90) ||
        (t.access_tier == "DEEP_ARCHIVE_ACCESS" && t.days >= 180)
      ])
    ])
    error_message = "ARCHIVE_ACCESS requires days >= 90; DEEP_ARCHIVE_ACCESS requires days >= 180."
  }
}

# ─────────────────────────────────────────────────────────────
# INVENTORY
# ─────────────────────────────────────────────────────────────

variable "inventory_configurations" {
  description = "S3 Inventory configurations for compliance and auditing."
  type = map(object({
    enabled                  = optional(bool, true)
    included_object_versions = optional(string, "All")    # All | Current
    schedule_frequency       = optional(string, "Weekly") # Daily | Weekly
    destination_bucket_arn   = string
    destination_prefix       = optional(string, null)
    destination_format       = optional(string, "Parquet") # CSV | ORC | Parquet
    destination_account_id   = optional(string, null)
    destination_encryption = optional(object({
      sse_kms = optional(object({ key_id = string }), null)
      sse_s3  = optional(bool, false)
    }), null)
    filter_prefix = optional(string, null)
    optional_fields = optional(list(string), [
      "Size", "LastModifiedDate", "StorageClass", "ETag",
      "IsMultipartUploaded", "ReplicationStatus", "EncryptionStatus",
      "IntelligentTieringAccessTier"
    ])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, c in var.inventory_configurations :
      contains(["All", "Current"], c.included_object_versions)
    ])
    error_message = "inventory_configurations[*].included_object_versions must be All or Current."
  }

  validation {
    condition = alltrue([
      for k, c in var.inventory_configurations :
      contains(["Daily", "Weekly"], c.schedule_frequency)
    ])
    error_message = "inventory_configurations[*].schedule_frequency must be Daily or Weekly."
  }

  validation {
    condition = alltrue([
      for k, c in var.inventory_configurations :
      contains(["CSV", "ORC", "Parquet"], c.destination_format)
    ])
    error_message = "inventory_configurations[*].destination_format must be CSV, ORC, or Parquet."
  }
}

# ─────────────────────────────────────────────────────────────
# METRICS (REQUEST METRICS)
# ─────────────────────────────────────────────────────────────

variable "metrics_configurations" {
  description = "S3 request metrics configurations (CloudWatch). Useful for per-prefix monitoring."
  type = map(object({
    filter_prefix = optional(string, null)
    filter_tags   = optional(map(string), {})
  }))
  default = {}
}

# ─────────────────────────────────────────────────────────────
# ANALYTICS
# ─────────────────────────────────────────────────────────────

variable "analytics_configurations" {
  description = "S3 Storage Class Analysis configurations to identify infrequent access patterns."
  type = map(object({
    filter_prefix = optional(string, null)
    filter_tags   = optional(map(string), {}) # Mapa directo, no lista
    destination = optional(object({
      bucket_arn        = string
      prefix            = optional(string, null)
      bucket_account_id = optional(string, null)
    }), null)
  }))
  default = {}
}

# ─────────────────────────────────────────────────────────────
# TRANSFER ACCELERATION
# ─────────────────────────────────────────────────────────────

variable "transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration (CloudFront edge upload). Incompatible with bucket names containing dots."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────────────────────────
# REQUESTER PAYS
# ─────────────────────────────────────────────────────────────

variable "requester_pays" {
  description = "Enable Requester Pays (data transfer costs charged to the requester, not bucket owner)."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────────────────────────
# OWNERSHIP CONTROLS / GRANT (legacy ACL support)
# ─────────────────────────────────────────────────────────────

variable "grants" {
  description = <<-EOT
    ACL grants for legacy workflows. Only valid when object_ownership = ObjectWriter or BucketOwnerPreferred.
    type: CanonicalUser | AmazonCustomerByEmail | Group
    permissions: READ | WRITE | READ_ACP | WRITE_ACP | FULL_CONTROL
  EOT
  type = list(object({
    id          = optional(string, null)
    type        = string
    permissions = list(string)
    uri         = optional(string, null)
  }))
  default = []

  validation {
    condition = alltrue([
      for g in var.grants :
      contains(["CanonicalUser", "AmazonCustomerByEmail", "Group"], g.type)
    ])
    error_message = "grants[*].type must be: CanonicalUser, AmazonCustomerByEmail, or Group."
  }

  validation {
    condition = alltrue([
      for g in var.grants : alltrue([
        for p in g.permissions :
        contains(["READ", "WRITE", "READ_ACP", "WRITE_ACP", "FULL_CONTROL"], p)
      ])
    ])
    error_message = "grants[*].permissions must be: READ, WRITE, READ_ACP, WRITE_ACP, or FULL_CONTROL."
  }
}

# ─────────────────────────────────────────────────────────────
# TIMEOUTS
# ─────────────────────────────────────────────────────────────

variable "timeouts" {
  description = "Custom resource timeouts."
  type = object({
    create = optional(string, "20m")
    read   = optional(string, "20m")
    update = optional(string, "20m")
    delete = optional(string, "60m")
  })
  default = {}
}
