# Configurar NAT Gateway para la subred privada
module "nat_gateway" {
  source = "../../modules/nat_gateway"

  name_prefix        = "${var.project_name}-${var.environment_name}"
  create_nat_gateway = true
  public_subnet_id   = module.subnets.public_subnet_id[0]
  # private_route_table_id = module.private_route_table.route_table_id
  internet_gateway_id = module.vpc.internet_gateway_id

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment_name}-nat-gateway",
      Environment = var.environment_name
    },
    var.vpc_custom_tags # Incorpora etiquetas personalizadas del entorno
  )
}
