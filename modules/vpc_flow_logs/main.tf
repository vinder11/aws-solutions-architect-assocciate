# --- Log Destination Resources ---
# Crear el CloudWatch Log Group si es necesario
resource "aws_cloudwatch_log_group" "flow_log_group" {
  count = var.log_destination_type == "cloud-watch-logs" && var.log_destination_arn == null ? 1 : 0

  name              = local.cw_log_group_name
  retention_in_days = var.log_group_retention_days
  tags              = var.tags
}

# Crear el S3 bucket si es necesario
resource "aws_s3_bucket" "flow_log_bucket" {
  count = var.log_destination_type == "s3" && var.log_destination_arn == null ? 1 : 0

  # El nombre del bucket debe ser único globalmente
  bucket = local.s3_bucket_name
  tags   = var.tags
}

# --- VPC Flow Log Resource ---
# Recurso principal que activa el Flow Log
resource "aws_flow_log" "main" {
  log_destination_type     = var.log_destination_type
  traffic_type             = var.traffic_type
  vpc_id                   = var.vpc_id
  max_aggregation_interval = var.max_aggregation_interval # Intervalo máximo de agregación en segundos

  # Utiliza el ARN y el rol determinados en los 'locals'
  log_destination = local.destination_arn
  iam_role_arn    = local.iam_role_arn

  tags = merge(var.tags, {
    Name = "flow-log-${var.vpc_id}"
  })
}
