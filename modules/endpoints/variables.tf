# modules/vpc_endpoints/variables.tf
variable "vpc_id" {
  description = "ID de la VPC donde se crearán los endpoints"
  type        = string
}

variable "default_security_group" {
  description = "Usar el security group por defecto para los endpoints de tipo Interface"
  type        = bool
  default     = false
}

variable "endpoints" {
  description = "Lista de endpoints a crear"
  type = list(object({
    name                = string
    service_name        = string
    vpc_endpoint_type   = optional(string)
    policy              = optional(string)
    route_table_ids     = optional(list(string), [])
    private_dns_enabled = optional(bool, false)
    subnet_ids          = optional(list(string), [])
    ip_address_type     = optional(string, "ipv4")
    security_group_ids  = optional(list(string), [])
    dns_options = optional(object({
      dns_record_ip_type                             = string
      private_dns_only_for_inbound_resolver_endpoint = optional(bool, false)
    }))
    tags = optional(map(string), {})
  }))
  default = []
  validation {
    condition = alltrue([
      for ep in var.endpoints : contains(["Interface", "Gateway"], ep.vpc_endpoint_type)
    ])
    error_message = "El tipo de endpoint debe ser 'Interface' o 'Gateway'."
  }
  validation {
    condition = alltrue([
      for ep in var.endpoints : can(regex(
        "^com.amazonaws.[a-z0-9-]+.[a-z0-9-]+$",
        ep.service_name
        )) || can(regex(
        "^[a-z0-9-]+.[a-z0-9-]+.vpce.amazonaws.com$",
        ep.service_name
      ))
    ])
    error_message = "El service_name debe seguir el formato 'com.amazonaws.region.servicio' o 'servicio.region.vpce.amazonaws.com'."
  }
  validation {
    condition = alltrue([
      for ep in var.endpoints :
      try(ep.policy, null) == null ? true : can(jsondecode(ep.policy))
    ])
    error_message = "El nombre del endpoint debe contener solo caracteres alfanuméricos, puntos, guiones bajos o guiones."
  }
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

variable "create_route53_private_zone" {
  description = "Crear una zona privada Route53 para los endpoints"
  type        = bool
  default     = false
}

variable "route53_zone_name" {
  description = "Nombre de la zona privada Route53"
  type        = string
  default     = "aws.local"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}(\\.[a-zA-Z0-9-]{1,63})*$", var.route53_zone_name))
    error_message = "El nombre de la zona DNS debe ser un nombre de dominio válido."
  }
}

variable "aws_region" {
  description = "Región de AWS donde se crearán los recursos"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "La región debe seguir el formato 'us-east-1', 'eu-west-1', etc."
  }
}
