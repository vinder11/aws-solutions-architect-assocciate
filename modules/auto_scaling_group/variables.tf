# variables.tf
variable "name" {
  description = "Nombre base para los recursos de Auto Scaling"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el Auto Scaling"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para el Auto Scaling Group"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "Debe proporcionar al menos una subnet"
  }
}

variable "use_external_launch_template" {
  description = "Si es true, usa un Launch Template externo en lugar de crear uno nuevo"
  type        = bool
  default     = false
}

variable "external_launch_template_id" {
  description = "ID del Launch Template externo (requerido si use_external_launch_template es true)"
  type        = string
  default     = null
}

variable "external_launch_template_version" {
  description = "Versión del Launch Template externo a usar ($Latest, $Default, o número de versión)"
  type        = string
  default     = "$Latest"
}

variable "ami_id" {
  description = "ID de la AMI para las instancias EC2 (requerido si use_external_launch_template es false)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair para acceso SSH"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Número mínimo de instancias"
  type        = number
  default     = 1
  validation {
    condition     = var.min_size >= 0
    error_message = "min_size debe ser mayor o igual a 0"
  }
}

variable "max_size" {
  description = "Número máximo de instancias"
  type        = number
  default     = 3
  validation {
    condition     = var.max_size > 0
    error_message = "max_size debe ser mayor a 0"
  }
}

variable "desired_capacity" {
  description = "Capacidad deseada inicial"
  type        = number
  default     = 2
  validation {
    condition     = var.desired_capacity >= 0
    error_message = "desired_capacity debe ser mayor o igual a 0"
  }
}

variable "health_check_type" {
  description = "Tipo de health check (EC2 o ELB)"
  type        = string
  default     = "EC2"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type debe ser EC2 o ELB"
  }
}

variable "health_check_grace_period" {
  description = "Período de gracia para health checks en segundos"
  type        = number
  default     = 300
}

variable "target_group_arns" {
  description = "Lista de ARNs de Target Groups del Load Balancer (usado si create_alb es false)"
  type        = list(string)
  default     = []
}

# ALB Configuration
variable "create_alb" {
  description = "Crear un Application Load Balancer nuevo"
  type        = bool
  default     = false
}

variable "alb_name" {
  description = "Nombre del ALB (si create_alb es true)"
  type        = string
  default     = null
}

variable "alb_internal" {
  description = "Si el ALB debe ser interno"
  type        = bool
  default     = false
}

variable "alb_subnets" {
  description = "IDs de subnets públicas para el ALB"
  type        = list(string)
  default     = []
}

variable "alb_security_group_ids" {
  description = "IDs de security groups para el ALB (si está vacío, se crea uno nuevo)"
  type        = list(string)
  default     = []
}

variable "alb_ingress_rules" {
  description = "Reglas de ingreso para el security group del ALB"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    }
  ]
}

variable "enable_deletion_protection" {
  description = "Habilitar protección contra eliminación del ALB"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Habilitar HTTP/2 en el ALB"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Habilitar load balancing entre zonas"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Timeout de conexión idle en segundos"
  type        = number
  default     = 60
}

variable "access_logs" {
  description = "Configuración de access logs del ALB"
  type = object({
    enabled = bool
    bucket  = string
    prefix  = string
  })
  default = {
    enabled = false
    bucket  = ""
    prefix  = ""
  }
}

variable "target_groups" {
  description = "Configuración de Target Groups a crear"
  type = map(object({
    port                 = number
    protocol             = string
    target_type          = optional(string, "instance")
    deregistration_delay = optional(number, 300)
    health_check = optional(object({
      enabled             = optional(bool, true)
      interval            = optional(number, 30)
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      matcher             = optional(string, "200")
    }), {})
    stickiness = optional(object({
      enabled         = optional(bool, false)
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
    }), null)
  }))
  default = {}
}

