# ============================================================
# main.tf — terraform-aws-efs module
# ============================================================

locals {
  # ── Tags ──────────────────────────────────────────────────
  common_tags = merge(
    {
      Name        = var.name
      ManagedBy   = "terraform"
      Environment = var.environment
    },
    var.tags
  )

  # ── Security group resolution ────────────────────────────
  # The SG used per mount target: per-MT override → module-managed SG → var.security_group_ids
  managed_sg_id = var.create_security_group ? [aws_security_group.this[0].id] : []

  default_sg_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : local.managed_sg_id

  # Per-mount-target effective SG list
  mount_target_sg_ids = {
    for k, mt in var.mount_targets :
    k => length(mt.security_group_ids) > 0 ? mt.security_group_ids : local.default_sg_ids
  }

  # ── Policy composition ────────────────────────────────────
  # Merge managed TLS-deny policy with optional user-supplied policy.
  # If var.file_system_policy is set, it takes full ownership.
  # attach_tls_deny = var.attach_deny_non_tls_policy || var.attach_deny_non_secure_transport_policy

  create_policy = var.file_system_policy != null || var.attach_deny_non_tls_policy || var.attach_deny_non_secure_transport_policy
  # final_policy = var.file_system_policy != null ? var.file_system_policy : (
  #   local.create_policy ? data.aws_iam_policy_document.deny_non_tls[0].json : null
  # )

  # ── Lifecycle policy blocks ───────────────────────────────
  # Build only the blocks that are non-null to avoid empty blocks in state
  lifecycle_policies = compact([
    var.lifecycle_policy.transition_to_ia != null ? "transition_to_ia" : null,
    var.lifecycle_policy.transition_to_primary != null ? "transition_to_primary" : null,
    var.lifecycle_policy.transition_to_archive != null ? "transition_to_archive" : null,
  ])
}

# ─────────────────────────────────────────────────────────────
# DATA SOURCES
# ─────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# ─────────────────────────────────────────────────────────────
# MANAGED POLICY — DENY NON-TLS
# ─────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "deny_non_tls" {
  count = var.attach_deny_non_tls_policy || var.attach_deny_non_secure_transport_policy ? 1 : 0

  statement {
    sid    = "DenyNonTLSConnections"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["elasticfilesystem:*"]

    resources = [aws_efs_file_system.this.arn]

    # resources = [
    #   "arn:${data.aws_partition.current.partition}:elasticfilesystem:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:file-system/*"
    # ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ─────────────────────────────────────────────────────────────
# MANAGED SECURITY GROUP
# ─────────────────────────────────────────────────────────────

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = coalesce(var.security_group_name, "${var.name}-efs-sg")
  description = var.security_group_description
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    var.security_group_tags,
    { Name = coalesce(var.security_group_name, "${var.name}-efs-sg") }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for k, r in var.security_group_rules :
    k => r if var.create_security_group && r.type == "ingress"
  }

  security_group_id = aws_security_group.this[0].id
  description       = each.value.description
  from_port         = each.value.protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.protocol

  cidr_ipv4                    = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = each.value.source_security_group_id

  tags = merge(local.common_tags, { Rule = each.key })
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for k, r in var.security_group_rules :
    k => r if var.create_security_group && r.type == "egress"
  }

  security_group_id = aws_security_group.this[0].id
  description       = each.value.description
  from_port         = each.value.protocol == "-1" ? null : each.value.from_port
  to_port           = each.value.protocol == "-1" ? null : each.value.to_port
  ip_protocol       = each.value.protocol

  cidr_ipv4                    = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks[0] : null
  cidr_ipv6                    = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks[0] : null
  referenced_security_group_id = each.value.source_security_group_id

  tags = merge(local.common_tags, { Rule = each.key })
}

# ─────────────────────────────────────────────────────────────
# EFS FILE SYSTEM
# ─────────────────────────────────────────────────────────────

