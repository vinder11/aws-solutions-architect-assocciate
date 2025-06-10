# variable "acl_id" {
#   description = "ID de la ACL existente a la que se añadirán las reglas"
#   type        = string
#   validation {
#     condition     = length(var.acl_id) > 0
#     error_message = "El ID de la ACL no puede estar vacío."
#   }
# }

# variable "rule_number" {
#   description = "Número de regla para el tráfico de entrada o salida"
#   type        = number
#   default     = 100
#   validation {
#     condition     = var.rule_number >= 1 && var.rule_number <= 32766
#     error_message = "El número de regla debe estar entre 1 y 32766."
#   }
# }

# variable "protocol" {
#   description = "Protocolo para la regla de entrada o salida (-1 para todos, tcp, udp, icmp)"
#   type        = string
#   default     = "-1"
#   validation {
#     condition     = contains(["-1", "tcp", "udp", "icmp", "6", "17", "1"], var.protocol)
#     error_message = "El protocolo debe ser -1, tcp, udp, icmp o sus números equivalentes (6, 17, 1)."
#   }
# }

# variable "type" {
#   description = "Valor que determina si la regla de tráfico es de entrada o salida"
#   type        = string
#   default     = "ingress"
#   validation {
#     condition     = contains(["ingress", "egress"], var.type)
#     error_message = "El tipo debe ser 'ingress' o 'egress'."
#   }
# }

# variable "rule_action" {
#   description = "Acción de la regla (allow o deny)"
#   type        = string
#   default     = "allow"
#   validation {
#     condition     = contains(["allow", "deny"], var.rule_action)
#     error_message = "La acción de la regla debe ser 'allow' o 'deny'."
#   }
# }

# variable "cidr_block" {
#   description = "Bloque CIDR para la regla. Por defecto, permite todo el tráfico IPv4."
#   type        = string
#   default     = "0.0.0.0/0"
# }

# variable "from_port" {
#   description = "Puerto de inicio para la regla de entrada (0-65535, null para todos los puertos)"
#   type        = number
#   default     = null
#   validation {
#     condition     = var.from_port == null || (var.from_port >= 0 && var.from_port <= 65535)
#     error_message = "El puerto debe estar entre 0 y 65535."
#   }
# }

# variable "to_port" {
#   description = "Puerto final para la regla de entrada (0-65535, null para todos los puertos)"
#   type        = number
#   default     = null
#   validation {
#     condition     = var.to_port == null || (var.to_port >= 0 && var.to_port <= 65535)
#     error_message = "El puerto debe estar entre 0 y 65535."
#   }
# }

# variable "icmp_type" {
#   description = "Tipo ICMP para regla de entrada (-1 para todos, solo aplicable si protocolo es icmp)"
#   type        = number
#   default     = null
#   validation {
#     condition = var.icmp_type == null ? true : (
#       can(tonumber(var.icmp_type)) &&
#       var.icmp_type >= -1 &&
#       var.icmp_type <= 255
#     )
#     error_message = "El tipo ICMP debe estar entre -1 y 255."
#   }
# }

# variable "icmp_code" {
#   description = "Código ICMP para regla de entrada (-1 para todos, solo aplicable si protocolo es icmp)"
#   type        = number
#   default     = null
#   validation {
#     condition = var.icmp_code == null ? true : (
#       can(tonumber(var.icmp_code)) &&
#       var.icmp_code >= -1 &&
#       var.icmp_code <= 255
#     )
#     error_message = "El código ICMP debe estar entre -1 y 255."
#   }
# }
