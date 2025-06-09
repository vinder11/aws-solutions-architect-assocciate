# Crear Elastic IP para el NAT Gateway
resource "aws_eip" "nat_eip" {

  domain = "vpc"

  tags = merge(
    {
      Name = "${var.name_prefix}-nat-eip"
    },
    var.tags
  )
}

# Crear NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {

  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.public_subnet_id

  tags = merge(
    {
      Name = "${var.name_prefix}-nat-gateway"
    },
    var.tags
  )

  # Esperar a que el Internet Gateway esté disponible
  depends_on = [var.internet_gateway_id]
}

# Agregar ruta hacia el NAT Gateway para las subredes privadas
resource "aws_route" "nat_gateway_route" {
  count = var.private_route_table_id != "" ? 1 : 0

  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}
