# modules/subnet/outputs.tf

output "subnet_ids" {
  description = "Mapa de IDs de subredes creadas"
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "subnet_arns" {
  description = "Mapa de ARNs de subredes creadas"
  value       = { for k, v in aws_subnet.this : k => v.arn }
}

output "subnet_cidrs" {
  description = "Mapa de CIDRs de subredes creadas"
  value       = { for k, v in aws_subnet.this : k => v.cidr_block }
}

output "subnet_azs" {
  description = "Mapa de zonas de disponibilidad de subredes creadas"
  value       = { for k, v in aws_subnet.this : k => v.availability_zone }
}

output "public_subnet_ids" {
  description = "Lista de IDs de subredes públicas"
  value       = [for k, v in local.public_subnets : v.id]
}

output "private_subnet_ids" {
  description = "Lista de IDs de subredes privadas"
  value       = [for k, v in local.private_subnets : v.id]
}
