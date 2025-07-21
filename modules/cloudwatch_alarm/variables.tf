# variables.tf
# =============================================================================

variable "alarm_name" {
  description = "Nombre base de la alarma"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.alarm_name))
    error_message = "El nombre de la alarma solo puede contener letras, números, guiones y guiones bajos."
  }
}

variable "alarm_description" {
  description = "Descripción de la alarma"
  type        = string
  default     = null
}

variable "metric_name" {
  description = "Nombre de la métrica de CloudWatch"
  type        = string
}

variable "namespace" {
  description = "Namespace de la métrica (ej: AWS/EC2, AWS/RDS, AWS/Lambda)"
  type        = string
}

variable "statistic" {
  description = "Estadística a aplicar (Average, Sum, Maximum, Minimum, SampleCount)"
  type        = string
  default     = "Average"
  validation {
    condition     = contains(["Average", "Sum", "Maximum", "Minimum", "SampleCount"], var.statistic)
    error_message = "La estadística debe ser una de: Average, Sum, Maximum, Minimum, SampleCount."
  }
}

variable "period" {
  description = "Período en segundos para evaluar la métrica"
  type        = number
  default     = 300
  validation {
    condition     = var.period >= 60 && var.period % 60 == 0
    error_message = "El período debe ser mínimo 60 segundos y múltiplo de 60."
  }
}

variable "evaluation_periods" {
  description = "Número de períodos sobre los cuales evaluar la métrica"
  type        = number
  default     = 2
  validation {
    condition     = var.evaluation_periods >= 1 && var.evaluation_periods <= 100
    error_message = "Los períodos de evaluación deben estar entre 1 y 100."
  }
}

variable "datapoints_to_alarm" {
  description = "Número de puntos de datos que deben estar en estado de alarma para activarla"
  type        = number
  default     = 1
  validation {
    condition     = var.datapoints_to_alarm != null || var.datapoints_to_alarm >= 1
    error_message = "Los puntos de datos para alarma deben estar entre 1 y el número de períodos de evaluación."
  }
}

variable "threshold" {
  description = "Valor umbral para la alarma"
  type        = number
}

variable "comparison_operator" {
  description = "Operador de comparación para el umbral"
  type        = string
  validation {
    condition = contains([
      "GreaterThanOrEqualToThreshold",
      "GreaterThanThreshold",
      "LessThanThreshold",
      "LessThanOrEqualToThreshold",
      "LessThanLowerOrGreaterThanUpperThreshold",
      "LessThanLowerThreshold",
      "GreaterThanUpperThreshold"
    ], var.comparison_operator)
    error_message = "Operador de comparación no válido."
  }
}

variable "dimensions" {
  description = "Dimensiones para filtrar la métrica"
  type        = map(string)
  default     = {}
}

variable "alarm_actions" {
  description = "Lista de ARNs de acciones a ejecutar cuando la alarma se activa"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Lista de ARNs de acciones a ejecutar cuando la alarma vuelve al estado OK"
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "Lista de ARNs de acciones para datos insuficientes"
  type        = list(string)
  default     = []
}

variable "treat_missing_data" {
  description = "Cómo tratar datos faltantes (notBreaching, breaching, ignore, missing)"
  type        = string
  default     = "missing"
  validation {
    condition     = contains(["notBreaching", "breaching", "ignore", "missing"], var.treat_missing_data)
    error_message = "El tratamiento de datos faltantes debe ser: notBreaching, breaching, ignore, o missing."
  }
}

variable "evaluate_low_sample_count_percentiles" {
  description = "Cómo evaluar percentiles con bajo conteo de muestras (evaluate, ignore)"
  type        = string
  default     = null
  # validation {
  #   condition     = contains(["evaluate", "ignore"], var.evaluate_low_sample_count_percentiles)
  #   error_message = "Debe ser 'evaluate' o 'ignore'."
  # }
}

variable "extended_statistic" {
  description = "Estadística extendida (percentil) en lugar de statistic estándar"
  type        = string
  default     = null
  validation {
    condition     = var.extended_statistic == null || can(regex("^p(0|([1-9][0-9]?)|(100))(\\.\\d+)?$", var.extended_statistic))
    error_message = "La estadística extendida debe ser un percentil válido (ej: p99, p95.5)."
  }
}

variable "unit" {
  description = "Unidad de medida de la métrica"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags a aplicar a la alarma"
  type        = map(string)
  default     = {}
}

variable "alarm_prefix" {
  description = "Prefijo para el nombre de la alarma"
  type        = string
  default     = ""
}

variable "alarm_suffix" {
  description = "Sufijo para el nombre de la alarma"
  type        = string
  default     = ""
}

variable "create_alarm" {
  description = "Flag para crear o no la alarma"
  type        = bool
  default     = true
}

# Opciones avanzadas para métricas compuestas
variable "metric_queries" {
  description = "Lista de consultas de métricas para alarmas basadas en múltiples métricas"
  type = list(object({
    id          = string
    label       = optional(string)
    return_data = optional(bool, true)

    # Para métricas normales
    metric = optional(object({
      metric_name = string
      namespace   = string
      period      = number
      stat        = string
      unit        = optional(string)
      dimensions  = optional(map(string), {})
    }))

    # Para expresiones matemáticas
    expression = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for query in var.metric_queries :
      (query.metric != null && query.expression == null) ||
      (query.metric == null && query.expression != null)
    ])
    error_message = "Cada query debe tener o 'metric' o 'expression', pero no ambos."
  }
}

# variable "anomaly_detector" {
#   description = "Configuración para detector de anomalías"
#   type = object({
#     enabled    = bool
#     dimensions = optional(map(string), {})
#     stat       = optional(string, "Average")

#     # Configuración del detector
#     detector_config = optional(object({
#       excluded_time_ranges = optional(list(object({
#         start_time = string
#         end_time   = string
#       })), [])

#       metric_timezone = optional(string)
#     }))
#   })
#   default = {
#     enabled = false
#   }
# }
