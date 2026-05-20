# ============================================================
# main.tf — terraform-aws-s3 module
# ============================================================

locals {
  # ── Name resolution ──────────────────────────────────────────
  # bucket_name wins over bucket_prefix (only one should be set)
  bucket_name   = var.bucket_name
  bucket_prefix = var.bucket_name == null ? var.bucket_prefix : null
  bucket_arn    = "arn:${data.aws_partition.current.partition}:s3:::${var.bucket_name}"

  # ── Tag merging ───────────────────────────────────────────────
  common_tags = merge(
    {
      ManagedBy   = "terraform"
      Environment = var.environment
    },
    var.tags
  )

  # ── Policy composition ────────────────────────────────────────
  # Merge built-in managed policies with any user-supplied policy.
  # All built-in statements are assembled here and merged via
  # aws_iam_policy_document data source, then overridden by
  # var.bucket_policy if provided (var.bucket_policy takes full ownership).
  attach_any_managed_policy = (
    var.attach_deny_insecure_transport_policy ||
    var.attach_deny_unencrypted_object_uploads ||
    var.attach_require_latest_tls_policy ||
    var.attach_inventory_destination_policy
  )

  final_policy = var.bucket_policy != null ? var.bucket_policy : (
    local.attach_any_managed_policy
    ? data.aws_iam_policy_document.combined[0].json
    : null
  )
}

