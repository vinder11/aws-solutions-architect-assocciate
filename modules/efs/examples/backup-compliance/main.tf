# ============================================================
# examples/backup-compliance/main.tf
#
# Cost-optimized One Zone EFS for backup staging with:
#   - One Zone storage class (single AZ, ~47% cheaper)
#   - DSSE-equivalent: SSE-KMS with customer-managed key
#   - Aggressive lifecycle: IA → Archive progression
#   - Cross-account access via resource-based policy
#   - Access point with strict POSIX enforcement for backup agent
#   - Deny root access for non-admin principals
#   - Custom SG: allow NFS only from specific CIDR (backup agent subnet)
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.34.0" }
  }
}

provider "aws" { region = var.aws_region }

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ── Resource policy: cross-account + deny root + deny non-TLS

data "aws_iam_policy_document" "backup_policy" {
  # Allow backup agent role from secondary account to mount
  statement {
    sid    = "CrossAccountBackupMount"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.backup_account_id}:role/${var.backup_agent_role_name}"]
    }
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }

  # Allow same-account platform role with root access
  statement {
    sid    = "AllowPlatformAdmin"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.platform_admin_role_name}"]
    }
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = ["*"]
  }

  # Deny root access for cross-account principals
  statement {
    sid    = "DenyRootAccessCrossAccount"
    effect = "Deny"
    principals { type = "AWS"; identifiers = ["*"] }
    actions   = ["elasticfilesystem:ClientRootAccess"]
    resources = ["*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Deny all non-TLS
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

module "efs_backup" {
  source = "../../modules/efs"

  name        = "bsol-backup-staging"
  environment = var.environment

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  encrypted  = true
  kms_key_id = var.kms_key_arn

  # One Zone: significantly cheaper for backup staging where HA is not critical
  availability_zone_name = var.availability_zone

  # Aggressive tiering — backup data is written once, rarely read
  lifecycle_policy = {
    transition_to_ia      = "AFTER_7_DAYS"
    transition_to_primary = null              # no automatic restore (cost control)
    transition_to_archive = "AFTER_180_DAYS" # archive after 6 months in IA
  }

  vpc_id = var.vpc_id

  create_security_group      = true
  security_group_description = "EFS backup staging — NFS from backup subnet only"

  security_group_rules = {
    nfs_from_backup_subnet = {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS from backup agent subnet"
      cidr_blocks = [var.backup_agent_cidr]
    }
    nfs_from_backup_account_vpc = {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS from cross-account backup VPC via VPC Peering/TGW"
      cidr_blocks = [var.backup_account_cidr]
    }
    all_egress = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Single mount target in the One Zone AZ
  mount_targets = {
    backup_az = { subnet_id = var.backup_subnet_id }
  }

  # Access point for backup agent — restricted POSIX user
  access_points = {
    backup_agent = {
      root_directory = {
        path = "/backups"
        creation_info = {
          owner_uid   = 999    # backup agent UID
          owner_gid   = 999
          permissions = "0750"
        }
      }
      posix_user = {
        uid = 999
        gid = 999
      }
      tags = { Purpose = "backup-agent" }
    }
  }

  # Custom policy handles TLS deny — don't attach managed policy too
  file_system_policy         = data.aws_iam_policy_document.backup_policy.json
  attach_deny_non_tls_policy = false

  enable_backup = true  # Backup of the backup staging (meta-protection)

  # Protect destination replication overwrite
  protection = { replication_overwrite = "DISABLED" }

  tags = {
    Project      = "bsol-backup"
    Owner        = "platform-engineering"
    CostCenter   = "infra"
    StorageClass = "one-zone"
    Compliance   = "backup-staging"
  }
}

# ── Variables ──────────────────────────────────────────────

variable "aws_region"               { type = string; default = "us-east-1" }
variable "environment"              { type = string; default = "prod" }
variable "vpc_id"                   { type = string }
variable "availability_zone"        { type = string; default = "us-east-1a" }
variable "backup_subnet_id"         { type = string }
variable "kms_key_arn"              { type = string }
variable "backup_agent_cidr"        { type = string }
variable "backup_account_cidr"      { type = string }
variable "backup_account_id"        { type = string }
variable "backup_agent_role_name"   { type = string }
variable "platform_admin_role_name" { type = string }

# ── Outputs ────────────────────────────────────────────────

output "file_system_id"          { value = module.efs_backup.file_system_id }
output "file_system_dns_name"    { value = module.efs_backup.file_system_dns_name }
output "access_point_ids"        { value = module.efs_backup.access_point_ids }
output "access_point_arns"       { value = module.efs_backup.access_point_arns }
output "mount_target_ips"        { value = module.efs_backup.mount_target_ips }
output "security_group_id"       { value = module.efs_backup.security_group_id }
output "efs_utils_mount_command" { value = module.efs_backup.efs_utils_mount_command }
