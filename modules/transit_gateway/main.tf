# main.tf

# Recurso principal del Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments

  tags = merge(var.tags, {
    Name = var.name
  })
}

# --- Compartir el TGW con otras cuentas (Opcional) ---
resource "aws_ram_resource_share" "main" {
  # Solo crear si se proveen ARNs para compartir
  count = length(var.share_with_principal_arns) > 0 ? 1 : 0

  name                      = "${var.name}-resource-share"
  allow_external_principals = true # Necesario para compartir fuera de una AWS Organization

  tags = merge(var.tags, {
    Name = "${var.name}-resource-share"
  })
}

resource "aws_ram_resource_association" "main" {
  # Asociar el TGW al recurso compartido de RAM
  count = length(var.share_with_principal_arns) > 0 ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.main.arn
  resource_share_arn = aws_ram_resource_share.main[0].arn
}

resource "aws_ram_principal_association" "main" {
  # Iterar sobre la lista de ARNs para asociarlos al recurso compartido
  for_each = { for arn in var.share_with_principal_arns : arn => arn }

  principal          = each.key
  resource_share_arn = aws_ram_resource_share.main[0].arn
}


# --- Adjuntar VPCs (Opcional) ---
resource "aws_ec2_transit_gateway_vpc_attachment" "main" {
  # Iterar sobre el mapa de VPCs a adjuntar
  for_each = var.vpc_attachments

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.subnet_ids # Subnets donde se crearán las ENIs del TGW

  tags = merge(var.tags, {
    Name = "tgw-attach-${each.key}"
  })
}
