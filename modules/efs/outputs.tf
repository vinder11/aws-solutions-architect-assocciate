# ============================================================
# outputs.tf — terraform-aws-efs module
# ============================================================

# ─────────────────────────────────────────────────────────────
# FILE SYSTEM
# ─────────────────────────────────────────────────────────────

output "file_system_id" {
  description = "The ID of the EFS file system (e.g. fs-0abc12345678)."
  value       = aws_efs_file_system.this.id
}

output "file_system_arn" {
  description = "The ARN of the EFS file system."
  value       = aws_efs_file_system.this.arn
}

output "file_system_dns_name" {
  description = <<-EOT
    The DNS name for the EFS file system.
    Format: {file_system_id}.efs.{region}.amazonaws.com
    Use this as the NFS server address for mount commands and /etc/fstab.
  EOT
  value = aws_efs_file_system.this.dns_name
}

output "file_system_size_in_bytes" {
  description = "Latest metered size (in bytes) of the file system."
  value       = aws_efs_file_system.this.size_in_bytes
}

output "file_system_number_of_mount_targets" {
  description = "Current number of mount targets created for this file system."
  value       = aws_efs_file_system.this.number_of_mount_targets
}

output "file_system_owner_id" {
  description = "AWS account ID of the file system owner."
  value       = aws_efs_file_system.this.owner_id
}

output "performance_mode" {
  description = "The performance mode of the file system."
  value       = aws_efs_file_system.this.performance_mode
}

output "throughput_mode" {
  description = "The throughput mode of the file system."
  value       = aws_efs_file_system.this.throughput_mode
}

output "encrypted" {
  description = "Whether the file system is encrypted at rest."
  value       = aws_efs_file_system.this.encrypted
}

output "kms_key_id" {
  description = "The ARN of the KMS key used for encryption (null if SSE-managed or unencrypted)."
  value       = aws_efs_file_system.this.kms_key_id
}

# ─────────────────────────────────────────────────────────────
# MOUNT TARGETS
# ─────────────────────────────────────────────────────────────

output "mount_target_ids" {
  description = "Map of mount target key → mount target ID."
  value       = { for k, mt in aws_efs_mount_target.this : k => mt.id }
}

output "mount_target_ips" {
  description = <<-EOT
    Map of mount target key → assigned IP address.
    Useful for /etc/fstab when DNS is not available or for NLB target group registration.
  EOT
  value = { for k, mt in aws_efs_mount_target.this : k => mt.ip_address }
}

output "mount_target_dns_names" {
  description = <<-EOT
    Map of mount target key → AZ-specific DNS name.
    Format: {availability_zone}.{file_system_id}.efs.{region}.amazonaws.com
    Use for AZ-pinned mounts to avoid cross-AZ data transfer charges.
  EOT
  value = { for k, mt in aws_efs_mount_target.this : k => mt.dns_name }
}

output "mount_target_availability_zones" {
  description = "Map of mount target key → availability zone name."
  value       = { for k, mt in aws_efs_mount_target.this : k => mt.availability_zone_name }
}

output "mount_target_network_interface_ids" {
  description = "Map of mount target key → ENI ID attached to the mount target."
  value       = { for k, mt in aws_efs_mount_target.this : k => mt.network_interface_id }
}

# ─────────────────────────────────────────────────────────────
# SECURITY GROUP
# ─────────────────────────────────────────────────────────────

output "security_group_id" {
  description = "ID of the managed security group (null if create_security_group = false)."
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "ARN of the managed security group (null if create_security_group = false)."
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

output "security_group_name" {
  description = "Name of the managed security group (null if create_security_group = false)."
  value       = var.create_security_group ? aws_security_group.this[0].name : null
}

# ─────────────────────────────────────────────────────────────
# ACCESS POINTS
# ─────────────────────────────────────────────────────────────

output "access_point_ids" {
  description = "Map of access point key → access point ID."
  value       = { for k, ap in aws_efs_access_point.this : k => ap.id }
}

output "access_point_arns" {
  description = "Map of access point key → access point ARN."
  value       = { for k, ap in aws_efs_access_point.this : k => ap.arn }
}

output "access_point_file_system_arns" {
  description = "Map of access point key → file system ARN (useful for IAM policies)."
  value       = { for k, ap in aws_efs_access_point.this : k => ap.file_system_arn }
}

# ─────────────────────────────────────────────────────────────
# REPLICATION
# ─────────────────────────────────────────────────────────────

output "replication_destination_file_system_id" {
  description = "ID of the destination (replica) EFS file system (null if replication not configured)."
  value       = try(aws_efs_replication_configuration.this[0].destination[0].file_system_id, null)
}

output "replication_destination_region" {
  description = "Region of the replication destination (null if replication not configured)."
  value       = try(aws_efs_replication_configuration.this[0].destination[0].region, null)
}

output "replication_source_file_system_arn" {
  description = "ARN of the source file system for this replication (null if not configured)."
  value       = try(aws_efs_replication_configuration.this[0].source_file_system_arn, null)
}

# ─────────────────────────────────────────────────────────────
# CONVENIENCE HELPERS
# ─────────────────────────────────────────────────────────────

output "mount_command" {
  description = <<-EOT
    Example Linux NFS mount command using the EFS DNS name.
    Replace /mnt/efs with your desired mount point.
  EOT
  value = "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.this.dns_name}:/ /mnt/efs"
}

output "efs_utils_mount_command" {
  description = "Example mount using amazon-efs-utils (enables encryption in transit via TLS)."
  value       = "sudo mount -t efs -o tls ${aws_efs_file_system.this.id}:/ /mnt/efs"
}

output "fstab_entry" {
  description = "Example /etc/fstab entry using amazon-efs-utils with TLS and IAM authorization."
  value       = "${aws_efs_file_system.this.id}:/ /mnt/efs efs _netdev,tls,iam 0 0"
}

output "kubernetes_persistent_volume_spec" {
  description = <<-EOT
    Stub spec for Kubernetes PersistentVolume using the EFS CSI driver.
    Populate access_point_id and fs_group as needed.
  EOT
  value = {
    driver        = "efs.csi.aws.com"
    file_system_id = aws_efs_file_system.this.id
    access_points = { for k, ap in aws_efs_access_point.this : k => ap.id }
  }
}

output "backup_policy_status" {
  description = "The AWS Backup policy status applied to this file system (ENABLED or DISABLED)."
  value       = aws_efs_backup_policy.this.backup_policy[0].status
}
