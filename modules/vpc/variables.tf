# /vpc-project/modules/vpc/variables.tf

variable "vpc_name" {
  description = "Nombre de la VPC. Será utilizado como prefijo para otros recursos dentro de la VPC."
  type        = string
}

variable "vpc_cidr_block" {
  description = "Bloque CIDR para la VPC."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "El valor de vpc_cidr_block debe ser un bloque CIDR válido (ej. '10.0.0.0/16')."
  }
}

variable "enable_dns_hostnames" {
  description = "Indica si las instancias EC2 lanzadas en la VPC obtienen nombres de host DNS."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Indica si la VPC soporta resolución DNS a través del servidor DNS provisto por Amazon."
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "Opción de tenencia para las instancias lanzadas en la VPC. Opciones: 'default', 'dedicated'."
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "El valor de instance_tenancy debe ser 'default' o 'dedicated'."
  }
}

variable "common_tags" {
  description = "Mapa de etiquetas comunes para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
}
