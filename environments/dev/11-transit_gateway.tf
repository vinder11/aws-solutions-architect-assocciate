# module "single_account_tgw" {
#   source = "../../modules/transit_gateway"

#   name                            = "${var.project_name}-tgw-${var.environment_name}"
#   description                     = "TGW principal para la cuenta corporativa"
#   dns_support                     = "enable" # Habilitar soporte DNS para el Transit Gateway
#   vpn_ecmp_support                = "enable"
#   default_route_table_association = "enable"
#   default_route_table_propagation = "enable"
#   auto_accept_shared_attachments  = "disable" #  se utiliza para permitir o denegar automáticamente las solicitudes de attachment desde otras cuentas de AWS cuando se comparte un Transit Gateway mediante AWS Resource Access Manager (RAM)

#   vpc_attachments = {
#     # Adjuntar la VPC de Producción
#     "aws-lab-az1a-priv" = {
#       vpc_id     = module.vpc.vpc_id                 # VPC de Laboratorio creada en el módulo de VPC
#       subnet_ids = module.subnets.private_subnet_ids # Al menos 2 subnets en AZs distintas para alta disponibilidad, en este caso como publica y privada están en la misma AZ tengo que colocarlos en diferentes attchments
#     },
#     # "aws-lab-az1a-pub" = { # NO ES POSIBLE LIMITACION ARQUITECTONICA DE TGW
#     #   vpc_id     = module.vpc.vpc_id                # VPC de Laboratorio creada en el módulo de VPC
#     #   subnet_ids = module.subnets.public_subnet_ids # Al menos 2 subnets en AZs distintas para alta disponibilidad, en este caso como publica y privada están en la misma AZ tengo que colocarlos en diferentes attchments
#     # },
#     # Adjuntar la VPC de Desarrollo
#     "desarrollo" = {
#       vpc_id     = "vpc-"
#       subnet_ids = ["subnet-", "subnet-"] # Bancosol-dev-vpc-WorkerNode-sn-a y Bancosol-dev-vpc-WorkerNode-sn-b, como están en diferentes AZs, puedo usar ambas
#     }
#   }

#   tags = var.vpc_custom_tags
# }

# resource "aws_route" "vpc_a_to_vpc_b" {
#   route_table_id         = "rtb-" # Tabla de ruteo de la VPC Desarrollo
#   destination_cidr_block = "198.168.2.0/23"        # CIDR de VPC AWS Lab
#   transit_gateway_id     = module.single_account_tgw.transit_gateway_id
# }

# resource "aws_route" "vpc_b_to_vpc_a1" {
#   route_table_id         = module.private_route_table.route_table_id # Tabla de ruteo de la VPC AWS Lab
#   destination_cidr_block = "10.34.35.0/24"                           # CIDR de VPC Desarrollo
#   transit_gateway_id     = module.single_account_tgw.transit_gateway_id
# }

# resource "aws_route" "vpc_b_to_vpc_a2" {
#   route_table_id         = module.private_route_table.route_table_id # Tabla de ruteo de la VPC AWS Lab
#   destination_cidr_block = "10.34.36.0/24"                           # CIDR de VPC Desarrollo
#   transit_gateway_id     = module.single_account_tgw.transit_gateway_id
# }

# Módulo para crear un Transit Gateway compartido entre múltiples cuentas de AWS
# Este módulo permite crear un Transit Gateway que puede ser compartido con otras cuentas de AWS
# module "shared_tgw" {
#   source = "./transit-gateway"

#   name = "org-shared-tgw"
#   description = "TGW compartido para toda la organización"

#   # Deshabilitamos asociación y propagación por defecto para tener un control granular
#   # con tablas de ruta personalizadas (práctica recomendada).
#   default_route_table_association = false
#   default_route_table_propagation = false

#   # Compartimos el TGW con otras dos cuentas de AWS
#   share_with_principal_arns = [
#     "arn:aws:iam::111122223333:root", # Cuenta de Producción
#     "arn:aws:iam::444455556666:root"  # Cuenta de Staging
#   ]

#   # En este caso, los attachments se harían desde las cuentas miembro,
#   # por lo que dejamos el mapa de attachments vacío aquí.

#   tags = {
#     Owner     = "NetworkTeam"
#     ManagedBy = "Terraform"
#   }
# }
