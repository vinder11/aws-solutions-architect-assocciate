# =============================================================================
# EJEMPLOS DE USO
# =============================================================================

# Ejemplo 1: Alarma básica de CPU para EC2
module "ec2_cpu_alarm" {
  source = "../../modules/cloudwatch_alarm"

  alarm_name          = "aws-lab-high-cpu"
  alarm_description   = "Alarma cuando CPU supera 80%"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    InstanceId = module.ec2_instances.instance_ids[0] # Usar el ID de la primera instancia EC2 creada
  }

  alarm_actions = ["arn:aws:automate:us-east-1:ec2:stop"] # Acción de detener la instancia
  # alarm_actions = [aws_sns_topic.alerts.arn]

  tags = var.vpc_custom_tags
}

/*
# Ejemplo 2: Alarma de percentil 99 con estadística extendida
module "rds_latency_alarm" {
  source = "./modules/cloudwatch-alarms"
  
  alarm_name            = "db-high-latency"
  alarm_description     = "Latencia P99 alta en base de datos"
  metric_name          = "ReadLatency"
  namespace            = "AWS/RDS"
  extended_statistic   = "p99"
  period               = 300
  evaluation_periods   = 3
  datapoints_to_alarm  = 2
  threshold            = 0.1
  comparison_operator  = "GreaterThanThreshold"
  treat_missing_data   = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = "prod-database"
  }
  
  alarm_actions = [aws_sns_topic.critical_alerts.arn]
  ok_actions    = [aws_sns_topic.recovery_alerts.arn]
}

# Ejemplo 3: Alarma con múltiples métricas usando metric_queries
module "lambda_composite_alarm" {
  source = "./modules/cloudwatch-alarms"
  
  alarm_name          = "lambda-error-rate"
  alarm_description   = "Tasa de error de Lambda alta"
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  
  metric_queries = [
    {
      id = "errors"
      metric = {
        metric_name = "Errors"
        namespace   = "AWS/Lambda"
        period      = 300
        stat        = "Sum"
        dimensions = {
          FunctionName = "my-lambda-function"
        }
      }
      return_data = false
    },
    {
      id = "invocations"
      metric = {
        metric_name = "Invocations"
        namespace   = "AWS/Lambda"
        period      = 300
        stat        = "Sum"
        dimensions = {
          FunctionName = "my-lambda-function"
        }
      }
      return_data = false
    },
    {
      id          = "error_rate"
      expression  = "errors / invocations * 100"
      label       = "Error Rate (%)"
      return_data = true
    }
  ]
  
  alarm_actions = [aws_sns_topic.lambda_alerts.arn]
}

# Ejemplo 4: Alarma con detector de anomalías
module "anomaly_alarm" {
  source = "./modules/cloudwatch-alarms"
  
  alarm_name          = "network-anomaly"
  alarm_description   = "Detección de anomalías en tráfico de red"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2  # Número de desviaciones estándar
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  
  dimensions = {
    InstanceId = "i-1234567890abcdef0"
  }
  
  anomaly_detector = {
    enabled = true
    stat    = "Average"
    detector_config = {
      excluded_time_ranges = [
        {
          start_time = "2024-12-25T00:00:00Z"
          end_time   = "2024-12-25T23:59:59Z"
        }
      ]
      metric_timezone = "UTC"
    }
  }
  
  alarm_actions = [aws_sns_topic.anomaly_alerts.arn]
}

# Ejemplo 5: Múltiples alarmas usando for_each
locals {
  ec2_instances = {
    web-1 = "i-1234567890abcdef0"
    web-2 = "i-0987654321fedcba0"
    web-3 = "i-abcdef1234567890"
  }
}

module "ec2_alarms" {
  source = "./modules/cloudwatch-alarms"
  
  for_each = local.ec2_instances
  
  alarm_name          = "${each.key}-cpu-high"
  alarm_description   = "CPU alta en instancia ${each.key}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  
  dimensions = {
    InstanceId = each.value
  }
  
  alarm_actions = [aws_sns_topic.ec2_alerts.arn]
  
  tags = {
    Environment = "production"
    Instance    = each.key
  }
}
*/
