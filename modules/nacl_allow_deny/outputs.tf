output "acl_id" {
  description = "ID de la ACL utilizada"
  value       = var.acl_id
}
output "rule_ids" {
  description = "IDs de las reglas de ingreso creadas"
  value       = { for k, v in aws_network_acl_rule.allow_deny : k => v.id }
}
output "rules_count" {
  description = "Número de reglas de ingreso creadas"
  value       = length(aws_network_acl_rule.allow_deny)
}
