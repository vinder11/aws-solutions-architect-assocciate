# Tabla de ruteo para subredes públicas
module "public_route_table" {
  source = "../../modules/route_table"

  vpc_id              = module.vpc.vpc_id
  route_table_name    = "${var.project_name}-public-rt-${var.environment_name}"
  subnet_ids          = module.subnets.public_subnet_ids
  is_public           = var.create_nat_gateway
  internet_gateway_id = module.vpc.internet_gateway_id

  tags = merge({
    Environment = var.environment_name
    },
    var.vpc_custom_tags # Incorpora etiquetas personalizadas del entorno
  )
}

# Tabla de ruteo para subredes privadas
module "private_route_table" {
  source = "../../modules/route_table"

  vpc_id           = module.vpc.vpc_id
  route_table_name = "${var.project_name}-private-rt-${var.environment_name}"
  subnet_ids       = module.subnets.private_subnet_ids
  is_public        = false
  nat_gateway_id   = module.nat_gateway.nat_gateway_id
  # nat_gateway_id   = var.create_nat_gateway ? module.nat_gateway.nat_gateway_id : null

  # Ejemplo de rutas personalizadas (opcional)
  # custom_routes = var.custom_routes

  tags = merge({
    Environment = var.environment_name
    },
    var.vpc_custom_tags # Incorpora etiquetas personalizadas del entorno
  )
}
