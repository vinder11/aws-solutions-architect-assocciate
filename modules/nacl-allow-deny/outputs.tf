output "acl_id" {
  description = "ID de la ACL utilizada"
  value       = var.acl_id
}

output "rule_id" {
  description = "ID de la regla de entrada o salida creada"
  value       = aws_network_acl_rule.allow_deny.id
}
