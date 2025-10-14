# ========================================
# Módulo ENI Reutilizable - variables.tf
# ========================================

variable "create_eni" {
  description = "Determina si se debe crear el ENI"
  type        = bool
  default     = true
}

variable "eni_name" {
  description = "Nombre del ENI (se usará en el tag Name)"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde se creará el ENI"
  type        = string
}

variable "private_ips" {
  description = "Lista de IPs privadas para asignar al ENI. La primera será la IP primaria"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.private_ips) <= 50
    error_message = "Un ENI puede tener máximo 50 direcciones IP privadas."
  }
}

variable "private_ip_count" {
  description = "Número de IPs privadas secundarias a asignar automáticamente (si private_ips está vacío)"
  type        = number
  default     = 0
  validation {
    condition     = var.private_ip_count >= 0 && var.private_ip_count <= 49
    error_message = "El número de IPs privadas debe estar entre 0 y 49."
  }
}

variable "security_group_ids" {
  description = "Lista de IDs de security groups a asociar con el ENI"
  type        = list(string)
  default     = []
}

variable "source_dest_check" {
  description = "Habilita o deshabilita el source/destination check"
  type        = bool
  default     = true
}

variable "description" {
  description = "Descripción del ENI"
  type        = string
  default     = ""
}

variable "attach_to_instance" {
  description = "Determina si se debe adjuntar el ENI a una instancia"
  type        = bool
  default     = false
}

variable "instance_id" {
  description = "ID de la instancia EC2 a la que se adjuntará el ENI"
  type        = string
  default     = ""
}

variable "device_index" {
  description = "Índice del dispositivo para el attachment (0 es eth0, 1 es eth1, etc.)"
  type        = number
  default     = 1
  validation {
    condition     = var.device_index >= 0
    error_message = "El device_index debe ser mayor o igual a 0."
  }
}

variable "attachment_delete_on_termination" {
  description = "Si el ENI debe eliminarse cuando se termine la instancia"
  type        = bool
  default     = false
}

variable "ipv6_address_count" {
  description = "Número de direcciones IPv6 a asignar"
  type        = number
  default     = 0
  validation {
    condition     = var.ipv6_address_count >= 0
    error_message = "El número de direcciones IPv6 debe ser mayor o igual a 0."
  }
}

variable "ipv6_addresses" {
  description = "Lista de direcciones IPv6 específicas a asignar"
  type        = list(string)
  default     = []
}

variable "interface_type" {
  description = "Tipo de interfaz de red (interface, efa, trunk)"
  type        = string
  default     = "interface"
  validation {
    condition     = contains(["interface", "efa", "trunk"], var.interface_type)
    error_message = "El interface_type debe ser 'interface', 'efa' o 'trunk'."
  }
}

variable "tags" {
  description = "Mapa de tags adicionales para el ENI"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Ambiente (dev, staging, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = ""
}
