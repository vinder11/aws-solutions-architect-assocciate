# ============================================================
# variables.tf — terraform-aws-efs module
# ============================================================

# ─────────────────────────────────────────────────────────────
# CORE FILE SYSTEM
# ─────────────────────────────────────────────────────────────

variable "name" {
  description = <<-EOT
    Name tag for the EFS file system and all associated resources.
    Used as prefix for child resource names (mount targets, access points, etc).
    Max 64 characters, alphanumeric + hyphens.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.name)) || can(regex("^[a-zA-Z0-9]{1,2}$", var.name))
    error_message = "name must be 1–64 characters, start with a letter, and contain only alphanumerics and hyphens."
  }
}

variable "performance_mode" {
  description = <<-EOT
    EFS performance mode. Choose based on workload:
    - generalPurpose: recommended for latency-sensitive workloads (web serving, CMS, home dirs). Max 35,000 IOPS.
    - maxIO: recommended for highly parallelized workloads (big data, media). Higher latency, unlimited IOPS.
    NOTE: Cannot be changed after file system creation.
  EOT
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "performance_mode must be 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = <<-EOT
    EFS throughput mode:
    - bursting:     scales with file system size. Default for most workloads.
    - provisioned:  fixed throughput independent of size (requires provisioned_throughput_in_mibps).
    - elastic:      automatically scales throughput up/down (recommended for spiky or unpredictable workloads).
  EOT
  type        = string
  default     = "elastic"

  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "throughput_mode must be one of: bursting, provisioned, elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = <<-EOT
    Provisioned throughput in MiB/s. Required when throughput_mode = 'provisioned'.
    Valid range: 1–3414 MiB/s. Charged separately from storage.
  EOT
  type        = number
  default     = null

  validation {
    condition     = var.provisioned_throughput_in_mibps == null || (var.provisioned_throughput_in_mibps >= 1 && var.provisioned_throughput_in_mibps <= 3414)
    error_message = "provisioned_throughput_in_mibps must be between 1 and 3414 MiB/s."
  }
}

variable "encrypted" {
  description = "Enable encryption at rest. Strongly recommended; required for compliance workloads."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = <<-EOT
    KMS key ARN or alias for encryption at rest.
    Null = use the AWS-managed EFS key (alias/aws/elasticfilesystem).
    Only evaluated when encrypted = true.
  EOT
  type        = string
  default     = null

  validation {
    condition = var.kms_key_id == null || (
      can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/[0-9a-f-]{36}$", var.kms_key_id)) ||
      can(regex("^alias/[a-zA-Z0-9/_-]+$", var.kms_key_id))
    )
    error_message = "kms_key_id must be a valid KMS key ARN (arn:aws:kms:...) or alias (alias/...), or null."
  }
}

variable "availability_zone_name" {
  description = <<-EOT
    Availability Zone for One Zone storage class (e.g. 'us-east-1a').
    Set this ONLY for One Zone file systems. Leave null for Regional (Multi-AZ) storage.
    One Zone is up to 47% cheaper but data is stored in a single AZ.
    NOTE: Cannot be changed after creation.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.availability_zone_name == null || can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone_name))
    error_message = "availability_zone_name must be a valid AZ name (e.g. us-east-1a) or null."
  }
}

variable "protection" {
  description = <<-EOT
    Data protection settings.
    replication_overwrite: controls whether a replication destination file system can be written to.
      ENABLED  (default) = blocks overwrite; destination is read-only.
      DISABLED           = allows overwrite; useful for failover testing.
  EOT
  type = object({
    replication_overwrite = optional(string, "ENABLED")
  })
  default = {}

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.protection.replication_overwrite)
    error_message = "protection.replication_overwrite must be 'ENABLED' or 'DISABLED'."
  }
}

# ─────────────────────────────────────────────────────────────
# LIFECYCLE POLICIES
# ─────────────────────────────────────────────────────────────

