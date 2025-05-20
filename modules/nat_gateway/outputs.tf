output "nat_gateway_id" {
  description = "ID del NAT Gateway creado"
  value       = var.create_nat_gateway ? aws_nat_gateway.nat_gateway[0].id : null
}

output "nat_eip_id" {
  description = "ID de la Elastic IP asociada al NAT Gateway"
  value       = var.create_nat_gateway ? aws_eip.nat_eip[0].id : null
}

output "nat_eip_public_ip" {
  description = "Dirección IP pública de la Elastic IP asociada al NAT Gateway"
  value       = var.create_nat_gateway ? aws_eip.nat_eip[0].public_ip : null
}
