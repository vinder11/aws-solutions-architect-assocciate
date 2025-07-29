# variables.tf
variable "role_name" {
  description = "Nombre del rol IAM"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.role_name))
    error_message = "El nombre del rol debe contener solo caracteres alfanuméricos y los símbolos: +=,.@_-"
  }
}

variable "role_description" {
  description = "Descripción del rol IAM"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Política de asunción del rol en formato JSON"
  type        = string
  default     = null

  validation {
    condition     = var.assume_role_policy == null || can(jsondecode(var.assume_role_policy))
    error_message = "La política de asunción debe ser un JSON válido."
  }
}

variable "trusted_entities" {
  description = "Lista de entidades que pueden asumir el rol"
  type = object({
    services     = optional(list(string), [])
    aws_accounts = optional(list(string), [])
    federated    = optional(list(string), [])
    users        = optional(list(string), [])
    roles        = optional(list(string), [])
  })
  default = {
    services     = []
    aws_accounts = []
    federated    = []
    users        = []
    roles        = []
  }
}

variable "managed_policies" {
  description = "Lista de ARNs de políticas administradas por AWS a adjuntar"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for policy in var.managed_policies :
      can(regex("^arn:aws:iam::(aws|[0-9]{12}):policy/", policy))
    ])
    error_message = "Todos los elementos deben ser ARNs válidos de políticas IAM."
  }
}

variable "inline_policies" {
  description = "Mapa de políticas inline a crear (nombre -> documento JSON)"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for policy_doc in values(var.inline_policies) :
      can(jsondecode(policy_doc))
    ])
    error_message = "Todas las políticas inline deben ser documentos JSON válidos."
  }
}

variable "max_session_duration" {
  description = "Duración máxima de la sesión en segundos (3600-43200)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "La duración máxima de sesión debe estar entre 3600 y 43200 segundos."
  }
}

variable "path" {
  description = "Ruta del rol IAM"
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/.*/$", var.path))
    error_message = "La ruta debe comenzar y terminar con '/'."
  }
}

variable "permissions_boundary" {
  description = "ARN de la política que define el límite de permisos"
  type        = string
  default     = null

  validation {
    condition     = var.permissions_boundary == null || can(regex("^arn:aws:iam::[0-9]{12}:policy/", var.permissions_boundary))
    error_message = "El boundary de permisos debe ser un ARN válido de política IAM."
  }
}

variable "force_detach_policies" {
  description = "Si forzar el desvinculo de políticas antes de eliminar el rol"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Mapa de etiquetas para aplicar al rol"
  type        = map(string)
  default     = {}
}
