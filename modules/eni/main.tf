# ========================================
# Módulo ENI Reutilizable - main.tf
# ========================================

resource "aws_network_interface" "this" {
  count = var.create_eni ? 1 : 0

  subnet_id               = var.subnet_id
  private_ips             = length(var.private_ips) > 0 ? var.private_ips : null
  private_ip_list_enabled = length(var.private_ips) > 0 ? true : false
  private_ips_count       = length(var.private_ips) == 0 && var.private_ip_count > 0 ? var.private_ip_count : null
  security_groups         = length(var.security_group_ids) > 0 ? var.security_group_ids : null
  source_dest_check       = var.source_dest_check
  description             = var.description != "" ? var.description : "ENI for ${var.eni_name}"
  ipv6_address_count      = var.ipv6_address_count > 0 ? var.ipv6_address_count : null
  ipv6_addresses          = length(var.ipv6_addresses) > 0 ? var.ipv6_addresses : null
  interface_type          = var.interface_type

  tags = merge(
    {
      Name        = var.eni_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.project != "" ? { Project = var.project } : {},
    var.tags
  )
}

resource "aws_network_interface_attachment" "this" {
  count = var.create_eni && var.attach_to_instance ? 1 : 0

  instance_id          = var.instance_id
  network_interface_id = aws_network_interface.this[0].id
  device_index         = var.device_index
}
