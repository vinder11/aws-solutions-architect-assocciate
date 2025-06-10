resource "aws_network_acl_rule" "allow_deny" {
  for_each = {
    for idx, rule in var.allow_deny_rules : idx => rule
  }

  network_acl_id = var.acl_id
  rule_number    = each.value.rule_number
  protocol       = each.value.protocol
  egress         = var.type == "egress" ? true : false
  rule_action    = each.value.rule_action
  cidr_block     = each.value.cidr_block
  # egress         = each.value.type == "egress" ? true : false
  # Configuración de puertos (solo para TCP/UDP)
  from_port = each.value.from_port
  to_port   = each.value.to_port
  # Configuración ICMP (solo para protocolo ICMP)
  icmp_type = each.value.protocol == "icmp" || each.value.protocol == "1" ? each.value.icmp_type : null
  icmp_code = each.value.protocol == "icmp" || each.value.protocol == "1" ? each.value.icmp_code : null

}
