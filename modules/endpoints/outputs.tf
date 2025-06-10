output "all_endpoints" {
  description = "Mapa completo de todos los endpoints creados con sus atributos principales"
  value       = aws_vpc_endpoint.this
}

output "endpoint_ids" {
  description = "Mapa de IDs de todos los endpoints creados, indexados por nombre de endpoint"
  value       = { for endpoint_name, endpoint in aws_vpc_endpoint.this : endpoint_name => endpoint.id }
}

output "endpoint_arns" {
  description = "Mapa de ARNs de todos los endpoints creados, indexados por nombre de endpoint"
  value       = { for endpoint_name, endpoint in aws_vpc_endpoint.this : endpoint_name => endpoint.arn }
}

output "interface_endpoints" {
  description = "Mapa de solo los endpoints de tipo Interface, indexados por nombre de endpoint"
  value       = { for endpoint_name, endpoint in aws_vpc_endpoint.this : endpoint_name => endpoint if endpoint.vpc_endpoint_type == "Interface" }
}

output "gateway_endpoints" {
  description = "Mapa de solo los endpoints de tipo Gateway, indexados por nombre de endpoint"
  value       = { for endpoint_name, endpoint in aws_vpc_endpoint.this : endpoint_name => endpoint if endpoint.vpc_endpoint_type == "Gateway" }
}

output "dns_entries" {
  description = "Mapa de entradas DNS para los endpoints que tienen DNS privado habilitado"
  value = {
    for endpoint_name, endpoint in aws_vpc_endpoint.this :
    endpoint_name => endpoint.dns_entry if endpoint.vpc_endpoint_type == "Interface" && try(endpoint.private_dns_enabled, false)
  }
}

output "network_interface_ids" {
  description = "Mapa de IDs de interfaces de red para endpoints de tipo Interface"
  value = {
    for endpoint_name, endpoint in aws_vpc_endpoint.this :
    endpoint_name => endpoint.network_interface_ids if endpoint.vpc_endpoint_type == "Interface"
  }
}

output "security_group_associations" {
  description = "Mapa de asociaciones de grupos de seguridad para endpoints de tipo Interface"
  value = {
    for endpoint_name, endpoint in aws_vpc_endpoint.this :
    endpoint_name => {
      security_group_ids = endpoint.security_group_ids
      default_sg_used    = length(try(endpoint.security_group_ids, [])) == 0 && var.default_security_group
    } if endpoint.vpc_endpoint_type == "Interface"
  }
}

output "route_table_associations" {
  description = "Mapa de asociaciones de tablas de ruta para endpoints de tipo Gateway"
  value = {
    for endpoint_name, endpoint in aws_vpc_endpoint.this :
    endpoint_name => endpoint.route_table_ids if endpoint.vpc_endpoint_type == "Gateway"
  }
}

output "default_security_group_id" {
  description = "ID del security group por defecto creado para los endpoints (si se configuró)"
  value       = var.default_security_group ? aws_security_group.vpc_endpoints[0].id : null
}
