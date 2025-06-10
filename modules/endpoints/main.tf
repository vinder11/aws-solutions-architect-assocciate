# Creación de endpoints en AWS VPC
resource "aws_vpc_endpoint" "this" {
  for_each = { for ep in var.endpoints : ep.name => ep }

  vpc_id            = var.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type
  policy            = try(each.value.policy, null)

  # Configuración de rutas para endpoints de tipo Gateway
  # Se asume que las tablas de ruteo se pasan como una lista de IDs
  route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? each.value.route_table_ids : null

  # Interface configurations
  # This is not applicable for Gateway endpoints
  private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? each.value.private_dns_enabled : null
  subnet_ids          = each.value.vpc_endpoint_type == "Interface" ? each.value.subnet_ids : null
  ip_address_type     = each.value.vpc_endpoint_type == "Interface" ? each.value.ip_address_type : null
  security_group_ids = each.value.vpc_endpoint_type == "Interface" ? (
    length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : (var.default_security_group ? [aws_security_group.vpc_endpoints[0].id] : [])
  ) : null

  # Configuración DNS opcional
  dynamic "dns_options" {
    for_each = each.value.dns_options != null ? [each.value.dns_options] : []
    content {
      dns_record_ip_type                             = dns_options.value.dns_record_ip_type
      private_dns_only_for_inbound_resolver_endpoint = try(dns_options.value.private_dns_only_for_inbound_resolver_endpoint, null)
    }
  }

  tags = merge(var.tags, try(each.value.tags, {}), { Name = each.value.name })
  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}
