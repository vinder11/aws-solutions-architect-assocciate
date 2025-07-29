# ==================================================
# outputs.tf
# ==================================================

output "role_arn" {
  description = "ARN del rol IAM creado"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Nombre del rol IAM creado"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID único del rol IAM"
  value       = aws_iam_role.this.unique_id
}

output "role_create_date" {
  description = "Fecha de creación del rol"
  value       = aws_iam_role.this.create_date
}

output "assume_role_policy" {
  description = "Política de asunción del rol"
  value       = aws_iam_role.this.assume_role_policy
  sensitive   = true
}

output "attached_managed_policies" {
  description = "Lista de políticas administradas adjuntadas"
  value       = var.managed_policies
}

output "inline_policies" {
  description = "Mapa de políticas inline creadas"
  value       = { for k, v in aws_iam_role_policy.inline_policies : k => v.name }
}
