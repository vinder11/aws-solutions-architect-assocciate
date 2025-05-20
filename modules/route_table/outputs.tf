output "route_table_id" {
  description = "ID de la tabla de ruteo creada"
  value       = aws_route_table.route_table.id
}

output "route_table_arn" {
  description = "ARN de la tabla de ruteo"
  value       = aws_route_table.route_table.arn
}

output "route_table_owner_id" {
  description = "ID del propietario de la tabla de ruteo"
  value       = aws_route_table.route_table.owner_id
}

output "association_ids" {
  description = "Lista de IDs de las asociaciones creadas entre la tabla de ruteo y las subredes"
  value       = aws_route_table_association.route_table_association[*].id
}

output "routes" {
  description = "Lista de rutas en la tabla de ruteo"
  value       = aws_route_table.route_table.route
}
