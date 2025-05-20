variable "name_prefix" {
  description = "Prefijo para nombres de recursos"
  type        = string
  default     = "main"
}

variable "create_nat_gateway" {
  description = "Determina si se debe crear un NAT Gateway"
  type        = bool
  default     = false
}

variable "public_subnet_id" {
  description = "ID de la subred pública donde se creará el NAT Gateway"
  type        = string
  default     = ""
}

variable "private_route_table_id" {
  description = "ID de la tabla de ruteo de la subred privada donde se agregará la ruta al NAT Gateway"
  type        = string
  default     = ""
}

variable "internet_gateway_id" {
  description = "ID del Internet Gateway para la dependencia"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags adicionales para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