variable "lifecycle_policy" {
  description = <<-EOT
    EFS Intelligent-Tiering lifecycle policies.

    transition_to_ia: move files not accessed within N days to Infrequent Access (IA) storage.
      Valid: AFTER_7_DAYS | AFTER_14_DAYS | AFTER_30_DAYS | AFTER_60_DAYS | AFTER_90_DAYS |
             AFTER_180_DAYS | AFTER_270_DAYS | AFTER_365_DAYS | null

    transition_to_primary: move files back to Standard storage upon access from IA.
      Valid: AFTER_1_ACCESS | null

    transition_to_archive: move files from IA to Archive storage class.
      Valid: AFTER_90_DAYS | AFTER_180_DAYS | AFTER_270_DAYS | AFTER_365_DAYS |
             AFTER_548_DAYS | AFTER_730_DAYS | null
    NOTE: transition_to_archive requires transition_to_ia to be set.
  EOT
  type = object({
    transition_to_ia      = optional(string, null)
    transition_to_primary = optional(string, null)
    transition_to_archive = optional(string, null)
  })
  default = {}

  validation {
    condition = var.lifecycle_policy.transition_to_ia == null || contains([
      "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS",
      "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS"
    ], var.lifecycle_policy.transition_to_ia)
    error_message = "lifecycle_policy.transition_to_ia must be one of AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS, or null."
  }

  validation {
    condition     = var.lifecycle_policy.transition_to_primary == null || var.lifecycle_policy.transition_to_primary == "AFTER_1_ACCESS"
    error_message = "lifecycle_policy.transition_to_primary must be 'AFTER_1_ACCESS' or null."
  }

  validation {
    condition = var.lifecycle_policy.transition_to_archive == null || contains([
      "AFTER_90_DAYS", "AFTER_180_DAYS", "AFTER_270_DAYS", "AFTER_365_DAYS",
      "AFTER_548_DAYS", "AFTER_730_DAYS"
    ], var.lifecycle_policy.transition_to_archive)
    error_message = "lifecycle_policy.transition_to_archive must be one of AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS, AFTER_548_DAYS, AFTER_730_DAYS, or null."
  }

  validation {
    condition     = var.lifecycle_policy.transition_to_archive == null || var.lifecycle_policy.transition_to_ia != null
    error_message = "lifecycle_policy.transition_to_archive requires transition_to_ia to be set."
  }
}

# ─────────────────────────────────────────────────────────────
# NETWORKING — VPC & MOUNT TARGETS
# ─────────────────────────────────────────────────────────────

variable "vpc_id" {
  description = "ID of the VPC where mount targets will be created."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (e.g. vpc-0abc12345678)."
  }
}

variable "mount_targets" {
  description = <<-EOT
    Map of mount targets to create. Key = logical AZ name (e.g. "az1", "us-east-1a").
    Best practice: one mount target per AZ where clients reside.
    subnet_id: the subnet in which to create the mount target.
    security_group_ids: list of SG IDs attached to this mount target (overrides var.security_group_ids).
    ip_address: optional static IPv4 address within the subnet CIDR.
  EOT
  type = map(object({
    subnet_id          = string
    security_group_ids = optional(list(string), [])
    ip_address         = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, mt in var.mount_targets :
      can(regex("^subnet-[0-9a-f]{8,17}$", mt.subnet_id))
    ])
    error_message = "mount_targets[*].subnet_id must be a valid subnet ID (e.g. subnet-0abc12345678)."
  }

  validation {
    condition = alltrue([
      for k, mt in var.mount_targets :
      alltrue([
        for sg in mt.security_group_ids :
        can(regex("^sg-[0-9a-f]{8,17}$", sg))
      ])
    ])
    error_message = "mount_targets[*].security_group_ids must contain valid SG IDs (e.g. sg-0abc12345678)."
  }

  validation {
    condition = alltrue([
      for k, mt in var.mount_targets :
      mt.ip_address == null || can(regex("^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", mt.ip_address))
    ])
    error_message = "mount_targets[*].ip_address must be a valid IPv4 address or null."
  }
}

