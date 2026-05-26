# ============================================================
# examples/multi-az-ha/main.tf
#
# High-availability EFS for big data / media processing:
#   - maxIO performance mode (highly parallel workloads)
#   - Provisioned throughput (predictable, not size-dependent)
#   - Cross-region replication to DR region
#   - Deep archive lifecycle: IA → Archive progression
#   - Static IPs on mount targets (avoids DNS dependency)
#   - Custom resource-based policy (restrict to specific IAM roles)
#   - Protection: replication_overwrite ENABLED (read-only destination)
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.34.0" }
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

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ── Custom EFS resource policy ─────────────────────────────

data "aws_iam_policy_document" "efs_policy" {
  # Allow only specific IAM roles to mount
  statement {
    sid    = "AllowAuthorizedRoles"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.data_processing_role_name}",
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.platform_admin_role_name}",
      ]
    }
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }

  # Deny all non-TLS connections
  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"
    principals { type = "AWS"; identifiers = ["*"] }
    actions   = ["elasticfilesystem:*"]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ── EFS module ────────────────────────────────────────────

module "efs_ha" {
  source = "../../modules/efs"

  providers = { aws = aws.primary }

  name        = "bsol-bigdata-efs"
  environment = var.environment

  # maxIO for highly parallel HPC/data processing workloads
  # NOTE: maxIO is incompatible with elastic throughput
  performance_mode                = "maxIO"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = var.provisioned_throughput_mibps  # e.g. 500

  encrypted  = true
  kms_key_id = var.kms_key_arn

  # Deep archival lifecycle for large media/data files
  lifecycle_policy = {
    transition_to_ia      = "AFTER_14_DAYS"   # aggressive IA transition
    transition_to_primary = "AFTER_1_ACCESS"  # hot data comes back fast
    transition_to_archive = "AFTER_90_DAYS"   # deep archive after 90d in IA
  }

  # Replication overwrite protection (destination is read-only)
  protection = {
    replication_overwrite = "ENABLED"
  }

  vpc_id = var.vpc_id

  # Bring own SGs (pre-created with strict rules for data processing SGs)
  create_security_group = false
  security_group_ids    = var.efs_security_group_ids

  # Static IPs on mount targets — avoids DNS, useful for /etc/fstab in HPC
  mount_targets = {
    az1 = {
      subnet_id  = var.data_subnet_az1
      ip_address = var.efs_ip_az1  # e.g. "10.0.1.100"
    }
    az2 = {
      subnet_id  = var.data_subnet_az2
      ip_address = var.efs_ip_az2
    }
    az3 = {
      subnet_id  = var.data_subnet_az3
      ip_address = var.efs_ip_az3
    }
  }

  # Access point for data processing jobs (enforced GID for group writes)
  access_points = {
    data_processing = {
      root_directory = {
        path = "/processing"
        creation_info = {
          owner_uid   = 5000
          owner_gid   = 5000
          permissions = "0770"
        }
      }
      posix_user = {
        uid            = 5000
        gid            = 5000
        secondary_gids = [5001]
      }
    }
    staging = {
      root_directory = {
        path = "/staging"
        creation_info = {
          owner_uid   = 5000
          owner_gid   = 5000
          permissions = "0777"  # wide open staging area
        }
      }
    }
  }

  # Cross-region replication to DR
  replication_configuration = {
    destination = {
      region     = var.dr_region
      kms_key_id = var.dr_kms_key_arn
    }
  }

  # Use custom policy (handles TLS deny internally)
  file_system_policy                     = data.aws_iam_policy_document.efs_policy.json
  attach_deny_non_tls_policy             = false  # already in custom policy
  bypass_policy_lockout_safety_check     = false

  enable_backup = true

  tags = {
    Project      = "bsol-bigdata"
    Owner        = "data-platform"
    CostCenter   = "data"
    Replication  = "enabled"
    DataClass    = "confidential"
  }
}

# ── Variables ──────────────────────────────────────────────

variable "primary_region"               { type = string; default = "us-east-1" }
variable "dr_region"                    { type = string; default = "us-west-2" }
variable "environment"                  { type = string; default = "prod" }
variable "vpc_id"                       { type = string }
variable "data_subnet_az1"              { type = string }
variable "data_subnet_az2"              { type = string }
variable "data_subnet_az3"              { type = string }
variable "efs_ip_az1"                   { type = string }
variable "efs_ip_az2"                   { type = string }
variable "efs_ip_az3"                   { type = string }
variable "efs_security_group_ids"       { type = list(string) }
variable "kms_key_arn"                  { type = string }
variable "dr_kms_key_arn"               { type = string }
variable "provisioned_throughput_mibps" { type = number; default = 500 }
variable "data_processing_role_name"    { type = string }
variable "platform_admin_role_name"     { type = string }

# ── Outputs ────────────────────────────────────────────────

output "file_system_id"          { value = module.efs_ha.file_system_id }
output "file_system_arn"         { value = module.efs_ha.file_system_arn }
output "mount_target_ips"        { value = module.efs_ha.mount_target_ips }
output "dr_file_system_id"       { value = module.efs_ha.replication_destination_file_system_id }
output "dr_region"               { value = module.efs_ha.replication_destination_region }
output "access_point_ids"        { value = module.efs_ha.access_point_ids }
output "fstab_entry"             { value = module.efs_ha.fstab_entry }
