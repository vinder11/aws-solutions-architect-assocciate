# outputs.tf

output "transit_gateway_id" {
  description = "El ID del Transit Gateway creado."
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "El ARN (Amazon Resource Name) del Transit Gateway."
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_default_route_table_id" {
  description = "El ID de la tabla de rutas por defecto asociada con el Transit Gateway."
  value       = aws_ec2_transit_gateway.main.association_default_route_table_id
}

output "vpc_attachment_ids" {
  description = "Mapa con los IDs de los adjuntos de VPC creados."
  value = {
    for k, v in aws_ec2_transit_gateway_vpc_attachment.main : k => v.id
  }
}
