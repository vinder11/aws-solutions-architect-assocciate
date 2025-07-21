# =============================================================================
# outputs.tf
# =============================================================================

output "alarm_arn" {
  description = "ARN de la alarma creada"
  value       = var.create_alarm ? aws_cloudwatch_metric_alarm.this[0].arn : null
}

output "alarm_name" {
  description = "Nombre de la alarma creada"
  value       = var.create_alarm ? aws_cloudwatch_metric_alarm.this[0].alarm_name : null
}

output "alarm_id" {
  description = "ID de la alarma creada"
  value       = var.create_alarm ? aws_cloudwatch_metric_alarm.this[0].id : null
}

# output "anomaly_detector_id" {
#   description = "ID del detector de anomalías (si está habilitado)"
#   value       = var.anomaly_detector.enabled ? aws_cloudwatch_anomaly_detector.this[0].id : null
# }

output "full_alarm_name" {
  description = "Nombre completo construido para la alarma"
  value       = local.full_alarm_name
}
