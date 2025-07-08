# main.tf

# --- Obtener información de las VPCs ---
# Necesitamos los bloques CIDR para crear las rutas correctamente.
data "aws_vpc" "requester" {
  id       = var.requester_vpc_id
  provider = aws.requester
}

data "aws_vpc" "accepter" {
  # Si es cross-region, necesitamos un provider específico
  id       = var.accepter_vpc_id
  provider = aws.accepter
}


# --- Recurso de VPC Peering Connection ---
# Este recurso siempre se crea desde la cuenta solicitante (requester).
resource "aws_vpc_peering_connection" "main" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = var.accepter_aws_account_id
  peer_region   = var.accepter_aws_region
  auto_accept   = var.auto_accept_peering

  tags = merge(var.tags, {
    Name = "vpc-peering-${data.aws_vpc.requester.cidr_block}-${data.aws_vpc.accepter.cidr_block}"
  })
  provider = aws.requester
}


# --- Aceptador de la Conexión ---
# Este recurso es necesario si 'auto_accept' es falso o si es un peering cross-account/region.
# Terraform lo gestionará desde el provider del aceptante.
resource "aws_vpc_peering_connection_accepter" "accepter" {
  # Solo se activa si auto_accept es falso, para manejar la aceptación explícitamente.
  count = !var.auto_accept_peering ? 1 : 0

  # Si es cross-region, usamos el provider del aceptante
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = "vpc-peering-accepter-${aws_vpc_peering_connection.main.id}"
  })

  lifecycle {
    ignore_changes = [
      # Ignoramos cambios en el ID de la conexión, ya que no se puede cambiar una vez creada.
      tags
    ]
  }

  provider = aws.accepter
}


# --- Actualización de Tablas de Enrutamiento ---

# Rutas en la VPC solicitante (Requester)
resource "aws_route" "requester" {
  # Itera sobre la lista de IDs de tablas de enrutamiento proporcionada
  count = length(var.requester_route_table_ids)

  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.accepter.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  # La creación de la ruta depende de que la conexión esté activa
  depends_on = [aws_vpc_peering_connection.main, aws_vpc_peering_connection_accepter.accepter]
  provider   = aws.requester
}

# Rutas en la VPC aceptante (Accepter)
resource "aws_route" "accepter" {
  # Si es cross-region, usamos el provider del aceptante
  provider = aws.accepter

  # Itera sobre la lista de IDs de tablas de enrutamiento proporcionada
  count = length(var.accepter_route_table_ids)

  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = data.aws_vpc.requester.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  depends_on = [aws_vpc_peering_connection.main, aws_vpc_peering_connection_accepter.accepter]
}
