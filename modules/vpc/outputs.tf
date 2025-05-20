# /vpc-project/modules/vpc/outputs.tf

output "vpc_id" {
  description = "El ID de la VPC creada."
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "El ARN (Amazon Resource Name) de la VPC."
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "El bloque CIDR de la VPC."
  value       = aws_vpc.main.cidr_block
}

output "default_route_table_id" {
  description = "El ID de la tabla de ruteo por defecto de la VPC."
  # Referencia al ID del recurso gestionado por Terraform
  value = aws_default_route_table.default.id
}

output "default_security_group_id" {
  description = "El ID del grupo de seguridad por defecto de la VPC."
  # Referencia al ID del recurso gestionado por Terraform
  value = aws_default_security_group.default.id
}

output "default_network_acl_id" {
  description = "El ID de la ACL de red por defecto de la VPC."
  # Referencia al ID del recurso gestionado por Terraform
  value = aws_default_network_acl.default.id
}

output "vpc_name" {
  description = "El nombre asignado a la VPC."
  value       = var.vpc_name
}

# Output condicional: devuelve el ID si existe, o una cadena vacía si no
output "internet_gateway_id" {
  value       = var.create_igw ? aws_internet_gateway.igw[0].id : null
  description = "El ID del Internet Gateway (IGW) creado, o null si no se creó."
}
