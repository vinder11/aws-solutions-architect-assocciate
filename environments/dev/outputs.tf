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
output "nacl_ingress_rule_id" {
  description = "ID de las reglas de entrada creada en el NACL."
  value       = module.nacl_allow_ingress.rule_ids
}
output "nacl_egress_rule_id" {
  description = "ID de las reglas de salida creada en el NACL."
  value       = module.nacl_allow_egress.rule_ids
}
####################################################################################################
output "sg_security_group_id" {
  description = "ID del grupo de seguridad creado"
  value       = module.security_groups.security_group_id
}
output "sg_security_group_owner_id" {
  description = "ID del propietario del grupo de seguridad"
  value       = module.security_groups.security_group_owner_id
}
output "sg_egress_rules" {
  description = "Lista de reglas de salida aplicadas"
  value       = module.security_groups.egress_rules
}
output "sg_ingress_rules" {
  description = "Lista de reglas de entrada aplicadas"
  value       = module.security_groups.ingress_rules
}
####################################################################################################
# output "vpc_flow_log_id" {
#   description = "ID del Flow Log creado para la VPC de desarrollo."
#   value       = module.vpc_flow_logs_produccion.flow_log_id
# }
# output "vpc_flow_log_destination_arn" {
#   description = "ARN del destino de los logs (CloudWatch Log Group o S3 bucket) para el Flow Log de la VPC de desarrollo."
#   value       = module.vpc_flow_logs_produccion.log_destination_arn
# }
# output "vpc_flow_log_iam_role_arn" {
#   description = "ARN del rol IAM creado para los Flow Logs de la VPC de desarrollo."
#   value       = module.vpc_flow_logs_produccion.iam_role_arn
# }
####################################################################################################
# output "vpc_peering_connection_id" {
#   description = "El ID de la conexión VPC Peering entre el entorno de desarrollo y producción."
#   value       = module.peering_prod_dev.vpc_peering_connection_id

# }
# output "vpc_peering_connection_status" {
#   description = "El estado de la solicitud de la conexión de peering entre el entorno de desarrollo y producción."
#   value       = module.peering_prod_dev.vpc_peering_connection_status
# }
####################################################################################################
# output "eip_public_ip" {
#   value       = module.nat_gateway_eip.public_ip
#   description = "La dirección IP pública asignada al NAT Gateway en el entorno de desarrollo."
# }
# output "eip_allocation_id" {
#   value       = module.nat_gateway_eip.allocation_id
#   description = "El ID de asignación de la Elastic IP para el NAT Gateway en el entorno de desarrollo."
# }
# output "eip_association_id" {
#   value       = module.nat_gateway_eip.association_id
#   description = "El ID de asociación de la Elastic IP para el NAT Gateway en el entorno de desarrollo."
# }
####################################################################################################
# output "transit_gateway_id" {
#   description = "El ID del Transit Gateway creado."
#   value       = module.single_account_tgw.transit_gateway_id
# }
# output "transit_gateway_arn" {
#   description = "El ARN (Amazon Resource Name) del Transit Gateway."
#   value       = module.single_account_tgw.transit_gateway_arn
# }
# output "transit_gateway_default_route_table_id" {
#   description = "El ID de la tabla de rutas por defecto asociada con el Transit Gateway."
#   value       = module.single_account_tgw.transit_gateway_default_route_table_id
# }
# output "vpc_attachment_ids" {
#   description = "Mapa con los IDs de los adjuntos de VPC creados."
#   value       = module.single_account_tgw.vpc_attachment_ids

# }
####################################################################################################
output "instance_ids" {
  description = "IDs de las instancias EC2 creadas en el entorno de desarrollo."
  value       = module.ec2_instances.instance_ids
}
output "instance_arns" {
  description = "ARNs de las instancias EC2 creadas en el entorno de desarrollo."
  value       = module.ec2_instances.instance_arns
}
output "instance_public_ips" {
  description = "IPs públicas de las instancias EC2 creadas en el entorno de desarrollo."
  value       = module.ec2_instances.instance_public_ips
}
output "instance_private_ips" {
  description = "IPs privadas de las instancias EC2 creadas en el entorno de desarrollo."
  value       = module.ec2_instances.instance_private_ips
}
####################################################################################################
output "alarm_full_name" {
  description = "Nombre completo construido para la alarma de CloudWatch."
  value       = module.ec2_cpu_alarm.full_alarm_name
}
output "alarm_arn" {
  description = "ARN de la alarma creada"
  value       = module.ec2_cpu_alarm.alarm_arn
}
output "alarm_id" {
  description = "ID de la alarma creada"
  value       = module.ec2_cpu_alarm.alarm_id
}
####################################################################################################
output "key_pair_name" {
  description = "El nombre del Key Pair creado."
  value       = module.key_pair_dev.key_name
}
output "key_pair_id" {
  description = "El ID del Key Pair."
  value       = module.key_pair_dev.key_pair_id
}
output "key_pair_arn" {
  description = "El ARN del Key Pair."
  value       = module.key_pair_dev.arn

}
####################################################################################################
output "iam_role_arn" {
  description = "ARN del rol IAM creado"
  value       = module.ec2_role.role_arn
}
output "iam_role_name" {
  description = "Nombre del rol IAM creado"
  value       = module.ec2_role.role_name
}
output "iam_role_id" {
  description = "ID único del rol IAM"
  value       = module.ec2_role.role_id
}
output "iam_role_create_date" {
  description = "Fecha de creación del rol"
  value       = module.ec2_role.role_create_date
}
output "iam_assume_role_policy" {
  description = "Política de asunción del rol"
  value       = module.ec2_role.assume_role_policy
  sensitive   = true
}
output "iam_attached_managed_policies" {
  description = "Lista de políticas administradas adjuntadas"
  value       = module.ec2_role.attached_managed_policies
}
output "iam_inline_policies" {
  description = "Mapa de políticas inline creadas"
  value       = module.ec2_role.inline_policies
}
