# outputs.tf

output "vpc_peering_connection_id" {
  description = "El ID de la conexión VPC Peering."
  value       = aws_vpc_peering_connection.main.id
}

output "vpc_peering_connection_status" {
  description = "El estado de la solicitud de la conexión de peering."
  value       = aws_vpc_peering_connection.main.accept_status
}
