variable "acl_id" {
  description = "ID de la ACL existente a la que se añadirán las reglas"
  type        = string
  validation {
    condition     = length(var.acl_id) > 0
    error_message = "El ID de la ACL no puede estar vacío."
  }
}
variable "type" {
  description = "Valor que determina si la regla de tráfico es de entrada o salida"
  type        = string
  default     = "ingress"
  validation {
    condition     = contains(["ingress", "egress"], var.type)
    error_message = "El tipo debe ser 'ingress' o 'egress'."
  }
}
variable "allow_deny_rules" {
  description = "Lista de reglas de ingreso o salida a crear"
  type = list(object({
    rule_number = number
    protocol    = optional(string, "-1")
    # type        = optional(string, "ingress") # o "egress" según sea necesario
    rule_action = optional(string, "allow")
    cidr_block  = optional(string, "0.0.0.0/0")
    from_port   = optional(number, null)
    to_port     = optional(number, null)
    icmp_type   = optional(number, null)
    icmp_code   = optional(number, null)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : rule.rule_number >= 1 && rule.rule_number <= 32766
    ])
    error_message = "Todos los números de regla deben estar entre 1 y 32766."
  }

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : contains(["allow", "deny"], rule.rule_action)
    ])
    error_message = "Todas las acciones de regla deben ser 'allow' o 'deny'."
  }

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : contains(["-1", "tcp", "udp", "icmp", "6", "17", "1"], rule.protocol)
    ])
    error_message = "Todos los protocolos deben ser -1, tcp, udp, icmp o sus números equivalentes (6, 17, 1)."
  }

  # validation {
  #   condition = alltrue([
  #     for rule in var.allow_deny_rules : contains(["ingress", "egress"], rule.type)
  #   ])
  #   error_message = "El tipo debe ser 'ingress' o 'egress'."
  # }

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : rule.from_port == null || (rule.from_port >= 0 && rule.from_port <= 65535)
    ])
    error_message = "Todos los puertos de inicio deben estar entre 0 y 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : rule.to_port == null || (rule.to_port >= 0 && rule.to_port <= 65535)
    ])
    error_message = "Todos los puertos finales deben estar entre 0 y 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : rule.icmp_type == null ? true : (
        can(tonumber(rule.icmp_type)) &&
        rule.icmp_type >= -1 &&
        rule.icmp_type <= 255
      )
    ])
    error_message = "Todos los tipos ICMP deben estar entre -1 y 255."
  }

  validation {
    condition = alltrue([
      for rule in var.allow_deny_rules : rule.icmp_code == null ? true : (
        can(tonumber(rule.icmp_code)) &&
        rule.icmp_code >= -1 &&
        rule.icmp_code <= 255
      )
    ])
    error_message = "Todos los códigos ICMP deben estar entre -1 y 255."
  }
}
