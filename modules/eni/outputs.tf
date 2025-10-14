# ========================================
# Módulo ENI Reutilizable - outputs.tf
# ========================================

output "eni_id" {
  description = "ID del ENI creado"
  value       = var.create_eni ? aws_network_interface.this[0].id : null
}

output "eni_arn" {
  description = "ARN del ENI"
  value       = var.create_eni ? aws_network_interface.this[0].arn : null
}

output "private_ip" {
  description = "IP privada principal del ENI"
  value       = var.create_eni ? aws_network_interface.this[0].private_ip : null
}

output "private_ips" {
  description = "Lista de todas las IPs privadas del ENI"
  value       = var.create_eni ? aws_network_interface.this[0].private_ips : []
}

output "mac_address" {
  description = "Dirección MAC del ENI"
  value       = var.create_eni ? aws_network_interface.this[0].mac_address : null
}

output "attachment_id" {
  description = "ID del attachment si el ENI está adjunto a una instancia"
  value       = var.create_eni && var.attach_to_instance ? aws_network_interface_attachment.this[0].id : null
}

output "subnet_id" {
  description = "ID de la subnet donde está el ENI"
  value       = var.create_eni ? aws_network_interface.this[0].subnet_id : null
}

output "security_group_ids" {
  description = "IDs de los security groups asociados"
  value       = var.create_eni ? aws_network_interface.this[0].security_groups : []
}
