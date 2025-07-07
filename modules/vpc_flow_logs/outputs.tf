# outputs.tf

output "flow_log_id" {
  description = "El ID del VPC Flow Log creado."
  value       = aws_flow_log.main.id
}

output "log_destination_arn" {
  description = "El ARN del destino de los logs (CloudWatch Log Group o S3 bucket)."
  value       = local.destination_arn
}

output "iam_role_arn" {
  description = "El ARN del rol IAM creado para los Flow Logs."
  value       = one(aws_iam_role.flow_logs_role[*].arn)
}
