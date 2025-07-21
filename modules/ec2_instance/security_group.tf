resource "aws_security_group" "this" {
  count = local.is_module_enabled && var.create_security_group ? 1 : 0
  # ^ Crea el Security Group solo si:
  # 1. El módulo está habilitado (local.is_module_enabled)
  # 2. Se solicita crear un SG (var.create_security_group = true)
  # count=0 o 1 para creación condicional

  name = "${local.name_prefix}-sg"
  # ^ Nombre del Security Group usando el prefijo generado en locals
  # Formato: <nombre>-<ambiente>-<proyecto>-sg

  description = "Security group for EC2 instance ${local.name_prefix}"
  # ^ Descripción clara que indica su propósito

  vpc_id = var.vpc_id
  # ^ ID de la VPC donde se creará el Security Group
  # Requerido porque los SGs son específicos de VPC

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-sg"
    # ^ Tags combinados: default_tags + nombre específico
  })

  lifecycle {
    create_before_destroy = true
    # ^ Estrategia de lifecycle que asegura que el nuevo SG se cree antes de destruir el antiguo
    # Evita interrupciones durante actualizaciones
  }
}

resource "aws_security_group_rule" "this" {
  for_each = local.is_module_enabled && var.create_security_group ? var.security_group_rules : {}
  # ^ Crea reglas usando for_each para iterar sobre el mapa de reglas
  # Solo si:
  # 1. Módulo habilitado
  # 2. Se crea Security Group
  # Usa el mapa var.security_group_rules donde cada clave es un nombre de regla

  security_group_id = aws_security_group.this[0].id
  # ^ Referencia al Security Group creado anteriormente
  # [0] porque aunque count=1, es una lista

  type = each.value.type
  # ^ Tipo de regla: "ingress" (entrada) o "egress" (salida)
  # Tomado del value del mapa en cada iteración

  from_port = each.value.from_port
  # ^ Puerto inicial del rango
  to_port = each.value.to_port
  # ^ Puerto final del rango
  protocol = each.value.protocol
  # ^ Protocolo: "tcp", "udp", "icmp", "-1" (todos), etc.

  description = try(each.value.description, null)
  # ^ Descripción de la regla (opcional)
  # try() evita error si la clave no existe

  # Definición de origen/destino (depende del tipo de regla):
  cidr_blocks = try(each.value.cidr_blocks, null)
  # ^ Lista de CIDRs permitidos/bloqueados
  source_security_group_id = try(each.value.source_security_group_id, null)
  # ^ ID de otro Security Group como origen
  # try() proporciona null si la clave no existe

  # Nota: Solo uno de estos (cidr_blocks o source_security_group_id) debe ser definido por regla
}
