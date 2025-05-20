variable "vpc_id" {
  description = "ID de la VPC donde se creará la tabla de ruteo"
  type        = string
}

variable "route_table_name" {
  description = "Nombre de la tabla de ruteo"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subredes que se asociarán a esta tabla de ruteo"
  type        = list(string)
  default     = []
}

variable "is_public" {
  description = "Indica si esta tabla de ruteo es para subredes públicas (true) o privadas (false)"
  type        = bool
  default     = false
}

variable "internet_gateway_id" {
  description = "ID del Internet Gateway a utilizar para rutas públicas"
  type        = string
  default     = ""
}

variable "nat_gateway_id" {
  description = "ID del NAT Gateway a utilizar para rutas privadas"
  type        = string
  default     = ""
}

variable "custom_routes" {
  description = "Lista de rutas personalizadas para agregar a la tabla de ruteo"
  type = list(object({
    destination_cidr          = string
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    vpc_endpoint_id           = optional(string)
    network_interface_id      = optional(string)
    # instance_id               = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags adicionales para aplicar a los recursos"
  type        = map(string)
  default     = {}
}
