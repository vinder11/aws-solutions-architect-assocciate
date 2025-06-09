variable "vpc_id" {
  description = "ID de la VPC donde se creará el grupo de seguridad"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-zA-Z0-9]+$", var.vpc_id))
    error_message = "El VPC ID debe tener formato válido (vpc-xxxxxxxx)."
  }
}

variable "name" {
  description = "Nombre del grupo de seguridad"
  type        = string
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 255
    error_message = "El nombre debe tener entre 1 y 255 caracteres."
  }
}

variable "description" {
  description = "Descripción del grupo de seguridad"
  type        = string
  default     = "Security group managed by Terraform"
  validation {
    condition     = length(var.description) <= 255
    error_message = "La descripción no puede exceder 255 caracteres."
  }
}

variable "ingress_rules" {
  description = "Lista de reglas de entrada"
  type = list(object({
    description      = optional(string, "Ingress rule")
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
    prefix_list_ids  = optional(list(string), [])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.ingress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      rule.from_port <= rule.to_port
    ])
    error_message = "Los puertos deben estar entre 0-65535 y from_port <= to_port."
  }
}

variable "egress_rules" {
  description = "Lista de reglas de salida"
  type = list(object({
    description      = optional(string, "Egress rule")
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
    security_groups  = optional(list(string), [])
    self             = optional(bool, false)
    prefix_list_ids  = optional(list(string), [])
  }))
  default = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  validation {
    condition = alltrue([
      for rule in var.egress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535 &&
      rule.to_port >= 0 && rule.to_port <= 65535 &&
      (rule.protocol == "-1" || rule.from_port <= rule.to_port)
    ])
    error_message = "Los puertos deben estar entre 0-65535 y from_port <= to_port (excepto protocolo -1)."
  }
}

variable "revoke_rules_on_delete" {
  description = "Revocar todas las reglas del grupo de seguridad al eliminarlo"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Tags adicionales para aplicar al grupo de seguridad"
  type        = map(string)
  default     = {}
}

variable "create_timeout" {
  description = "Timeout para la creación del grupo de seguridad"
  type        = string
  default     = "10m"
}

variable "delete_timeout" {
  description = "Timeout para la eliminación del grupo de seguridad"
  type        = string
  default     = "15m"
}

# Presets comunes
variable "enable_http" {
  description = "Habilitar regla HTTP (puerto 80)"
  type        = bool
  default     = false
}

variable "enable_https" {
  description = "Habilitar regla HTTPS (puerto 443)"
  type        = bool
  default     = false
}

variable "enable_ssh" {
  description = "Habilitar regla SSH (puerto 22)"
  type        = bool
  default     = false
}

variable "enable_rdp" {
  description = "Habilitar regla RDP (puerto 3389)"
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks permitidos para SSH"
  type        = list(string)
  default     = []
}

variable "http_cidr_blocks" {
  description = "CIDR blocks permitidos para HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR blocks permitidos para HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rdp_cidr_blocks" {
  description = "CIDR blocks permitidos para RDP"
  type        = list(string)
  default     = []
}