resource "aws_efs_file_system" "this" {
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null
  encrypted                       = var.encrypted
  kms_key_id                      = var.encrypted ? var.kms_key_id : null
  availability_zone_name          = var.availability_zone_name

  tags = merge(local.common_tags, { Name = var.name })

  # ── Lifecycle policies ────────────────────────────────────
  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_ia != null ? [var.lifecycle_policy.transition_to_ia] : []
    content {
      transition_to_ia = lifecycle_policy.value
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_primary != null ? [var.lifecycle_policy.transition_to_primary] : []
    content {
      transition_to_primary_storage_class = lifecycle_policy.value
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy.transition_to_archive != null ? [var.lifecycle_policy.transition_to_archive] : []
    content {
      transition_to_archive = lifecycle_policy.value
    }
  }

  # ── Protection ────────────────────────────────────────────
  protection {
    replication_overwrite = var.protection.replication_overwrite
  }

  # timeouts {
  #   create = var.timeouts.create
  #   update = var.timeouts.update
  #   delete = var.timeouts.delete
  # }

  lifecycle {
    # Performance mode and One Zone AZ cannot change post-creation
    # Timeouts deben ir aquí para aws_efs_file_system
    # PERO: aws_efs_file_system NO soporta timeouts en lifecycle
    precondition {
      condition     = !(var.throughput_mode == "provisioned" && var.provisioned_throughput_in_mibps == null)
      error_message = "provisioned_throughput_in_mibps must be set when throughput_mode = 'provisioned'."
    }

    precondition {
      condition     = !(var.throughput_mode != "provisioned" && var.provisioned_throughput_in_mibps != null)
      error_message = "provisioned_throughput_in_mibps must be null when throughput_mode is not 'provisioned'."
    }

    precondition {
      condition     = !(var.performance_mode == "maxIO" && var.throughput_mode == "elastic")
      error_message = "maxIO performance mode is incompatible with elastic throughput mode. Use 'bursting' or 'provisioned' instead."
    }

    precondition {
      condition     = !(!var.encrypted && var.kms_key_id != null)
      error_message = "kms_key_id can only be set when encrypted = true."
    }

    precondition {
      condition = var.availability_zone_name == null || (
        length(var.mount_targets) == 0 || alltrue([
          for k, mt in var.mount_targets : true # validated externally; single-AZ buckets should use 1 MT
        ])
      )
      error_message = "One Zone EFS (availability_zone_name set) should use mount targets only in that AZ."
    }

    ignore_changes = [
      # performance_mode and availability_zone_name are immutable post-creation
      performance_mode,
      availability_zone_name,
    ]
  }
}

# ─────────────────────────────────────────────────────────────
# FILE SYSTEM POLICY
# ─────────────────────────────────────────────────────────────

resource "aws_efs_file_system_policy" "this" {
  count = local.create_policy ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  # policy                             = local.final_policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
  policy = var.file_system_policy != null ? var.file_system_policy : (
    length(data.aws_iam_policy_document.deny_non_tls) > 0 ? data.aws_iam_policy_document.deny_non_tls[0].json : null
  )
}

# ─────────────────────────────────────────────────────────────
# MOUNT TARGETS
# ─────────────────────────────────────────────────────────────

resource "aws_efs_mount_target" "this" {
  for_each = var.mount_targets

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value.subnet_id
  security_groups = local.mount_target_sg_ids[each.key]
  ip_address      = each.value.ip_address

  lifecycle {
    precondition {
      condition     = length(local.mount_target_sg_ids[each.key]) > 0
      error_message = "Mount target '${each.key}' has no security groups. Set security_group_ids on the mount target, var.security_group_ids, or enable create_security_group = true."
    }
  }
}

# ─────────────────────────────────────────────────────────────
# ACCESS POINTS
# ─────────────────────────────────────────────────────────────

resource "aws_efs_access_point" "this" {
  for_each = var.access_points

  file_system_id = aws_efs_file_system.this.id
  # client_token eliminado - no es soportado por este recurso
  # client_token   = coalesce(each.value.client_token, each.key)

  tags = merge(
    local.common_tags,
    var.access_point_tags,
    each.value.tags,
    { Name = coalesce(each.value.name, "${var.name}-${each.key}") }
  )

  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_gid   = creation_info.value.owner_gid
          owner_uid   = creation_info.value.owner_uid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      gid            = posix_user.value.gid
      uid            = posix_user.value.uid
      secondary_gids = posix_user.value.secondary_gids
    }
  }
}

# ─────────────────────────────────────────────────────────────
# REPLICATION
# ─────────────────────────────────────────────────────────────

resource "aws_efs_replication_configuration" "this" {
  count = var.replication_configuration != null ? 1 : 0

  source_file_system_id = aws_efs_file_system.this.id

  destination {
    region                 = var.replication_configuration.destination.region
    file_system_id         = var.replication_configuration.destination.file_system_id
    availability_zone_name = var.replication_configuration.destination.availability_zone_name
    kms_key_id             = var.replication_configuration.destination.kms_key_id
  }

  lifecycle {
    precondition {
      condition = !(
        var.replication_configuration.destination.file_system_id != null &&
        var.replication_configuration.destination.availability_zone_name != null
      )
      error_message = "replication_configuration.destination: file_system_id and availability_zone_name are mutually exclusive."
    }
  }
}

# ─────────────────────────────────────────────────────────────
# BACKUP — AWS BACKUP INTEGRATION
# ─────────────────────────────────────────────────────────────

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}
