# main.tf

# Recurso para asignar una nueva Elastic IP en el ámbito de la VPC
resource "aws_eip" "main" {
  # 'domain = "vpc"' es el valor implícito y recomendado actualmente.
  # Para versiones anteriores del provider, se usaba 'vpc = true'.
  domain                   = "vpc"
  customer_owned_ipv4_pool = var.customer_owned_ipv4_pool

  tags = var.tags
}

# Recurso para asociar la EIP a un recurso, si se especifica
resource "aws_eip_association" "main" {
  # Solo se crea este recurso si se pasa un ID de instancia o de ENI
  count = var.associate_with_instance_id != null || var.associate_with_network_interface_id != null ? 1 : 0

  instance_id          = var.associate_with_instance_id
  network_interface_id = var.associate_with_network_interface_id
  allocation_id        = aws_eip.main.allocation_id
}
