# modules/subnet/variables.tf

variable "name" {
  description = "Prefijo del nombre para todas las subredes"
  type        = string
  default     = "main"
}

variable "vpc_id" {
  description = "ID de la VPC donde se crearán las subredes"
  type        = string
}

variable "azs" {
  description = "Lista de zonas de disponibilidad donde se crearán las subredes"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "subnets" {
  description = "Mapa de subredes a crear con sus configuraciones"
  type        = map(any)
  default     = {}
  # Ejemplo de uso:
  # subnets = {
  #   public1 = {
  #     cidr_block = "192.168.0.0/24"
  #     public     = true
  #     tags       = { Purpose = "Web Servers" }
  #   },
  #   private1 = {
  #     cidr_block = "192.168.1.0/24"
  #     public     = false
  #     tags       = { Purpose = "Database" }
  #   }
  # }
}

variable "tags" {
  description = "Mapa de etiquetas para agregar a todos los recursos"
  type        = map(string)
  default     = {}
}
