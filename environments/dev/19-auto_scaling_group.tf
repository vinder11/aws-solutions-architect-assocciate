# Escenario 1: Sin ALB (solo Target Groups externos)
# module "autoscaling" {
#   source = "../../modules/auto_scaling_group"

#   name              = "web-app"
#   vpc_id            = "vpc-12345"
#   subnet_ids        = ["subnet-123", "subnet-456"]
#   ami_id            = "ami-abc123"
#   target_group_arns = ["arn:aws:elasticloadbalancing:..."]

#   min_size = 2
#   max_size = 10
# }
########################################################################################################################
# Escenario 2: Crear ALB + Target Groups + Listeners completo
module "autoscaling_with_alb" {
  source = "../../modules/auto_scaling_group"

  name       = "${var.project_name}-web-app"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [module.subnets.public_subnet_ids[0]] # Usar solo una subred pública para las instancias que van detrás del ALB

  use_external_launch_template = true
  external_launch_template_id  = module.basic_launch_template.id

  # Configuración del ALB
  create_alb   = true
  alb_internal = false
  alb_subnets  = module.subnets.public_subnet_ids

  # Configuración del Auto Scaling Group
  min_size         = 1
  max_size         = 10
  desired_capacity = 1

  # Target Groups
  target_groups = {
    app = {
      port     = 80
      protocol = "HTTP"
      health_check = {
        path                = "/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
        matcher             = "200"
      }
    }
  }

  # Listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type             = "forward"
        target_group_key = "app"
      }
    }
    # https = {
    #   port            = 443
    #   protocol        = "HTTPS"
    #   certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
    #   default_action = {
    #     type             = "forward"
    #     target_group_key = "app"
    #   }
    # }
  }

  # scaling_policies = {
  #   # target_tracking_policy = {
  #   #   policy_type               = "TargetTrackingScaling"
  #   #   estimated_instance_warmup = 250
  #   #   target_tracking_configuration = {
  #   #     predefined_metric_type = "ASGAverageCPUUtilization"
  #   #     target_value           = 60.0
  #   #   }
  #   # },
  #   #   # Simple Scaling - Scale Up
  #   #   simple_scaling_policy_out = {
  #   #     policy_type        = "SimpleScaling"
  #   #     adjustment_type    = "ChangeInCapacity"
  #   #     scaling_adjustment = 1
  #   #     cooldown           = 360
  #   #   },
  #   #   # Simple Scaling - Scale Down
  #   #   simple_scaling_policy_in = {
  #   #     policy_type        = "SimpleScaling"
  #   #     adjustment_type    = "ChangeInCapacity"
  #   #     scaling_adjustment = -1
  #   #     cooldown           = 360
  #   #   },
  #   #   step_scale_out = {
  #   #     policy_type             = "StepScaling"
  #   #     adjustment_type         = "ChangeInCapacity"
  #   #     metric_aggregation_type = "Average"
  #   #     step_adjustments = [
  #   #       {
  #   #         scaling_adjustment          = 1
  #   #         metric_interval_lower_bound = 0 # Desde 90%
  #   #         metric_interval_upper_bound = 5 # Hasta 95%
  #   #       },
  #   #       {
  #   #         scaling_adjustment          = 2
  #   #         metric_interval_lower_bound = 5 # Desde 95% en adelante
  #   #         metric_interval_upper_bound = null
  #   #       }
  #   #     ]
  #   #   }
  #   #   step_scale_in = {
  #   #     policy_type             = "StepScaling"
  #   #     adjustment_type         = "ChangeInCapacity"
  #   #     metric_aggregation_type = "Average"
  #   #     step_adjustments = [
  #   #       {
  #   #         scaling_adjustment          = -1
  #   #         metric_interval_lower_bound = -10 # 10-20%
  #   #         metric_interval_upper_bound = 0
  #   #       },
  #   #       {
  #   #         scaling_adjustment          = -2
  #   #         metric_interval_lower_bound = null # <10%
  #   #         metric_interval_upper_bound = -10
  #   #       }
  #   #     ]
  #   #   }
  #   # predictive-cpu = {
  #   #   policy_type = "PredictiveScaling"
  #   #   predictive_scaling_configuration = {
  #   #     mode                   = "ForecastOnly"
  #   #     scheduling_buffer_time = 300
  #   #     metric_specification = {
  #   #       target_value = 70
  #   #       predefined_metric_pair_specification = {
  #   #         predefined_metric_type = "ASGCPUUtilization"
  #   #       }
  #   #     }
  #   #   }
  #   # }
  # }

  # scheduled_actions = {
  #   scale_out = {
  #     min_size         = 2
  #     max_size         = 5
  #     desired_capacity = 3
  #     recurrence       = "0 0 * * FRI"          # Todos los días a las 8 AM
  #     start_time       = "2026-03-01T04:59:00Z" # Escala hacia afuera el 1 de marzo a las 3 AM UTC (8 AM hora local)
  #     end_time         = "2026-03-31T03:59:00Z" # Detener la acción programada el 31 de marzo a las 11:59 PM UTC
  #     time_zone        = "America/La_Paz"
  #   },
  #   # scale_in = {
  #   #   min_size         = 1
  #   #   max_size         = 3
  #   #   desired_capacity = 1
  #   #   start_time       = "2026-02-23T23:59:00Z" # Escala hacia adentro el 31 de diciembre a las 11 PM UTC
  #   # }
  # }

  tags = var.vpc_custom_tags
}

