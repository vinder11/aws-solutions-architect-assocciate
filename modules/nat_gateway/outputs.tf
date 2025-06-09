output "nat_gateway_id" {
  description = "ID del NAT Gateway creado"
  value       = aws_nat_gateway.nat_gateway.id
}

output "nat_eip_id" {
  description = "ID de la Elastic IP asociada al NAT Gateway"
  value       = aws_eip.nat_eip.id
}

output "nat_eip_public_ip" {
  description = "Dirección IP pública de la Elastic IP asociada al NAT Gateway"
  value       = aws_eip.nat_eip.public_ip
}
