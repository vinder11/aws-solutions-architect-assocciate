# --- Locals for dynamic values ---
# Lógica para determinar nombres y ARNs dinámicamente
locals {
  # Determina el ARN del destino final
  destination_arn = var.log_destination_arn != null ? var.log_destination_arn : (
    var.log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.flow_log_group[0].arn : aws_s3_bucket.flow_log_bucket[0].arn
  )

  # Determina el ARN del rol IAM a usar
  iam_role_arn = var.log_destination_arn == null ? aws_iam_role.flow_logs_role[0].arn : null

  # Asigna un nombre por defecto si el usuario no lo especifica
  cw_log_group_name = var.log_group_name != "" ? var.log_group_name : "vpc-flow-logs-${var.vpc_id}"
  s3_bucket_name    = var.s3_bucket_name != "" ? var.s3_bucket_name : "vpc-flow-logs-${var.vpc_id}-${random_string.bucket_suffix.id}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