variable "security_group_ids" {
  description = <<-EOT
    Default security group IDs attached to ALL mount targets that don't specify their own.
    Must allow inbound NFS (TCP port 2049) from client subnets/SGs.
    At least one SG is required per mount target.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for sg in var.security_group_ids :
      can(regex("^sg-[0-9a-f]{8,17}$", sg))
    ])
    error_message = "security_group_ids must contain valid SG IDs (e.g. sg-0abc12345678)."
  }
}

# ─────────────────────────────────────────────────────────────
# SECURITY GROUP (MANAGED BY MODULE — OPTIONAL)
# ─────────────────────────────────────────────────────────────

variable "create_security_group" {
  description = <<-EOT
    When true, the module creates and manages a Security Group for the EFS mount targets.
    The SG is configured via var.security_group_rules.
    Set false to bring your own SGs via var.security_group_ids / var.mount_targets[*].security_group_ids.
  EOT
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name for the managed security group. Defaults to '{name}-efs-sg' when null."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the managed security group."
  type        = string
  default     = "EFS mount target security group managed by Terraform"
}

variable "security_group_rules" {
  description = <<-EOT
    Ingress and egress rules for the managed security group.
    type: ingress | egress
    protocol: tcp | udp | icmp | -1 (all)
    source_security_group_id: mutually exclusive with cidr_blocks/ipv6_cidr_blocks.
    self: allow traffic from the SG itself (for same-SG clients).
  EOT
  type = map(object({
    type                     = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    description              = optional(string, "")
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    source_security_group_id = optional(string, null)
    self                     = optional(bool, false)
  }))
  default = {
    nfs_ingress = {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS inbound from VPC"
      cidr_blocks = ["10.0.0.0/8"]
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

  validation {
    condition = alltrue([
      for k, r in var.security_group_rules :
      contains(["ingress", "egress"], r.type)
    ])
    error_message = "security_group_rules[*].type must be 'ingress' or 'egress'."
  }

  validation {
    condition = alltrue([
      for k, r in var.security_group_rules :
      r.from_port >= 0 && r.from_port <= 65535
    ])
    error_message = "security_group_rules[*].from_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for k, r in var.security_group_rules :
      r.to_port >= 0 && r.to_port <= 65535
    ])
    error_message = "security_group_rules[*].to_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for k, r in var.security_group_rules :
      r.from_port <= r.to_port
    ])
    error_message = "security_group_rules[*].from_port must be <= to_port."
  }

  validation {
    condition = alltrue([
      for k, r in var.security_group_rules :
      !(r.source_security_group_id != null && length(r.cidr_blocks) > 0)
    ])
    error_message = "security_group_rules: source_security_group_id and cidr_blocks are mutually exclusive per rule."
  }

  validation {
    condition = alltrue([
      for k, r in var.security_group_rules :
      r.source_security_group_id == null ||
      can(regex("^sg-[0-9a-f]{8,17}$", r.source_security_group_id))
    ])
    error_message = "security_group_rules[*].source_security_group_id must be a valid SG ID or null."
  }
}

# ─────────────────────────────────────────────────────────────
# ACCESS POINTS
# ─────────────────────────────────────────────────────────────