variable "listeners" {
  description = "Configuración de listeners del ALB"
  type = map(object({
    port            = number
    protocol        = string
    certificate_arn = optional(string)
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
    default_action = object({
      type             = string
      target_group_key = optional(string)
      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
      }))
      fixed_response = optional(object({
        content_type = string
        message_body = string
        status_code  = string
      }))
    })
  }))
  default = {}
}

variable "user_data" {
  description = "Script de user data para las instancias"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Habilitar monitoring detallado de CloudWatch"
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "Habilitar optimización EBS"
  type        = bool
  default     = false
}

variable "root_block_device" {
  description = "Configuración del volumen raíz"
  type = object({
    volume_type           = string
    volume_size           = number
    delete_on_termination = bool
    encrypted             = bool
  })
  default = {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }
}

variable "additional_security_group_ids" {
  description = "IDs de security groups adicionales"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "Reglas de ingreso para el security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "egress_rules" {
  description = "Reglas de egreso para el security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

variable "metrics_granularity" {
  description = "Granularidad de métricas para el Auto Scaling Group"
  type        = string
  default     = "1Minute"
  validation {
    condition     = contains(["1Minute", "5Minute"], var.metrics_granularity)
    error_message = "metrics_granularity debe ser '1Minute' o '5Minute'"
  }
}

variable "scaling_policies" {
  description = "Políticas de escalado"
  type = map(object({
    policy_type               = string
    estimated_instance_warmup = optional(number)
    adjustment_type           = optional(string)
    scaling_adjustment        = optional(number)
    cooldown                  = optional(number)
    # Para Step Scaling
    metric_aggregation_type = optional(string, "Average")
    step_adjustments = optional(list(object({
      scaling_adjustment          = number
      metric_interval_lower_bound = optional(number)
      metric_interval_upper_bound = optional(number)
    })))
    # Para Target Tracking
    target_tracking_configuration = optional(object({
      predefined_metric_type = string
      target_value           = number
    }))
    # Para Predictive Scaling (nuevo)
    predictive_scaling_configuration = optional(object({
      mode                         = optional(string, "ForecastOnly") # ForecastOnly | ForecastAndScale
      scheduling_buffer_time       = optional(number, 300)
      max_capacity_breach_behavior = optional(string, "HonorMaxCapacity") # HonorMaxCapacity | IncreaseMaxCapacity
      max_capacity_buffer          = optional(number)
      metric_specification = object({
        target_value = number
        # Opción 1: métricas predefinidas
        predefined_scaling_metric_specification = optional(object({
          predefined_metric_type = string # ASGAverageCPUUtilization | ASGAverageNetworkIn | ASGAverageNetworkOut | ALBRequestCountPerTarget
          resource_label         = optional(string)
        }))
        predefined_load_metric_specification = optional(object({
          predefined_metric_type = string # ASGTotalCPUUtilization | ASGTotalNetworkIn | ASGTotalNetworkOut | ALBTargetGroupRequestCount
          resource_label         = optional(string)
        }))
        # Opción 2: métrica combinada predefinida
        predefined_metric_pair_specification = optional(object({
          predefined_metric_type = string # ASGCPUUtilization | ASGNetworkIn | ASGNetworkOut | ALBRequestCount
          resource_label         = optional(string)
        }))
        # Opción 3: métricas customizadas
        customized_scaling_metric_specification = optional(object({
          metric_data_queries = list(object({
            id          = string
            expression  = optional(string)
            label       = optional(string)
            return_data = optional(bool, false)
            metric_stat = optional(object({
              stat = string
              metric = object({
                metric_name = string
                namespace   = string
                dimensions = optional(list(object({
                  name  = string
                  value = string
                })))
              })
            }))
          }))
        }))
        customized_load_metric_specification = optional(object({
          metric_data_queries = list(object({
            id          = string
            expression  = optional(string)
            label       = optional(string)
            return_data = optional(bool, false)
            metric_stat = optional(object({
              stat = string
              metric = object({
                metric_name = string
                namespace   = string
                dimensions = optional(list(object({
                  name  = string
                  value = string
                })))
              })
            }))
          }))
        }))
        customized_capacity_metric_specification = optional(object({
          metric_data_queries = list(object({
            id          = string
            expression  = optional(string)
            label       = optional(string)
            return_data = optional(bool, false)
            metric_stat = optional(object({
              stat = string
              metric = object({
                metric_name = string
                namespace   = string
                dimensions = optional(list(object({
                  name  = string
                  value = string
                })))
              })
            }))
          }))
        }))
      })
    }))
  }))
  validation {
    condition = alltrue([
      for k, v in var.scaling_policies :
      (
        v.predictive_scaling_configuration == null ||
        v.policy_type == "PredictiveScaling"
      )
    ])
    error_message = "predictive_scaling_configuration solo puede usarse cuando policy_type = PredictiveScaling"
  }
  default = {}
}

variable "enable_termination_protection" {
  description = "Habilitar protección contra terminación"
  type        = bool
  default     = false
}

variable "suspended_processes" {
  description = "Lista de procesos del ASG a suspender"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags a aplicar a los recursos"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Tags adicionales para las instancias EC2"
  type        = map(string)
  default     = {}
}

variable "iam_instance_profile" {
  description = "Nombre o ARN del IAM instance profile"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Asociar IP pública a las instancias"
  type        = bool
  default     = false
}

variable "default_cooldown" {
  description = "Tiempo de cooldown por defecto en segundos"
  type        = number
  default     = 300
}

variable "force_delete" {
  description = "Forzar eliminación del ASG sin esperar drenaje"
  type        = bool
  default     = false
}

variable "wait_for_capacity_timeout" {
  description = "Timeout para esperar la capacidad deseada"
  type        = string
  default     = "10m"
}

# ---  Configuración de notificaciones  ------------
variable "create_autoscaling_notification" {
  description = "Crear las notificaciones hacia SNS"
  type        = bool
  default     = false
}

variable "notification_events" {
  description = "Lista de eventos de ASG que se reenviarán al tema"
  type        = list(string)
  default = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  validation {
    condition = alltrue([
      for ev in var.notification_events :
      contains([
        "autoscaling:EC2_INSTANCE_LAUNCH",
        "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
        "autoscaling:EC2_INSTANCE_TERMINATE",
        "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
        "autoscaling:EC2_INSTANCE_UNHEALTHY",
        "autoscaling:TEST_NOTIFICATION"
      ], ev)
    ])
    error_message = "Evento no válido para Auto Scaling notifications."
  }
}

# ---  SNS: bring-your-own-topic o créalo  ---------
variable "sns_topic_arn" {
  description = "ARN de un tema SNS ya existente. Si se deja null se creará uno nuevo."
  type        = string
  default     = null
}

variable "sns_display_name" {
  description = "Nombre visible del tema (solo cuando se crea uno nuevo)"
  type        = string
  default     = "asg-notifications"
}

variable "sns_endpoint" {
  description = "Endpoint de la suscripción (email, lambda, sms…). Solo cuando se crea el tema."
  type        = string
  default     = ""
}

variable "sns_protocol" {
  description = "Protocolo de la suscripción: email, sms, lambda, https…"
  type        = string
  default     = "email"

  validation {
    condition = contains(
      ["email", "email-json", "sms", "http", "https", "lambda", "sqs"],
      var.sns_protocol
    )
    error_message = "Protocolo SNS no válido."
  }
}

variable "scheduled_actions" {
  description = "Acciones programadas para el Auto Scaling Group"
  type = map(object({
    min_size         = optional(number)
    max_size         = optional(number)
    desired_capacity = optional(number)
    recurrence       = optional(string)
    start_time       = optional(string)
    end_time         = optional(string)
    time_zone        = optional(string, "UTC")
  }))
  default = {}
}
