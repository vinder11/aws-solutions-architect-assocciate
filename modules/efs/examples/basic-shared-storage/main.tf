# ============================================================
# examples/basic-shared-storage/main.tf
#
# Classic shared NFS storage for:
#   - Multi-AZ high availability (3 mount targets)
#   - Elastic throughput (recommended default)
#   - SSE-KMS encryption
#   - Intelligent-Tiering: IA after 30 days, back on access
#   - Managed security group: allow NFS from app SG
#   - AWS Backup enabled
#   - Deny non-TLS policy
# Use case: shared home directories, CMS uploads, config files
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.34.0" }
  }
}

provider "aws" { region = var.aws_region }

# ── Module call ────────────────────────────────────────────

module "efs" {
  source = "../../modules/efs"

  name        = "bsol-shared-storage"
  environment = "prod"

  # ── Performance ──────────────────────────────────────────
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  # ── Encryption ───────────────────────────────────────────
  encrypted  = true
  kms_key_id = var.kms_key_arn

  # ── Intelligent-Tiering lifecycle ────────────────────────
  lifecycle_policy = {
    transition_to_ia      = "AFTER_30_DAYS"   # move cold files to IA after 30 days
    transition_to_primary = "AFTER_1_ACCESS"  # move back to Standard on access
    transition_to_archive = null              # no deep archival for this workload
  }

  # ── VPC & security ───────────────────────────────────────
  vpc_id = var.vpc_id

  # Module-managed SG: allow NFS from application security group
  create_security_group      = true
  security_group_description = "EFS NFS access for bsol-shared-storage"

  security_group_rules = {
    nfs_from_app = {
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "NFS from application servers"
      source_security_group_id = var.app_security_group_id
    }
    nfs_from_bastion = {
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "NFS from bastion"
      source_security_group_id = var.bastion_security_group_id
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

  # ── Mount targets — one per AZ ────────────────────────────
  mount_targets = {
    az1 = { subnet_id = var.private_subnet_az1 }
    az2 = { subnet_id = var.private_subnet_az2 }
    az3 = { subnet_id = var.private_subnet_az3 }
  }

  # ── Backup ───────────────────────────────────────────────
  enable_backup = true

  # ── Policies ─────────────────────────────────────────────
  attach_deny_non_tls_policy = true

  tags = {
    Project    = "bsol-platform"
    Owner      = "platform-engineering"
    CostCenter = "infra"
  }
}

# ── Variables ──────────────────────────────────────────────

variable "aws_region"               { type = string; default = "us-east-1" }
variable "vpc_id"                   { type = string }
variable "private_subnet_az1"       { type = string }
variable "private_subnet_az2"       { type = string }
variable "private_subnet_az3"       { type = string }
variable "kms_key_arn"              { type = string }
variable "app_security_group_id"    { type = string }
variable "bastion_security_group_id" { type = string }

# ── Outputs ────────────────────────────────────────────────

output "file_system_id"       { value = module.efs.file_system_id }
output "file_system_dns_name" { value = module.efs.file_system_dns_name }
output "mount_target_ips"     { value = module.efs.mount_target_ips }
output "security_group_id"    { value = module.efs.security_group_id }
output "mount_command"        { value = module.efs.mount_command }
output "fstab_entry"          { value = module.efs.fstab_entry }