variable "access_points" {
  description = <<-EOT
    Map of EFS Access Points. Key = logical name used in outputs.
    Access points enforce a root directory, POSIX user, and creation info,
    enabling multi-tenant access with separate namespaces on a single EFS.

    root_directory.path: absolute path on the EFS (e.g. "/data/app1").
    root_directory.creation_info: POSIX owner/permissions applied when creating the directory.
    posix_user: POSIX UID/GID used for all file operations through this access point.
      Overrides the NFS client's identity. Required for container workloads.
    client_token: idempotency token (defaults to the access point key).
  EOT
  type = map(object({
    name = optional(string, null)
    # client_token = optional(string, null)

    root_directory = optional(object({
      path = optional(string, "/")
      creation_info = optional(object({
        owner_gid   = number
        owner_uid   = number
        permissions = string # octal string, e.g. "0755"
      }), null)
    }), { path = "/" })

    posix_user = optional(object({
      gid            = number
      uid            = number
      secondary_gids = optional(list(number), [])
    }), null)

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, ap in var.access_points :
      ap.root_directory == null ||
      can(regex("^/", ap.root_directory.path))
    ])
    error_message = "access_points[*].root_directory.path must be an absolute path starting with '/'."
  }

  validation {
    condition = alltrue([
      for k, ap in var.access_points :
      ap.root_directory == null ||
      ap.root_directory.creation_info == null ||
      can(regex("^[0-7]{3,4}$", ap.root_directory.creation_info.permissions))
    ])
    error_message = "access_points[*].root_directory.creation_info.permissions must be a 3 or 4-digit octal string (e.g. '0755')."
  }

  validation {
    condition = alltrue([
      for k, ap in var.access_points :
      ap.posix_user == null ||
      (ap.posix_user.uid >= 0 && ap.posix_user.uid <= 4294967295)
    ])
    error_message = "access_points[*].posix_user.uid must be a valid POSIX UID (0–4294967295)."
  }

  validation {
    condition = alltrue([
      for k, ap in var.access_points :
      ap.posix_user == null ||
      (ap.posix_user.gid >= 0 && ap.posix_user.gid <= 4294967295)
    ])
    error_message = "access_points[*].posix_user.gid must be a valid POSIX GID (0–4294967295)."
  }

  validation {
    condition = alltrue([
      for k, ap in var.access_points :
      ap.root_directory == null ||
      ap.root_directory.creation_info == null ||
      (ap.root_directory.creation_info.owner_uid >= 0 && ap.root_directory.creation_info.owner_uid <= 4294967295)
    ])
    error_message = "access_points[*].root_directory.creation_info.owner_uid must be a valid UID (0–4294967295)."
  }
}

# ─────────────────────────────────────────────────────────────
# FILE SYSTEM POLICY
# ─────────────────────────────────────────────────────────────

variable "file_system_policy" {
  description = <<-EOT
    Resource-based IAM policy for the EFS file system (JSON).
    Controls which principals can mount, access, or manage the file system.
    Use aws_iam_policy_document data source and jsonencode() to build.
    Null = no resource policy applied.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.file_system_policy == null || can(jsondecode(var.file_system_policy))
    error_message = "file_system_policy must be valid JSON or null."
  }
}

variable "bypass_policy_lockout_safety_check" {
  description = <<-EOT
    Bypass the policy lockout safety check when updating file_system_policy.
    WARNING: Setting true risks locking yourself out of the file system.
    Only set true if you fully understand the policy being applied.
  EOT
  type        = bool
  default     = false
}

variable "attach_deny_non_tls_policy" {
  description = "Attach a managed policy denying all non-TLS (in-transit unencrypted) connections."
  type        = bool
  default     = true
}

