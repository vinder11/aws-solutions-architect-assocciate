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
#       vpc_id     = "vpc-09180172491355392"
#       subnet_ids = ["subnet-0f969102e835c45bb", "subnet-06796dadcc662ad0b"] # Bancosol-dev-vpc-WorkerNode-sn-a y Bancosol-dev-vpc-WorkerNode-sn-b, como están en diferentes AZs, puedo usar ambas
#     }
#   }

#   tags = var.vpc_custom_tags
# }

# resource "aws_route" "vpc_a_to_vpc_b" {
#   route_table_id         = "rtb-0c2b35397d65bc893" # Tabla de ruteo de la VPC Desarrollo
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