# ─────────────────────────────────────────────────────────────
# CURRENT CALLER IDENTITY (for managed policies)
# ─────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ─────────────────────────────────────────────────────────────
# MANAGED POLICY DOCUMENTS
# ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "deny_insecure_transport" {
  count = var.attach_deny_insecure_transport_policy ? 1 : 0

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      local.bucket_arn,        # ← Cambiado de aws_s3_bucket.this.arn
      "${local.bucket_arn}/*", # ← Cambiado
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "deny_unencrypted_uploads" {
  count = var.attach_deny_unencrypted_object_uploads ? 1 : 0

  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"] # ← Cambiado
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "require_latest_tls" {
  count = var.attach_require_latest_tls_policy ? 1 : 0

  statement {
    sid     = "DenyOutdatedTLS"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      local.bucket_arn,        # ← Cambiado
      "${local.bucket_arn}/*", # ← Cambiado
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }
}

data "aws_iam_policy_document" "inventory_destination" {
  count = var.attach_inventory_destination_policy ? 1 : 0

  statement {
    sid       = "InventoryPolicy"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.bucket_arn}/*"] # ← Cambiado
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:s3:::*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# Merge all managed policy statements
data "aws_iam_policy_document" "combined" {
  count = local.attach_any_managed_policy && var.bucket_policy == null ? 1 : 0

  source_policy_documents = compact([
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[0].json : null,
    var.attach_deny_unencrypted_object_uploads ? data.aws_iam_policy_document.deny_unencrypted_uploads[0].json : null,
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : null,
    var.attach_inventory_destination_policy ? data.aws_iam_policy_document.inventory_destination[0].json : null,
  ])
}

# ─────────────────────────────────────────────────────────────
# S3 BUCKET (core resource)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  bucket_prefix = local.bucket_prefix
  force_destroy = var.force_destroy

  object_lock_enabled = var.object_lock_enabled

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = var.bucket_name != null || var.bucket_prefix != null
      error_message = "Either bucket_name or bucket_prefix must be provided."
    }
    precondition {
      condition     = !(var.bucket_name != null && var.bucket_prefix != null)
      error_message = "bucket_name and bucket_prefix are mutually exclusive. Provide only one."
    }
    precondition {
      condition     = !var.transfer_acceleration || (var.bucket_name == null || !can(regex("\\.", var.bucket_name)))
      error_message = "Transfer Acceleration is incompatible with bucket names that contain dots."
    }
    precondition {
      condition     = !var.versioning.mfa_delete || var.versioning.enabled
      error_message = "MFA Delete requires versioning to be enabled."
    }
    precondition {
      condition     = var.object_lock_configuration == null || var.object_lock_enabled
      error_message = "object_lock_configuration requires object_lock_enabled = true on the bucket."
    }
    precondition {
      condition     = var.replication_configuration == null || var.versioning.enabled
      error_message = "Replication requires versioning to be enabled on the source bucket."
    }
    precondition {
      condition     = var.acl == null || var.object_ownership != "BucketOwnerEnforced"
      error_message = "ACL cannot be set when object_ownership = BucketOwnerEnforced (ACLs are disabled)."
    }
  }

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

# ─────────────────────────────────────────────────────────────
# OWNERSHIP CONTROLS
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

# ─────────────────────────────────────────────────────────────
# PUBLIC ACCESS BLOCK
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets

  # Must wait for ownership controls to be applied first
  depends_on = [aws_s3_bucket_ownership_controls.this]
}

# ─────────────────────────────────────────────────────────────
# ACL (only when not BucketOwnerEnforced)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_acl" "this" {
  count = var.acl != null && var.object_ownership != "BucketOwnerEnforced" ? 1 : 0

  bucket = aws_s3_bucket.this.id
  acl    = var.acl

  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this,
  ]
}

# ─────────────────────────────────────────────────────────────
# LEGACY GRANTS (ACL)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_acl" "grants" {
  count = length(var.grants) > 0 && var.object_ownership != "BucketOwnerEnforced" ? 1 : 0

  bucket = aws_s3_bucket.this.id

  access_control_policy {
    dynamic "grant" {
      for_each = var.grants
      content {
        grantee {
          id            = grant.value.type == "CanonicalUser" ? grant.value.id : null
          type          = grant.value.type
          uri           = grant.value.type == "Group" ? grant.value.uri : null
          email_address = grant.value.type == "AmazonCustomerByEmail" ? grant.value.id : null
        }
        permission = grant.value.permissions[0]
      }
    }
    owner {
      id = data.aws_caller_identity.current.account_id
    }
  }

  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this,
  ]
}

# ─────────────────────────────────────────────────────────────
# VERSIONING
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = var.versioning.enabled ? "Enabled" : "Suspended"
    mfa_delete = var.versioning.mfa_delete ? "Enabled" : "Disabled"
  }
}

# ─────────────────────────────────────────────────────────────
# SERVER-SIDE ENCRYPTION
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption.sse_algorithm
      kms_master_key_id = var.encryption.kms_key_id
    }
    bucket_key_enabled = contains(["aws:kms", "aws:kms:dsse"], var.encryption.sse_algorithm) ? var.encryption.bucket_key_enabled : null
  }
}

# ─────────────────────────────────────────────────────────────
# BUCKET POLICY
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_policy" "this" {
  count = local.final_policy != null ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = local.final_policy

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# ─────────────────────────────────────────────────────────────
# LIFECYCLE RULES
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  # Must wait for versioning to be configured to avoid conflicts
  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # ── Filter ───────────────────────────────────────────────
      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          dynamic "and" {
            for_each = (
              filter.value.prefix != null &&
              (length(filter.value.tags) > 0 ||
                filter.value.object_size_greater_than != null ||
              filter.value.object_size_less_than != null)
            ) ? [filter.value] : []
            content {
              prefix                   = and.value.prefix
              tags                     = and.value.tags
              object_size_greater_than = and.value.object_size_greater_than
              object_size_less_than    = and.value.object_size_less_than
            }
          }
          # Simple prefix-only filter
          prefix = (
            filter.value.prefix != null &&
            length(filter.value.tags) == 0 &&
            filter.value.object_size_greater_than == null &&
            filter.value.object_size_less_than == null
          ) ? filter.value.prefix : null

          # Tags-only filter
          dynamic "tag" {
            for_each = (
              filter.value.prefix == null &&
              length(filter.value.tags) == 1 &&
              filter.value.object_size_greater_than == null &&
              filter.value.object_size_less_than == null
            ) ? filter.value.tags : {}
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      # ── Expiration ────────────────────────────────────────────
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      # ── Transitions ───────────────────────────────────────────
      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      # ── Noncurrent version expiration ─────────────────────────
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days           = noncurrent_version_expiration.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_expiration.value.newer_noncurrent_versions
        }
      }

      # ── Noncurrent version transitions ────────────────────────
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          noncurrent_days           = noncurrent_version_transition.value.noncurrent_days
          newer_noncurrent_versions = noncurrent_version_transition.value.newer_noncurrent_versions
          storage_class             = noncurrent_version_transition.value.storage_class
        }
      }

      # ── Abort incomplete multipart uploads ────────────────────
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days != null ? [rule.value.abort_incomplete_multipart_upload_days] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────
# REPLICATION
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.replication_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.this.id
  role   = var.replication_configuration.role_arn

  depends_on = [aws_s3_bucket_versioning.this]

  dynamic "rule" {
    for_each = var.replication_configuration.rules
    content {
      id       = coalesce(rule.value.id, rule.key)
      status   = rule.value.status
      priority = rule.value.priority

      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          dynamic "and" {
            for_each = (
              filter.value.prefix != null && length(filter.value.tags) > 0
            ) ? [filter.value] : []
            content {
              prefix = and.value.prefix
              tags   = and.value.tags
            }
          }
          prefix = (
            filter.value.prefix != null && length(filter.value.tags) == 0
          ) ? filter.value.prefix : null

          dynamic "tag" {
            for_each = (
              filter.value.prefix == null && length(filter.value.tags) == 1
            ) ? filter.value.tags : {}
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      destination {
        bucket        = rule.value.destination.bucket
        storage_class = rule.value.destination.storage_class
        account       = rule.value.destination.account

        dynamic "encryption_configuration" {
          for_each = rule.value.destination.replica_kms_key_id != null ? [1] : []
          content {
            replica_kms_key_id = rule.value.destination.replica_kms_key_id
          }
        }

        dynamic "access_control_translation" {
          for_each = rule.value.destination.access_control_translation != null ? [rule.value.destination.access_control_translation] : []
          content {
            owner = access_control_translation.value.owner
          }
        }

        dynamic "replication_time" {
          for_each = rule.value.destination.replication_time != null ? [rule.value.destination.replication_time] : []
          content {
            status = replication_time.value.status
            time {
              minutes = replication_time.value.minutes
            }
          }
        }

        dynamic "metrics" {
          for_each = rule.value.destination.metrics != null ? [rule.value.destination.metrics] : []
          content {
            status = metrics.value.status
            event_threshold {
              minutes = metrics.value.minutes
            }
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = rule.value.delete_marker_replication != null ? [rule.value.delete_marker_replication] : []
        content {
          status = delete_marker_replication.value.status
        }
      }

      dynamic "source_selection_criteria" {
        for_each = rule.value.source_selection_criteria != null ? [rule.value.source_selection_criteria] : []
        content {
          dynamic "replica_modifications" {
            for_each = source_selection_criteria.value.replica_modifications != null ? [source_selection_criteria.value.replica_modifications] : []
            content {
              status = replica_modifications.value.status
            }
          }
          dynamic "sse_kms_encrypted_objects" {
            for_each = source_selection_criteria.value.sse_kms_encrypted_objects != null ? [source_selection_criteria.value.sse_kms_encrypted_objects] : []
            content {
              status = sse_kms_encrypted_objects.value.status
            }
          }
        }
      }

      dynamic "existing_object_replication" {
        for_each = rule.value.existing_object_replication != null ? [rule.value.existing_object_replication] : []
        content {
          status = existing_object_replication.value.status
        }
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────
# OBJECT LOCK CONFIGURATION (WORM)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.object_lock_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = var.object_lock_configuration.rule.default_retention.mode
      days  = var.object_lock_configuration.rule.default_retention.days
      years = var.object_lock_configuration.rule.default_retention.years
    }
  }
}

# ─────────────────────────────────────────────────────────────
# CORS
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      id              = cors_rule.value.id
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# ─────────────────────────────────────────────────────────────
# STATIC WEBSITE
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.website != null ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "index_document" {
    for_each = var.website.index_document != null ? [var.website.index_document] : []
    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = var.website.error_document != null ? [var.website.error_document] : []
    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.website.redirect_all_requests_to != null ? [var.website.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = redirect_all_requests_to.value.protocol
    }
  }

  dynamic "routing_rule" {
    for_each = var.website.routing_rules != null ? jsondecode(var.website.routing_rules) : []
    content {
      dynamic "condition" {
        for_each = lookup(routing_rule.value, "Condition", null) != null ? [routing_rule.value.Condition] : []
        content {
          http_error_code_returned_equals = lookup(condition.value, "HttpErrorCodeReturnedEquals", null)
          key_prefix_equals               = lookup(condition.value, "KeyPrefixEquals", null)
        }
      }
      redirect {
        host_name               = lookup(routing_rule.value.Redirect, "HostName", null)
        http_redirect_code      = lookup(routing_rule.value.Redirect, "HttpRedirectCode", null)
        protocol                = lookup(routing_rule.value.Redirect, "Protocol", null)
        replace_key_prefix_with = lookup(routing_rule.value.Redirect, "ReplaceKeyPrefixWith", null)
        replace_key_with        = lookup(routing_rule.value.Redirect, "ReplaceKeyWith", null)
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_logging" "this" {
  count = var.logging != null ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.logging.target_bucket
  target_prefix = var.logging.target_prefix

  dynamic "target_object_key_format" {
    for_each = var.logging.target_object_key_format != null ? [var.logging.target_object_key_format] : []
    content {
      dynamic "partitioned_prefix" {
        for_each = target_object_key_format.value.partitioned_prefix != null ? [target_object_key_format.value.partitioned_prefix] : []
        content {
          partition_date_source = partitioned_prefix.value.partition_date_source
        }
      }
      dynamic "simple_prefix" {
        for_each = (target_object_key_format.value.simple_prefix == true &&
        target_object_key_format.value.partitioned_prefix == null) ? [1] : []
        content {}
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────
# NOTIFICATIONS
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_notification" "this" {
  count = var.notifications != null ? 1 : 0

  bucket      = aws_s3_bucket.this.id
  eventbridge = var.notifications.eventbridge

  dynamic "lambda_function" {
    for_each = var.notifications.lambda_functions != null ? var.notifications.lambda_functions : {}
    content {
      id                  = lambda_function.key
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "queue" {
    for_each = var.notifications.queues != null ? var.notifications.queues : {}
    content {
      id            = queue.key
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = var.notifications.topics != null ? var.notifications.topics : {}
    content {
      id            = topic.key
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }
}

# ─────────────────────────────────────────────────────────────
# INTELLIGENT-TIERING CONFIGURATIONS
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  for_each = var.intelligent_tiering_configurations

  bucket = aws_s3_bucket.this.id
  name   = each.key
  status = each.value.status

  dynamic "filter" {
    for_each = each.value.filter != null ? [each.value.filter] : []
    content {
      prefix = filter.value.prefix
      # Tags como atributo directo (mapa), NO como dynamic block
      tags = filter.value.tags
    }
  }

  dynamic "tiering" {
    for_each = each.value.tiering
    content {
      access_tier = tiering.value.access_tier
      days        = tiering.value.days
    }
  }
}

# ─────────────────────────────────────────────────────────────
# INVENTORY CONFIGURATIONS
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_inventory" "this" {
  for_each = var.inventory_configurations

  bucket  = aws_s3_bucket.this.id
  name    = each.key
  enabled = each.value.enabled

  included_object_versions = each.value.included_object_versions

  schedule {
    frequency = each.value.schedule_frequency
  }

  destination {
    bucket {
      bucket_arn = each.value.destination_bucket_arn
      prefix     = each.value.destination_prefix
      format     = each.value.destination_format
      account_id = each.value.destination_account_id

      dynamic "encryption" {
        for_each = each.value.destination_encryption != null ? [each.value.destination_encryption] : []
        content {
          dynamic "sse_kms" {
            for_each = encryption.value.sse_kms != null ? [encryption.value.sse_kms] : []
            content {
              key_id = sse_kms.value.key_id
            }
          }
          dynamic "sse_s3" {
            for_each = (encryption.value.sse_s3 == true && encryption.value.sse_kms == null) ? [1] : []
            content {}
          }
        }
      }
    }
  }

  dynamic "filter" {
    for_each = each.value.filter_prefix != null ? [each.value.filter_prefix] : []
    content {
      prefix = filter.value
    }
  }

  optional_fields = each.value.optional_fields
}

# ─────────────────────────────────────────────────────────────
# METRICS (REQUEST METRICS)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_metric" "this" {
  for_each = var.metrics_configurations

  bucket = aws_s3_bucket.this.id
  name   = each.key

  dynamic "filter" {
    for_each = (each.value.filter_prefix != null || length(each.value.filter_tags) > 0) ? [1] : []
    content {
      prefix = each.value.filter_prefix
      tags   = each.value.filter_tags
    }
  }
}

# ─────────────────────────────────────────────────────────────
# ANALYTICS (STORAGE CLASS ANALYSIS)
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_analytics_configuration" "this" {
  for_each = var.analytics_configurations

  bucket = aws_s3_bucket.this.id
  name   = each.key

  dynamic "filter" {
    for_each = (each.value.filter_prefix != null || length(each.value.filter_tags) > 0) ? [1] : []
    content {
      prefix = each.value.filter_prefix
      # Tags como atributo mapa, NO como dynamic block
      tags = each.value.filter_tags
    }
  }

  dynamic "storage_class_analysis" {
    for_each = each.value.destination != null ? [each.value.destination] : []
    content {
      data_export {
        destination {
          s3_bucket_destination {
            bucket_arn        = storage_class_analysis.value.bucket_arn
            prefix            = storage_class_analysis.value.prefix
            bucket_account_id = storage_class_analysis.value.bucket_account_id
          }
        }
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────
# TRANSFER ACCELERATION
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_accelerate_configuration" "this" {
  count = var.transfer_acceleration ? 1 : 0

  bucket = aws_s3_bucket.this.id
  status = "Enabled"
}

# ─────────────────────────────────────────────────────────────
# REQUESTER PAYS
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket_request_payment_configuration" "this" {
  count = var.requester_pays ? 1 : 0

  bucket = aws_s3_bucket.this.id
  payer  = "Requester"
}
