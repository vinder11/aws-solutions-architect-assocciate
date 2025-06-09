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
