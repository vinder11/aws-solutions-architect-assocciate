# /vpc-project/environments/dev/outputs.tf

# Outputs del entorno de desarrollo, provenientes del módulo VPC.

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

output "development_default_security_group_id" {
  description = "ID del grupo de seguridad por defecto de la VPC de desarrollo."
  value       = module.vpc.default_security_group_id
}

output "development_default_network_acl_id" {
  description = "ID de la ACL de red por defecto de la VPC de desarrollo."
  value       = module.vpc.default_network_acl_id
}

output "development_default_route_table_id" {
  description = "ID de la tabla de ruteo por defecto de la VPC de desarrollo."
  value       = module.vpc.default_route_table_id
}
