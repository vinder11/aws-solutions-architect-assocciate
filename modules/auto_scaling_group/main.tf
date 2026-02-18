# main.tf

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name_prefix         = "${var.name}-asg-"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = local.all_target_group_arns

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  force_delete              = var.force_delete
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  launch_template {
    id      = local.launch_template_id
    version = local.launch_template_version
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = var.metrics_granularity

  suspended_processes = var.suspended_processes

  dynamic "tag" {
    for_each = merge(
      var.tags,
      {
        Name = "${var.name}-asg"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "this" {
  for_each = var.scaling_policies

  name                      = "${var.name}-${each.key}"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  policy_type               = each.value.policy_type
  estimated_instance_warmup = contains(["StepScaling", "TargetTrackingScaling"], each.value.policy_type) ? each.value.estimated_instance_warmup : null
  adjustment_type           = contains(["SimpleScaling", "StepScaling"], each.value.policy_type) ? each.value.adjustment_type : null

  # Para Simple Scaling
  scaling_adjustment = each.value.policy_type == "SimpleScaling" ? each.value.scaling_adjustment : null
  cooldown           = each.value.policy_type == "SimpleScaling" ? each.value.cooldown : null

  # Para Step Scaling
  metric_aggregation_type = each.value.policy_type == "StepScaling" ? each.value.metric_aggregation_type : null

  dynamic "step_adjustment" {
    for_each = each.value.policy_type == "StepScaling" && each.value.step_adjustments != null ? each.value.step_adjustments : []
    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }

  # Para Target Tracking
  dynamic "target_tracking_configuration" {
    for_each = each.value.target_tracking_configuration != null ? [each.value.target_tracking_configuration] : []
    content {
      predefined_metric_specification {
        predefined_metric_type = target_tracking_configuration.value.predefined_metric_type
      }
      target_value = target_tracking_configuration.value.target_value
    }
  }

  # Predictive Scaling (nuevo)
  dynamic "predictive_scaling_configuration" {
    for_each = each.value.predictive_scaling_configuration != null ? [each.value.predictive_scaling_configuration] : []
    content {
      mode                         = predictive_scaling_configuration.value.mode
      scheduling_buffer_time       = predictive_scaling_configuration.value.scheduling_buffer_time
      max_capacity_breach_behavior = predictive_scaling_configuration.value.max_capacity_breach_behavior
      max_capacity_buffer          = predictive_scaling_configuration.value.max_capacity_buffer

      metric_specification {
        target_value = predictive_scaling_configuration.value.metric_specification.target_value

        dynamic "predefined_scaling_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.predefined_scaling_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.predefined_scaling_metric_specification] : []
          content {
            predefined_metric_type = predefined_scaling_metric_specification.value.predefined_metric_type
            resource_label         = predefined_scaling_metric_specification.value.resource_label
          }
        }

        dynamic "predefined_load_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.predefined_load_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.predefined_load_metric_specification] : []
          content {
            predefined_metric_type = predefined_load_metric_specification.value.predefined_metric_type
            resource_label         = predefined_load_metric_specification.value.resource_label
          }
        }

        dynamic "predefined_metric_pair_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.predefined_metric_pair_specification != null ? [predictive_scaling_configuration.value.metric_specification.predefined_metric_pair_specification] : []
          content {
            predefined_metric_type = predefined_metric_pair_specification.value.predefined_metric_type
            resource_label         = predefined_metric_pair_specification.value.resource_label
          }
        }

        dynamic "customized_scaling_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.customized_scaling_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.customized_scaling_metric_specification] : []
          content {
            dynamic "metric_data_queries" {
              for_each = customized_scaling_metric_specification.value.metric_data_queries
              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                label       = metric_data_queries.value.label
                return_data = metric_data_queries.value.return_data
                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat != null ? [metric_data_queries.value.metric_stat] : []
                  content {
                    stat = metric_stat.value.stat
                    metric {
                      metric_name = metric_stat.value.metric.metric_name
                      namespace   = metric_stat.value.metric.namespace
                      dynamic "dimensions" {
                        for_each = metric_stat.value.metric.dimensions != null ? metric_stat.value.metric.dimensions : []
                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        # customized_load_metric_specification y customized_capacity_metric_specification
        # siguen la misma estructura que customized_scaling_metric_specification
        dynamic "customized_load_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.customized_load_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.customized_load_metric_specification] : []
          content {
            dynamic "metric_data_queries" {
              for_each = customized_load_metric_specification.value.metric_data_queries
              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                label       = metric_data_queries.value.label
                return_data = metric_data_queries.value.return_data
                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat != null ? [metric_data_queries.value.metric_stat] : []
                  content {
                    stat = metric_stat.value.stat
                    metric {
                      metric_name = metric_stat.value.metric.metric_name
                      namespace   = metric_stat.value.metric.namespace
                      dynamic "dimensions" {
                        for_each = metric_stat.value.metric.dimensions != null ? metric_stat.value.metric.dimensions : []
                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        dynamic "customized_capacity_metric_specification" {
          for_each = predictive_scaling_configuration.value.metric_specification.customized_capacity_metric_specification != null ? [predictive_scaling_configuration.value.metric_specification.customized_capacity_metric_specification] : []
          content {
            dynamic "metric_data_queries" {
              for_each = customized_capacity_metric_specification.value.metric_data_queries
              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                label       = metric_data_queries.value.label
                return_data = metric_data_queries.value.return_data
                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat != null ? [metric_data_queries.value.metric_stat] : []
                  content {
                    stat = metric_stat.value.stat
                    metric {
                      metric_name = metric_stat.value.metric.metric_name
                      namespace   = metric_stat.value.metric.namespace
                      dynamic "dimensions" {
                        for_each = metric_stat.value.metric.dimensions != null ? metric_stat.value.metric.dimensions : []
                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

# Scheduled Actions
resource "aws_autoscaling_schedule" "this" {
  for_each = var.scheduled_actions

  scheduled_action_name  = "${var.name}-${each.key}"
  autoscaling_group_name = aws_autoscaling_group.this.name

  min_size         = each.value.min_size
  max_size         = each.value.max_size
  desired_capacity = each.value.desired_capacity
  recurrence       = each.value.recurrence
  start_time       = each.value.start_time
  end_time         = each.value.end_time
  time_zone        = each.value.time_zone
}

resource "aws_autoscaling_notification" "this" {
  count = var.create_autoscaling_notification ? 1 : 0

  group_names   = [aws_autoscaling_group.this.name]
  notifications = var.notification_events
  topic_arn     = coalesce(var.sns_topic_arn, try(aws_sns_topic.this[0].arn, ""))
}