# module "asg_cpu_alarm_out" {
#   source = "../../modules/cloudwatch_alarm"

#   alarm_name          = "${module.autoscaling_with_alb.autoscaling_group_name}-high-cpu"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2   # Número de períodos para evaluar
#   period              = 120 # Período en segundos (2 minutos)
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   statistic           = "Average"
#   threshold           = 80
#   alarm_description   = "This alarm is triggered when CPU > 80%"
#   alarm_actions       = [module.autoscaling_with_alb.scaling_policy_arns["simple_scaling_policy_out"]] # Acción de escalado hacia afuera

#   dimensions = {
#     AutoScalingGroupName = module.autoscaling_with_alb.autoscaling_group_name # Usar el nombre del ASG creado
#   }
#   # alarm_actions = [aws_sns_topic.alerts.arn]
#   tags = var.vpc_custom_tags
# }

# module "asg_cpu_alarm_in" {
#   source = "../../modules/cloudwatch_alarm"

#   alarm_name          = "${module.autoscaling_with_alb.autoscaling_group_name}-low-cpu"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = 2   # Número de períodos para evaluar
#   period              = 120 # Período en segundos (2 minutos)
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   statistic           = "Average"
#   threshold           = 40
#   alarm_description   = "This alarm is triggered when CPU < 40%"
#   alarm_actions       = [module.autoscaling_with_alb.scaling_policy_arns["simple_scaling_policy_in"]] # Acción de escalado hacia adentro

#   dimensions = {
#     AutoScalingGroupName = module.autoscaling_with_alb.autoscaling_group_name # Usar el nombre del ASG creado
#   }
#   # alarm_actions = [aws_sns_topic.alerts.arn]
#   tags = var.vpc_custom_tags
# }

# module "asg_cpu_alarm_out_step" {
#   source = "../../modules/cloudwatch_alarm"

#   alarm_name          = "${module.autoscaling_with_alb.autoscaling_group_name}-high-cpu-step"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1   # Número de períodos para evaluar
#   period              = 120 # Período en segundos (2 minutos)
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   statistic           = "Average"
#   threshold           = 90 # umbral base en 90%
#   alarm_description   = "This alarm is triggered when CPU > 90%"
#   alarm_actions       = [module.autoscaling_with_alb.scaling_policy_arns["step_scale_out"]] # Acción de escalado hacia afuera

#   dimensions = {
#     AutoScalingGroupName = module.autoscaling_with_alb.autoscaling_group_name # Usar el nombre del ASG creado
#   }
#   # alarm_actions = [aws_sns_topic.alerts.arn]
#   tags = var.vpc_custom_tags
# }

# module "asg_cpu_alarm_in_step" {
#   source = "../../modules/cloudwatch_alarm"

#   alarm_name          = "${module.autoscaling_with_alb.autoscaling_group_name}-low-cpu-step"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = 2   # Número de períodos para evaluar
#   period              = 120 # Período en segundos (2 minutos)
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   statistic           = "Average"
#   threshold           = 20
#   alarm_description   = "This alarm is triggered when CPU < 20%"
#   alarm_actions       = [module.autoscaling_with_alb.scaling_policy_arns["step_scale_in"]] # Acción de escalado hacia adentro

#   dimensions = {
#     AutoScalingGroupName = module.autoscaling_with_alb.autoscaling_group_name # Usar el nombre del ASG creado
#   }
#   # alarm_actions = [aws_sns_topic.alerts.arn]
#   tags = var.vpc_custom_tags
# }
########################################################################################################################
# Escenario 3: Crear solo Target Groups (usar ALB existente)
# module "autoscaling_existing_alb" {
#   source = "../../modules/auto_scaling_group"

#   name       = "web-app"
#   vpc_id     = "vpc-12345"
#   subnet_ids = ["subnet-123", "subnet-456"]
#   ami_id     = "ami-abc123"

#   # Crear target groups sin ALB
#   target_groups = {
#     app = {
#       port     = 80
#       protocol = "HTTP"
#       health_check = {
#         path = "/health"
#       }
#     }
#   }

#   min_size = 2
#   max_size = 10
# }

# # Luego adjuntar manualmente el TG al ALB existente
# resource "aws_lb_listener_rule" "forward_to_new_tg" {
#   listener_arn = "arn:aws:elasticloadbalancing:...:listener/..."

#   action {
#     type             = "forward"
#     target_group_arn = module.autoscaling_existing_alb.target_group_arns["app"]
#   }

#   condition {
#     path_pattern {
#       values = ["/app/*"]
#     }
#   }
# }
