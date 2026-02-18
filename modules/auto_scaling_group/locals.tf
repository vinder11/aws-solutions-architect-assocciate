locals {
  create_launch_template  = !var.use_external_launch_template
  launch_template_id      = var.use_external_launch_template ? var.external_launch_template_id : aws_launch_template.this[0].id
  launch_template_version = var.use_external_launch_template ? var.external_launch_template_version : "$Latest"

  # ALB locals
  create_alb_sg = var.create_alb && length(var.alb_security_group_ids) == 0
  alb_sg_ids    = var.create_alb ? (local.create_alb_sg ? [aws_security_group.alb[0].id] : var.alb_security_group_ids) : []

  # Target groups - combinar externos con creados
  all_target_group_arns = concat(
    var.target_group_arns,
    [for tg in aws_lb_target_group.this : tg.arn]
  )
}
