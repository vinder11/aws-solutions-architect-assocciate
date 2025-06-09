# Grupo de seguridad principal
resource "aws_security_group" "this" {
  name                   = var.name
  description            = var.description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = local.common_tags

  timeouts {
    create = var.create_timeout
    delete = var.delete_timeout
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Reglas de entrada
resource "aws_security_group_rule" "ingress_cidr" {
  for_each = {
    for idx, rule in local.all_ingress_rules : idx => rule
    if contains(keys(rule), "cidr_blocks") || contains(keys(rule), "ipv6_cidr_blocks")
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  description      = each.value.description
  from_port        = each.value.from_port
  to_port          = each.value.to_port
  protocol         = each.value.protocol
  cidr_blocks      = try(each.value.cidr_blocks, null)
  ipv6_cidr_blocks = try(each.value.ipv6_cidr_blocks, null)

  depends_on = [aws_security_group.this]
}

resource "aws_security_group_rule" "ingress_self" {
  for_each = {
    for idx, rule in local.all_ingress_rules : idx => rule
    if try(rule.self, false)
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  description = each.value.description
  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.protocol
  self        = true

  depends_on = [aws_security_group.this]
}

resource "aws_security_group_rule" "ingress_sg" {
  for_each = {
    for idx, rule in local.all_ingress_rules : idx => rule
    if length(try(rule.security_groups, [])) > 0
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.security_groups[0]

  depends_on = [aws_security_group.this]
}

resource "aws_security_group_rule" "ingress_prefix_list" {
  for_each = {
    for idx, rule in local.all_ingress_rules : idx => rule
    if length(try(rule.prefix_list_ids, [])) > 0
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id

  description     = each.value.description
  from_port       = each.value.from_port
  to_port         = each.value.to_port
  protocol        = each.value.protocol
  prefix_list_ids = each.value.prefix_list_ids

  depends_on = [aws_security_group.this]
}


# Reglas de salida
resource "aws_security_group_rule" "egress" {
  count = length(var.egress_rules)

  type              = "egress"
  security_group_id = aws_security_group.this.id

  description = var.egress_rules[count.index].description
  from_port   = var.egress_rules[count.index].from_port
  to_port     = var.egress_rules[count.index].to_port
  protocol    = var.egress_rules[count.index].protocol

  cidr_blocks      = try(var.egress_rules[count.index].cidr_blocks, null)
  ipv6_cidr_blocks = try(var.egress_rules[count.index].ipv6_cidr_blocks, null)
  # self             = try(var.egress_rules[count.index].self, false)
  # prefix_list_ids  = try(var.egress_rules[count.index].prefix_list_ids, null)

  depends_on = [aws_security_group.this]
}
