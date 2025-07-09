# variables.tf

variable "name" {
  description = "Nombre para el Transit Gateway y recursos asociados."
  type        = string
}

variable "description" {
  description = "Descripción para el Transit Gateway."
  type        = string
  default     = "Transit Gateway gestionado por Terraform"
}

variable "amazon_side_asn" {
  # El rango de ASN privados es 64512-65534, pero se puede usar el rango 4200000000-4294967294 para ASN privados de 32 bits.
  description = "Número de Sistema Autónomo (ASN) privado para el lado de Amazon del gateway." # Si no se especifica, AWS asigna uno automáticamente. y tambien se espifica si es para conexiones VPN.
  type        = number
  default     = 64512
}

variable "dns_support" {
  description = "Habilita o deshabilita el soporte DNS."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.dns_support)
    error_message = "El valor para dns_support debe ser 'enable' o 'disable'."
  }
}

variable "vpn_ecmp_support" {
  description = "Habilita o deshabilita Equal-cost multi-path (ECMP). Valores permitidos: 'enable', 'disable'."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.vpn_ecmp_support)
    error_message = "El valor para vpn_ecmp_support debe ser 'enable' o 'disable'."
  }
}

variable "default_route_table_association" {
  description = "Habilita o deshabilita la asociación automática. Valores permitidos: 'enable', 'disable'."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_association)
    error_message = "El valor para default_route_table_association debe ser 'enable' o 'disable'."
  }
}

variable "default_route_table_propagation" {
  description = "Habilita o deshabilita la propagación automática. Valores permitidos: 'enable', 'disable'."
  type        = string
  default     = "enable"
  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_propagation)
    error_message = "El valor para default_route_table_propagation debe ser 'enable' o 'disable'."
  }
}

variable "auto_accept_shared_attachments" {
  description = "Habilita o deshabilita la aceptación automática. Valores permitidos: 'enable', 'disable'."
  type        = string
  default     = "disable"
  validation {
    condition     = contains(["enable", "disable"], var.auto_accept_shared_attachments)
    error_message = "El valor para auto_accept_shared_attachments debe ser 'enable' o 'disable'."
  }
}

variable "share_with_principal_arns" {
  description = "Lista de ARNs de Cuentas de AWS o de una Organización/OU para compartir el TGW."
  type        = list(string)
  default     = []
}

variable "vpc_attachments" {
  description = "Mapa de VPCs a adjuntar al Transit Gateway. La clave es un nombre para el adjunto y el valor contiene vpc_id y subnet_ids."
  type = map(object({
    vpc_id     = string
    subnet_ids = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Mapa de etiquetas para aplicar a los recursos."
  type        = map(string)
  default     = {}
}