variable "attach_deny_non_secure_transport_policy" {
  description = "Alias for attach_deny_non_tls_policy. Takes precedence if both set."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────────────────────────
# REPLICATION
# ─────────────────────────────────────────────────────────────

variable "replication_configuration" {
  description = <<-EOT
    EFS replication configuration. Creates a destination file system in another region/AZ
    that stays in sync with this (source) file system.

    destination.region: target AWS region. Null = same region as source.
    destination.file_system_id: replicate INTO an existing EFS (must be empty).
      Null = EFS creates a new destination file system automatically.
    destination.availability_zone_name: for One Zone destination (e.g. 'us-west-2a').
    destination.kms_key_id: KMS key for destination encryption. Null = AWS-managed key.

    NOTE: source file system cannot be a replication destination itself.
  EOT
  type = object({
    destination = object({
      region                 = optional(string)
      file_system_id         = optional(string)
      availability_zone_name = optional(string)
      kms_key_id             = optional(string)
    })
  })
  default = null

  # Validación 1: file_system_id debe ser un EFS ID válido o null
  validation {
    condition = (
      var.replication_configuration == null
      ) || (
      var.replication_configuration.destination.file_system_id == null
      ) || (
      can(regex("^fs-[0-9a-f]{8,17}$", var.replication_configuration.destination.file_system_id))
    )
    error_message = "replication_configuration.destination.file_system_id must be a valid EFS ID (e.g. fs-0abc12345678) or null."
  }

  # Validación 2: AZ válida o null
  validation {
    condition = (
      var.replication_configuration == null
      ) || (
      var.replication_configuration.destination.availability_zone_name == null
      ) || (
      can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.replication_configuration.destination.availability_zone_name))
    )
    error_message = "replication_configuration.destination.availability_zone_name must be a valid AZ (e.g. us-west-2a) or null."
  }

  # Validación 3: KMS key válido o null
  validation {
    condition = (
      var.replication_configuration == null
      ) || (
      var.replication_configuration.destination.kms_key_id == null
      ) || (
      can(regex("^(arn:aws[a-z-]*:kms:|alias/)", var.replication_configuration.destination.kms_key_id))
    )
    error_message = "replication_configuration.destination.kms_key_id must be a KMS ARN or alias, or null."
  }

  # Validación 4: region debe ser una región AWS válida o null
  validation {
    condition = (
      var.replication_configuration == null
      ) || (
      var.replication_configuration.destination.region == null
      ) || (
      can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.replication_configuration.destination.region))
    )
    error_message = "replication_configuration.destination.region must be a valid AWS region (e.g. us-west-2) or null."
  }

  # Validación 5: file_system_id y availability_zone_name son mutuamente exclusivos
  # (Si se replica a un EFS existente, no se especifica AZ; si es One Zone, se especifica AZ)
  # validation {
  #   condition = (
  #     var.replication_configuration == null
  #     ) || (
  #     var.replication_configuration.destination.file_system_id == null
  #     ) || (
  #     var.replication_configuration.destination.availability_zone_name == null
  #   )
  #   error_message = "replication_configuration.destination.file_system_id and availability_zone_name are mutually exclusive. Use file_system_id to replicate to an existing EFS, or availability_zone_name for a new One Zone EFS."
  # }
}

# ─────────────────────────────────────────────────────────────
# BACKUP
# ─────────────────────────────────────────────────────────────

variable "enable_backup" {
  description = <<-EOT
    Enable AWS Backup automatic backups for this file system.
    Creates a daily backup with 35-day retention using the default EFS backup plan.
    For custom schedules, use the aws_backup_* resources outside this module.
  EOT
  type        = bool
  default     = true
}

# ─────────────────────────────────────────────────────────────
# TAGS
# ─────────────────────────────────────────────────────────────

variable "tags" {
  description = "Map of tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment label (dev | staging | prod). Merged into tags."
  type        = string
  default     = ""

  validation {
    condition     = var.environment == "" || contains(["dev", "staging", "prod", "sandbox", "qa"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, sandbox, qa, or empty string."
  }
}

variable "mount_target_tags" {
  description = "Additional tags applied only to mount target resources."
  type        = map(string)
  default     = {}
}

variable "access_point_tags" {
  description = "Additional tags applied to all access points (merged with per-AP tags)."
  type        = map(string)
  default     = {}
}

variable "security_group_tags" {
  description = "Additional tags applied to the managed security group."
  type        = map(string)
  default     = {}
}

# ─────────────────────────────────────────────────────────────
# TIMEOUTS
# ─────────────────────────────────────────────────────────────

# variable "timeouts" {
#   description = "Custom resource timeouts for aws_efs_file_system."
#   type = object({
#     create = optional(string, "10m")
#     update = optional(string, "10m")
#     delete = optional(string, "20m")
#   })
#   default = {}
# }
