# variables.tf

variable "key_name" {
  description = "El nombre único para el Key Pair en AWS."
  type        = string

  validation {
    # Asegura que el nombre no contenga espacios ni caracteres inválidos.
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.key_name))
    error_message = "El nombre del Key Pair solo puede contener letras, números, puntos, guiones bajos y guiones."
  }
}

variable "public_key" {
  description = "El contenido de la clave pública (generalmente del archivo .pub)."
  type        = string
  sensitive   = true # Aunque es pública, se trata como sensible para no mostrarla en logs.

  validation {
    # Validación simple para asegurar que el formato de la clave pública es plausible.
    condition     = substr(var.public_key, 0, 4) == "ssh-"
    error_message = "La clave pública debe comenzar con 'ssh-rsa', 'ssh-ed25519', etc."
  }
}

variable "tags" {
  description = "Un mapa de etiquetas para aplicar al recurso Key Pair."
  type        = map(string)
  default     = {}
}
