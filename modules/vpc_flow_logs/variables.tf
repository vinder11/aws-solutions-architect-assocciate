# variables.tf

variable "vpc_id" {
  description = "El ID de la VPC para la cual se activarán los Flow Logs."
  type        = string
}

variable "log_destination_type" {
  description = "El tipo de destino para los logs. Valores permitidos: 'cloud-watch-logs' o 's3'."
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.log_destination_type)
    error_message = "Los valores permitidos para log_destination_type son 'cloud-watch-logs' o 's3'."
  }
}

variable "traffic_type" {
  description = "El tipo de tráfico a capturar. Valores permitidos: 'ACCEPT', 'REJECT', 'ALL'."
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.traffic_type)
    error_message = "Los valores permitidos para traffic_type son 'ACCEPT', 'REJECT', 'ALL'."
  }
}

variable "max_aggregation_interval" {
  description = "El intervalo máximo de agregación en segundos. Valor por defecto es 600 segundos (10 minutos)."
  type        = number
  default     = 60
  validation {
    condition     = var.max_aggregation_interval >= 60 && var.max_aggregation_interval <= 21600
    error_message = "El intervalo máximo de agregación debe estar entre 60 y 21600 segundos."
  }
}

variable "log_destination_arn" {
  description = "ARN del destino (CloudWatch Log Group o S3 Bucket). Si no se provee, se creará un recurso nuevo."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "Nombre del CloudWatch Log Group a crear. Solo se usa si log_destination_type es 'cloud-watch-logs' y no se provee log_destination_arn."
  type        = string
  default     = ""
}

variable "log_group_retention_days" {
  description = "Días de retención para el CloudWatch Log Group creado."
  type        = number
  default     = 30
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3 a crear. Solo se usa si log_destination_type es 's3' y no se provee log_destination_arn."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Mapa de etiquetas para aplicar a los recursos creados."
  type        = map(string)
  default     = {}
}
