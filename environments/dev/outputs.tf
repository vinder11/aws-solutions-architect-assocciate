# /vpc-project/environments/dev/outputs.tf

# Outputs del entorno de desarrollo, provenientes del módulo VPC.
####################################################################################################
output "development_vpc_id" {
  description = "ID de la VPC del entorno de desarrollo."
  value       = module.vpc.vpc_id
}
output "development_vpc_cidr" {
  description = "CIDR block de la VPC del entorno de desarrollo."
  value       = module.vpc.vpc_cidr_block
}
output "development_vpc_arn" {
  description = "ARN de la VPC del entorno de desarrollo."
  value       = module.vpc.vpc_arn
}
output "development_internet_gateway_id" {
  description = "El ID del Internet Gateway (IGW) creado, o null si no se creó."
  value       = module.vpc.internet_gateway_id
}
####################################################################################################
output "development_default_security_group_id" {
  description = "ID del grupo de seguridad por defecto de la VPC de desarrollo."
  value       = module.vpc.default_security_group_id
}
####################################################################################################
output "development_default_network_acl_id" {
  description = "ID de la ACL de red por defecto de la VPC de desarrollo."
  value       = module.vpc.default_network_acl_id
}
####################################################################################################
output "development_default_route_table_id" {
  description = "ID de la tabla de ruteo por defecto de la VPC de desarrollo."
  value       = module.vpc.default_route_table_id
}
####################################################################################################
output "development_subnet_ids" {
  description = "IDs de las subredes creadas en el entorno de desarrollo."
  value       = module.subnets.subnet_ids
}
output "development_subnet_arns" {
  description = "ARNs de las subredes creadas en el entorno de desarrollo."
  value       = module.subnets.subnet_arns
}
output "development_subnet_cidrs" {
  description = "CIDRs de las subredes creadas en el entorno de desarrollo."
  value       = module.subnets.subnet_cidrs
}
output "development_subnet_azs" {
  description = "Zonas de disponibilidad de las subredes creadas en el entorno de desarrollo."
  value       = module.subnets.subnet_azs
}
####################################################################################################
output "development_public_subnet_ids" {
  description = "IDs de las subredes públicas creadas en el entorno de desarrollo."
  value       = module.subnets.public_subnet_ids
}
output "development_public_route_table_id" {
  description = "IDs de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.public_route_table.route_table_id
}
output "development_public_route_table_arns" {
  description = "ARNs de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.public_route_table.route_table_arn
}
output "development_public_route_table_owner_ids" {
  description = "IDs de los propietarios de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.public_route_table.route_table_owner_id
}
output "development_public_route_table_association_id" {
  description = "IDs de las asociaciones de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.public_route_table.association_ids
}
output "development_public_route_table_routes" {
  description = "Rutas de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.public_route_table.routes
}
####################################################################################################
output "development_private_subnet_ids" {
  description = "IDs de las subredes privadas creadas en el entorno de desarrollo."
  value       = module.subnets.private_subnet_ids
}
output "development_private_route_table_id" {
  description = "IDs de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.private_route_table.route_table_id
}
output "development_private_route_table_arns" {
  description = "ARNs de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.private_route_table.route_table_arn
}
output "development_private_route_table_owner_ids" {
  description = "IDs de los propietarios de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.private_route_table.route_table_owner_id
}
output "development_private_route_table_association_id" {
  description = "IDs de las asociaciones de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.private_route_table.association_ids
}
output "development_private_route_table_routes" {
  description = "Rutas de las tablas de ruteo creadas en el entorno de desarrollo."
  value       = module.private_route_table.routes
}
####################################################################################################
output "development_nat_gateway_id" {
  description = "ID del NAT Gateway creado en el entorno de desarrollo."
  value       = module.nat_gateway.nat_gateway_id
}
output "development_nat_eip_id" {
  description = "ID de la Elastic IP asociada al NAT Gateway en el entorno de desarrollo."
  value       = module.nat_gateway.nat_eip_id
}
output "development_nat_eip_public_ip" {
  description = "Dirección IP pública de la Elastic IP asociada al NAT Gateway en el entorno de desarrollo."
  value       = module.nat_gateway.nat_eip_public_ip
}
####################################################################################################
output "ingress_rule_id" {
  description = "ID de las reglas de entrada creada en el NACL."
  value       = module.nacl_allow_ingress.rule_id
}
output "egress_rule_id" {
  description = "ID de las reglas de salida creada en el NACL."
  value       = module.nacl_allow_egress.rule_id
}
####################################################################################################
