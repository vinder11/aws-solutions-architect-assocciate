# =============================================================================
# main.tf
# =============================================================================

locals {
  # Construir el nombre completo de la alarma
  full_alarm_name = "${var.alarm_prefix}${var.alarm_name}${var.alarm_suffix}"

  # Determinar si usar estadística estándar o extendida
  use_extended_statistic = var.extended_statistic != null

  # Tags finales combinando los por defecto con los del usuario
  final_tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "cloudwatch-alarms"
    },
    var.tags
  )
}

# Detector de anomalías (opcional)
# resource "aws_cloudwatch_anomaly_detector" "this" {
# count = var.anomaly_detector.enabled ? 1 : 0

# metric_name = var.metric_name
# namespace   = var.namespace
# stat        = var.anomaly_detector.stat
# dimensions  = var.anomaly_detector.dimensions

# dynamic "single_metric_anomaly_detector" {
# for_each = var.anomaly_detector.detector_config != null ? [var.anomaly_detector.detector_config] : []
# content {
# dynamic "excluded_time_ranges" {
#   for_each = single_metric_anomaly_detector.value.excluded_time_ranges
#   content {
#     start_time = excluded_time_ranges.value.start_time
#     end_time   = excluded_time_ranges.value.end_time
#   }
# }

# metric_timezone = single_metric_anomaly_detector.value.metric_timezone
# }
# }

# tags = local.final_tags
# }

# Alarma principal
resource "aws_cloudwatch_metric_alarm" "this" {
  count = var.create_alarm ? 1 : 0

  alarm_name        = local.full_alarm_name
  alarm_description = var.alarm_description

  # Configuración de métrica básica (solo si no hay metric_queries)
  metric_name        = length(var.metric_queries) == 0 ? var.metric_name : null
  namespace          = length(var.metric_queries) == 0 ? var.namespace : null
  statistic          = length(var.metric_queries) == 0 && !local.use_extended_statistic ? var.statistic : null
  extended_statistic = length(var.metric_queries) == 0 && local.use_extended_statistic ? var.extended_statistic : null
  period             = length(var.metric_queries) == 0 ? var.period : null
  unit               = length(var.metric_queries) == 0 ? var.unit : null
  dimensions         = length(var.metric_queries) == 0 ? var.dimensions : null

  # Métricas compuestas
  dynamic "metric_query" {
    for_each = var.metric_queries
    content {
      id          = metric_query.value.id
      label       = metric_query.value.label
      return_data = metric_query.value.return_data

      dynamic "metric" {
        for_each = metric_query.value.metric != null ? [metric_query.value.metric] : []
        content {
          metric_name = metric.value.metric_name
          namespace   = metric.value.namespace
          period      = metric.value.period
          stat        = metric.value.stat
          unit        = metric.value.unit
          dimensions  = metric.value.dimensions
        }
      }

      expression = metric_query.value.expression
    }
  }

  # Configuración de evaluación
  comparison_operator                   = var.comparison_operator
  threshold                             = var.threshold
  evaluation_periods                    = var.evaluation_periods
  datapoints_to_alarm                   = var.datapoints_to_alarm <= var.evaluation_periods ? var.datapoints_to_alarm : var.evaluation_periods
  treat_missing_data                    = var.treat_missing_data
  evaluate_low_sample_count_percentiles = var.evaluate_low_sample_count_percentiles

  # Acciones
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = local.final_tags

  # depends_on = [aws_cloudwatch_anomaly_detector.this]
}
