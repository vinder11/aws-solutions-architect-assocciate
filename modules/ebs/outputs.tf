# ============================================
# OUTPUTS
# ============================================

output "volume_ids" {
  description = "IDs de los volúmenes EBS creados"
  value       = { for k, v in aws_ebs_volume.this : k => v.id }
}

output "volume_arns" {
  description = "ARNs de los volúmenes EBS creados"
  value       = { for k, v in aws_ebs_volume.this : k => v.arn }
}

output "volume_details" {
  description = "Detalles completos de los volúmenes"
  value = {
    for k, v in aws_ebs_volume.this : k => {
      id                = v.id
      arn               = v.arn
      availability_zone = v.availability_zone
      size              = v.size
      type              = v.type
      iops              = v.iops
      throughput        = v.throughput
      encrypted         = v.encrypted
      kms_key_id        = v.kms_key_id
    }
  }
}

output "attachment_ids" {
  description = "IDs de los attachments creados"
  value       = { for k, v in aws_volume_attachment.this : k => v.id }
}

output "snapshot_policy_arn" {
  description = "ARN de la política de snapshots DLM"
  value       = var.enable_volume_snapshots ? aws_dlm_lifecycle_policy.ebs_snapshots[0].arn : null
}
