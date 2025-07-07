# variables.tf

variable "requester_vpc_id" {
  description = "ID de la VPC que inicia la solicitud de peering (Requester)."
  type        = string
}

variable "accepter_vpc_id" {
  description = "ID de la VPC que acepta la solicitud de peering (Accepter)."
  type        = string
}

variable "auto_accept_peering" {
  description = "Si se establece en 'true', el módulo intentará aceptar la conexión automáticamente. Útil para peering dentro de la misma cuenta."
  type        = bool
  default     = true
}

# --- Variables para configuración Cross-Account ---

variable "accepter_aws_account_id" {
  description = "ID de la cuenta de AWS propietaria de la VPC aceptante. Requerido si el peering es entre cuentas."
  type        = string
  default     = null
}

variable "accepter_aws_region" {
  description = "Región de AWS donde se encuentra la VPC aceptante. Requerido para peering entre regiones."
  type        = string
  default     = null
}

# --- Variables para el enrutamiento ---

variable "requester_route_table_ids" {
  description = "Lista de IDs de las tablas de enrutamiento de la VPC solicitante que deben ser actualizadas."
  type        = list(string)
  default     = []
}

variable "accepter_route_table_ids" {
  description = "Lista de IDs de las tablas de enrutamiento de la VPC aceptante que deben ser actualizadas."
  type        = list(string)
  default     = []
}

# --- Variables de metadatos ---

variable "tags" {
  description = "Mapa de etiquetas para aplicar a los recursos creados."
  type        = map(string)
  default     = {}
}
