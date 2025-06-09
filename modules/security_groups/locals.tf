# Locals para generar reglas combinadas
locals {
  # Combinar reglas predefinidas con reglas personalizadas
  preset_ingress_rules = concat(
    var.enable_http ? [{
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.http_cidr_blocks
    }] : [],
    var.enable_https ? [{
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.https_cidr_blocks
    }] : [],
    var.enable_ssh ? [{
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidr_blocks
    }] : [],
    var.enable_rdp ? [{
      description = "RDP"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = var.rdp_cidr_blocks
    }] : []
  )

  # Combinar reglas preset con reglas personalizadas
  all_ingress_rules = concat(local.preset_ingress_rules, var.ingress_rules)

  # Tags combinados
  common_tags = merge(
    {
      Name      = var.name
      ManagedBy = "terraform"
      Type      = "security-group"
      VPC       = var.vpc_id
    },
    var.additional_tags
  )
}
