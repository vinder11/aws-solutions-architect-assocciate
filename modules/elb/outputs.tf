# ============================================================
# outputs.tf — terraform-aws-elb module
# ============================================================

# ─────────────────────────────────────────────────────────────
# LOAD BALANCER
# ─────────────────────────────────────────────────────────────

output "lb_id" {
  description = "The ID of the load balancer."
  value       = aws_lb.this.id
}

output "lb_arn" {
  description = "The ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "lb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics."
  value       = aws_lb.this.arn_suffix
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the LB (for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "lb_name" {
  description = "The name of the load balancer."
  value       = aws_lb.this.name
}

output "lb_type" {
  description = "The type of load balancer: application, network, or gateway."
  value       = aws_lb.this.load_balancer_type
}

output "lb_internal" {
  description = "Whether the load balancer is internal."
  value       = aws_lb.this.internal
}

# ─────────────────────────────────────────────────────────────
# TARGET GROUPS
# ─────────────────────────────────────────────────────────────

output "target_group_arns" {
  description = "Map of target group key → ARN."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "target_group_ids" {
  description = "Map of target group key → ID."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.id }
}

output "target_group_arn_suffixes" {
  description = "Map of target group key → ARN suffix (for CloudWatch)."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn_suffix }
}

output "target_group_names" {
  description = "Map of target group key → name."
  value       = { for k, tg in aws_lb_target_group.this : k => tg.name }
}

# ─────────────────────────────────────────────────────────────
# LISTENERS
# ─────────────────────────────────────────────────────────────

output "listener_arns" {
  description = "Map of listener key → ARN."
  value       = { for k, l in aws_lb_listener.this : k => l.arn }
}

output "listener_ids" {
  description = "Map of listener key → ID."
  value       = { for k, l in aws_lb_listener.this : k => l.id }
}

# ─────────────────────────────────────────────────────────────
# LISTENER RULES
# ─────────────────────────────────────────────────────────────

output "listener_rule_arns" {
  description = "Map of rule key → ARN (ALB only)."
  value       = { for k, r in aws_lb_listener_rule.this : k => r.arn }
}

# ─────────────────────────────────────────────────────────────
# WAF / SHIELD
# ─────────────────────────────────────────────────────────────

output "waf_association_id" {
  description = "ID of the WAFv2 WebACL association (ALB only, null if not configured)."
  value       = length(aws_wafv2_web_acl_association.this) > 0 ? aws_wafv2_web_acl_association.this[0].id : null
}

output "shield_protection_id" {
  description = "ID of the Shield Advanced protection (null if not enabled)."
  value       = length(aws_shield_protection.this) > 0 ? aws_shield_protection.this[0].id : null
}

# ─────────────────────────────────────────────────────────────
# CONVENIENCE — Route 53 alias target
# ─────────────────────────────────────────────────────────────

output "route53_alias_target" {
  description = "Ready-to-use object for aws_route53_record alias blocks."
  value = {
    dns_name               = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
