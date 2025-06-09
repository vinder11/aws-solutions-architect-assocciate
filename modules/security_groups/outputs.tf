# outputs.tf
output "security_group_id" {
  description = "ID del grupo de seguridad creado"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN del grupo de seguridad creado"
  value       = aws_security_group.this.arn
}

output "security_group_name" {
  description = "Nombre del grupo de seguridad creado"
  value       = aws_security_group.this.name
}

output "security_group_description" {
  description = "Descripción del grupo de seguridad creado"
  value       = aws_security_group.this.description
}

output "security_group_vpc_id" {
  description = "ID de la VPC del grupo de seguridad"
  value       = aws_security_group.this.vpc_id
}

output "security_group_owner_id" {
  description = "ID del propietario del grupo de seguridad"
  value       = aws_security_group.this.owner_id
}

output "egress_rules" {
  description = "Lista de reglas de salida aplicadas"
  value = [
    for rule in aws_security_group_rule.egress : {
      description = rule.description
      from_port   = rule.from_port
      to_port     = rule.to_port
      protocol    = rule.protocol
      cidr_blocks = rule.cidr_blocks
    }
  ]
}

output "security_group_tags" {
  description = "Tags aplicados al grupo de seguridad"
  value       = aws_security_group.this.tags
}

output "ingress_rules" {
  value = flatten([
    [
      for rule in aws_security_group_rule.ingress_cidr : {
        id          = rule.id
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
        type        = rule.type
        cidr_blocks = rule.cidr_blocks
      }
    ],
    [
      for rule in aws_security_group_rule.ingress_self : {
        id          = rule.id
        description = rule.description
        from_port   = rule.from_port
        to_port     = rule.to_port
        protocol    = rule.protocol
        type        = rule.type
        self        = rule.self
      }
    ],
    [
      for rule in aws_security_group_rule.ingress_sg : {
        id                       = rule.id
        description              = rule.description
        from_port                = rule.from_port
        to_port                  = rule.to_port
        protocol                 = rule.protocol
        type                     = rule.type
        source_security_group_id = rule.source_security_group_id
      }
    ],
    [
      for rule in aws_security_group_rule.ingress_prefix_list : {
        id              = rule.id
        description     = rule.description
        from_port       = rule.from_port
        to_port         = rule.to_port
        protocol        = rule.protocol
        type            = rule.type
        prefix_list_ids = rule.prefix_list_ids
      }
    ]
  ])
}

