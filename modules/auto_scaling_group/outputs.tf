# outputs.tf
output "autoscaling_group_id" {
  description = "ID del Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "autoscaling_group_arn" {
  description = "ARN del Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "ID del Launch Template (null si se usa uno externo)"
  value       = local.create_launch_template ? aws_launch_template.this[0].id : null
}

output "launch_template_latest_version" {
  description = "Última versión del Launch Template (null si se usa uno externo)"
  value       = local.create_launch_template ? aws_launch_template.this[0].latest_version : null
}

output "security_group_id" {
  description = "ID del Security Group (null si se usa launch template externo)"
  value       = local.create_launch_template ? aws_security_group.asg[0].id : null
}

output "scaling_policy_arns" {
  description = "ARNs de las políticas de escalado"
  value       = { for k, v in aws_autoscaling_policy.this : k => v.arn }
}

output "used_launch_template_id" {
  description = "ID del Launch Template usado (creado o externo)"
  value       = local.launch_template_id
}

# ALB Outputs
output "alb_id" {
  description = "ID del Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].id : null
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].arn : null
}

output "alb_dns_name" {
  description = "DNS name del Application Load Balancer"
  value       = var.create_alb ? aws_lb.this[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID del Application Load Balancer (para Route53)"
  value       = var.create_alb ? aws_lb.this[0].zone_id : null
}

output "alb_security_group_id" {
  description = "ID del security group del ALB"
  value       = local.create_alb_sg ? aws_security_group.alb[0].id : null
}

output "target_group_arns" {
  description = "ARNs de los Target Groups creados"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_names" {
  description = "Nombres de los Target Groups creados"
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}

output "listener_arns" {
  description = "ARNs de los listeners creados"
  value       = { for k, v in aws_lb_listener.this : k => v.arn }
}

output "sns_topic_arn" {
  description = "ARN del tema SNS usado para las notificaciones (null si no se usa)"
  value = (
    var.sns_topic_arn != null
    ? var.sns_topic_arn
    : (length(aws_sns_topic.this) > 0 ? aws_sns_topic.this[0].arn : null)
  )
}

output "scheduled_action_names" {
  description = "Nombres de las acciones programadas del ASG"
  value       = { for k, v in aws_autoscaling_schedule.this : k => v.scheduled_action_name }
}
