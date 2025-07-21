# Escenario 1: Peering en la Misma Cuenta y Región (El más común)
# module "peering_prod_dev" {
#   source = "../../modules/vpc_peering"

#   requester_vpc_id = module.vpc.vpc_id       # VPC de Laboratorio
#   accepter_vpc_id  = "vpc-09180172491355392" # VPC de Desarrollo

#   # Actualizar las tablas de ruta principales de ambas VPCs
#   requester_route_table_ids = [module.private_route_table.route_table_id, module.public_route_table.route_table_id] # Tabla de ruta privada de la VPC de Laboratorio
#   accepter_route_table_ids  = ["rtb-0c2b35397d65bc893"]                                                             # Bancosol-dev-vpc-WorkerNode-rt de la subredes Bancosol-dev-vpc-WorkerNode-sn-a y Bancosol-dev-vpc-WorkerNode-sn-b
#   auto_accept_peering       = false                                                                                 # Aceptar automáticamente la conexión de peering

#   tags = var.vpc_custom_tags # Etiquetas personalizadas del entorno
# }

# Escenario 2: Peering entre Cuentas Diferentes (Cross-Account)
# providers.tf

# provider "aws" {
#   region = "us-east-1"
#   # Credenciales para la cuenta A (Requester)
# }

# provider "aws" {
#   alias  = "accepter"
#   region = "us-east-1"
#   # Credenciales para la cuenta B (Accepter)
#   # Puedes usar assume_role para esto
#   assume_role {
#     role_arn = "arn:aws:iam::ACCOUNT_B_ID:role/TerraformPeeringRole"
#   }
# }

# main.tf

# module "peering_cross_account" {
#   source = "./vpc-peering"

#   # Debes pasarle el provider del aceptante al módulo
#   providers = {
#     aws.accepter = aws.accepter
#   }

#   # La conexión ya no puede ser aceptada automáticamente por el mismo recurso
#   auto_accept_peering = false

#   requester_vpc_id = "vpc-aaaaaaaa" # VPC en Cuenta A
#   accepter_vpc_id  = "vpc-bbbbbbbb" # VPC en Cuenta B

#   accepter_aws_account_id = "ID_DE_LA_CUENTA_B" # Ej: "222222222222"

#   requester_route_table_ids = ["rtb-aaaaaaaa"]
#   accepter_route_table_ids  = ["rtb-bbbbbbbb"]

#   tags = {
#     Purpose = "Shared-Services"
#   }
# }
