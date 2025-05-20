resource "aws_route_table" "route_table" {
  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = var.route_table_name
      Type = var.is_public ? "public" : "private"
    },
    var.tags
  )
}

# Asociar tabla de ruteo con subredes
resource "aws_route_table_association" "route_table_association" {
  count = length(var.subnet_ids)

  subnet_id      = var.subnet_ids[count.index]
  route_table_id = aws_route_table.route_table.id
}

# Crear ruta hacia Internet Gateway para tablas de ruteo públicas
resource "aws_route" "internet_gateway_route" {
  count = var.is_public && var.internet_gateway_id != "" ? 1 : 0

  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id
}

# Crear ruta hacia NAT Gateway para tablas de ruteo privadas
resource "aws_route" "nat_gateway_route" {
  count = !var.is_public && var.nat_gateway_id != "" ? 1 : 0

  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# Rutas adicionales personalizadas
resource "aws_route" "custom_routes" {
  count = length(var.custom_routes)

  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = var.custom_routes[count.index].destination_cidr

  # Condicionales para determinar qué tipo de destino usar
  gateway_id                = lookup(var.custom_routes[count.index], "gateway_id", null)
  nat_gateway_id            = lookup(var.custom_routes[count.index], "nat_gateway_id", null)
  transit_gateway_id        = lookup(var.custom_routes[count.index], "transit_gateway_id", null)
  vpc_peering_connection_id = lookup(var.custom_routes[count.index], "vpc_peering_connection_id", null)
  vpc_endpoint_id           = lookup(var.custom_routes[count.index], "vpc_endpoint_id", null)
  network_interface_id      = lookup(var.custom_routes[count.index], "network_interface_id", null)
  # instance_id               = lookup(var.custom_routes[count.index], "instance_id", null)
}
