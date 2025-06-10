# resource "aws_network_acl_rule" "allow_deny" {
#   network_acl_id = var.acl_id
#   rule_number    = var.rule_number
#   protocol       = var.protocol
#   egress         = var.type == "egress" ? true : false
#   rule_action    = var.rule_action
#   cidr_block     = var.cidr_block

#   # Configuración de puertos (solo para TCP/UDP)
#   from_port = var.protocol != "-1" && var.protocol != "icmp" && var.protocol != "1" ? var.from_port : null
#   to_port   = var.protocol != "-1" && var.protocol != "icmp" && var.protocol != "1" ? var.to_port : null

#   # Configuración ICMP (solo para protocolo ICMP)
#   icmp_type = var.protocol == "icmp" || var.protocol == "1" ? var.icmp_type : null
#   icmp_code = var.protocol == "icmp" || var.protocol == "1" ? var.icmp_code : null
# }
