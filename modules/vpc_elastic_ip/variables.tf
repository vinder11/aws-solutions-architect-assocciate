# variables.tf

variable "tags" {
  description = "Mapa de etiquetas para aplicar a la Elastic IP."
  type        = map(string)
  default     = {}
}

# --- Variables de Asociación (Opcionales) ---

variable "associate_with_instance_id" {
  description = "Opcional. El ID de la instancia EC2 con la que se asociará la EIP."
  type        = string
  default     = null
}

variable "associate_with_network_interface_id" {
  description = "Opcional. El ID de la Interfaz de Red (ENI) con la que se asociará la EIP."
  type        = string
  default     = null
}

# --- Variables Avanzadas ---

variable "customer_owned_ipv4_pool" {
  description = "Opcional. El pool de IPs propiedad del cliente (BYOIP) desde el cual asignar la EIP."
  type        = string
  default     = null
}
