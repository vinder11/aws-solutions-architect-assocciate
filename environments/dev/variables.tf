# /vpc-project/environments/dev/variables.tf

variable "aws_profile" {
  description = "Perfil de AWS CLI a usar para la configuración."
  type        = string
}

variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos."
  type        = string
  # default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto, usado para prefijos y etiquetas."
  type        = string
  default     = "myproject"
}

variable "environment_name" {
  description = "Nombre del entorno (ej. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "vpc_cidr_block_env" {
  description = "Bloque CIDR para la VPC de este entorno."
  type        = string
}

variable "vpc_custom_tags" {
  description = "Etiquetas personalizadas adicionales para la VPC y sus recursos."
  type        = map(string)
  default     = {}
}

variable "public_subnet_cidr" {
  description = "Bloque CIDR para la subred pública"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Bloque CIDR para la subred privada"
  type        = string
}

variable "nacl_allow_deny_ingress_rules" {
  description = "Lista de reglas de ingreso o salida a crear"
  type = list(object({
    rule_number = number
    protocol    = optional(string, "-1")
    rule_action = optional(string, "allow")
    cidr_block  = optional(string, "0.0.0.0/0")
    from_port   = optional(number, null)
    to_port     = optional(number, null)
    icmp_type   = optional(number, null)
    icmp_code   = optional(number, null)
  }))
  default = []
}

variable "nacl_allow_deny_egress_rules" {
  description = "Lista de reglas de ingreso o salida a crear"
  type = list(object({
    rule_number = number
    protocol    = optional(string, "-1")
    rule_action = optional(string, "allow")
    cidr_block  = optional(string, "0.0.0.0/0")
    from_port   = optional(number, null)
    to_port     = optional(number, null)
    icmp_type   = optional(number, null)
    icmp_code   = optional(number, null)
  }))
  default = []
}
