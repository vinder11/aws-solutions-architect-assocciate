# ============================================================
# main.tf — terraform-aws-elb module
# ============================================================

locals {
  is_alb  = var.lb_type == "application"
  is_nlb  = var.lb_type == "network"
  is_gwlb = var.lb_type == "gateway"

  common_tags = merge(
    {
      ManagedBy   = "terraform"
      LBType      = var.lb_type
      Environment = var.environment
    },
    var.tags
  )

  # Use subnet_mapping when provided (NLB EIP pinning), else plain subnet_ids
  use_subnet_mapping = length(var.subnet_mapping) > 0
}

# ─────────────────────────────────────────────────────────────
# LOAD BALANCER
# ─────────────────────────────────────────────────────────────

resource "aws_lb" "this" {
  name               = var.name
  load_balancer_type = var.lb_type
  internal           = var.internal
  tags               = local.common_tags

  # Subnet assignment: explicit mapping (NLB EIPs) vs list
  subnets = local.use_subnet_mapping ? null : var.subnet_ids

  dynamic "subnet_mapping" {
    for_each = local.use_subnet_mapping ? var.subnet_mapping : []
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = subnet_mapping.value.allocation_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
      ipv6_address         = subnet_mapping.value.ipv6_address
    }
  }

  # Security groups (ALB only)
  security_groups = local.is_alb ? var.security_group_ids : null

  # Deletion protection (top-level variable takes precedence; nlb sub-var also supported)
  enable_deletion_protection = var.enable_deletion_protection || (local.is_nlb && var.nlb.enable_deletion_protection)

  # ── ALB-specific attributes ──────────────────────────────
  idle_timeout                        = local.is_alb ? var.alb.idle_timeout : null
  drop_invalid_header_fields          = local.is_alb ? var.alb.drop_invalid_header_fields : null
  preserve_host_header                = local.is_alb ? var.alb.preserve_host_header : null
  xff_header_processing_mode          = local.is_alb ? var.alb.xff_header_processing_mode : null
  desync_mitigation_mode              = local.is_alb ? var.alb.desync_mitigation_mode : null
  enable_http2                        = local.is_alb ? var.alb.enable_http2 : null
  enable_waf_fail_open                = local.is_alb ? var.alb.enable_waf_fail_open : null
  client_keep_alive                   = local.is_alb ? var.alb.client_keep_alive : null
  ip_address_type                     = local.is_alb ? var.alb.ip_address_type : (local.is_nlb ? var.nlb.ip_address_type : null)

  # ── NLB-specific attributes ──────────────────────────────
  enable_cross_zone_load_balancing    = local.is_nlb ? var.nlb.enable_cross_zone_load_balancing : null
  dns_record_client_routing_policy    = local.is_nlb ? var.nlb.dns_record_client_routing_policy : null

  # ── Access logs (all types) ───────────────────────────────
  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [var.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = true
    }
  }

  # ── Connection logs (ALB only) ────────────────────────────
  dynamic "connection_logs" {
    for_each = local.is_alb && var.connection_logs.enabled ? [var.connection_logs] : []
    content {
      bucket  = connection_logs.value.bucket
      prefix  = connection_logs.value.prefix
      enabled = true
    }
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    # Preconditions run at plan time — catch misconfigurations early
    precondition {
      condition     = !local.is_alb || length(var.subnet_ids) >= 2 || local.use_subnet_mapping
      error_message = "ALB requires at least 2 subnets across different Availability Zones."
    }

    precondition {
      condition     = !local.is_alb || length(var.security_group_ids) > 0
      error_message = "ALB requires at least one security group (security_group_ids)."
    }

    precondition {
      condition     = local.is_alb || length(var.security_group_ids) == 0
      error_message = "NLB and GWLB do not support security groups. Remove security_group_ids."
    }

    precondition {
      condition = !local.is_gwlb || alltrue([
        for k, tg in var.target_groups : tg.protocol == "GENEVE"
      ])
      error_message = "GWLB target groups must use protocol = 'GENEVE'."
    }
  }
}

# ─────────────────────────────────────────────────────────────
# TARGET GROUPS
# ─────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = "${var.name}-${each.key}"
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type
  tags        = local.common_tags

  protocol_version                   = local.is_alb ? each.value.protocol_version : null
  deregistration_delay               = each.value.deregistration_delay
  slow_start                         = local.is_alb ? each.value.slow_start : null
  load_balancing_algorithm_type      = local.is_alb ? each.value.load_balancing_algorithm_type : null
  load_balancing_cross_zone_enabled  = each.value.load_balancing_cross_zone_enabled
  lambda_multi_value_headers_enabled = each.value.target_type == "lambda" ? each.value.lambda_multi_value_headers_enabled : null
  proxy_protocol_v2                  = local.is_nlb ? each.value.proxy_protocol_v2 : null
  preserve_client_ip                 = local.is_nlb ? each.value.preserve_client_ip : null
  connection_termination             = local.is_nlb ? each.value.connection_termination : null

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []
    content {
      enabled             = health_check.value.enabled
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      matcher             = health_check.value.matcher
    }
  }

  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
    }
  }

  dynamic "target_failover" {
    for_each = local.is_nlb && each.value.target_failover != null ? [each.value.target_failover] : []
    content {
      on_deregistration = target_failover.value.on_deregistration
      on_unhealthy      = target_failover.value.on_unhealthy
    }
  }

  lifecycle {
    precondition {
      condition     = !local.is_gwlb || each.value.protocol == "GENEVE"
      error_message = "GWLB target group '${each.key}' must use protocol = 'GENEVE'."
    }
    precondition {
      condition     = each.value.target_type != "lambda" || each.value.port == null
      error_message = "Target group '${each.key}': lambda target_type must not specify a port."
    }
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────
# TARGET GROUP ATTACHMENTS (static)
# ─────────────────────────────────────────────────────────────

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_group_attachments

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = each.value.port
  availability_zone = each.value.availability_zone
}

# ─────────────────────────────────────────────────────────────
# LISTENERS
# ─────────────────────────────────────────────────────────────

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.ssl_policy : null
  certificate_arn   = contains(["HTTPS", "TLS"], each.value.protocol) ? each.value.certificate_arn : null
  alpn_policy       = each.value.protocol == "TLS" ? each.value.alpn_policy : null
  tags              = merge(local.common_tags, { ListenerKey = each.key })

  # ── Default action ────────────────────────────────────────

  dynamic "default_action" {
    for_each = each.value.default_action.type == "forward" ? [each.value.default_action] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[default_action.value.target_group_key].arn
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "redirect" ? [each.value.default_action] : []
    content {
      type = "redirect"
      redirect {
        port        = default_action.value.redirect.port
        protocol    = default_action.value.redirect.protocol
        status_code = default_action.value.redirect.status_code
        host        = default_action.value.redirect.host
        path        = default_action.value.redirect.path
        query       = default_action.value.redirect.query
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "fixed-response" ? [each.value.default_action] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = default_action.value.fixed_response.content_type
        message_body = default_action.value.fixed_response.message_body
        status_code  = default_action.value.fixed_response.status_code
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "authenticate-cognito" ? [each.value.default_action] : []
    content {
      type = "authenticate-cognito"
      authenticate_cognito {
        user_pool_arn                  = default_action.value.authenticate_cognito.user_pool_arn
        user_pool_client_id            = default_action.value.authenticate_cognito.user_pool_client_id
        user_pool_domain               = default_action.value.authenticate_cognito.user_pool_domain
        on_unauthenticated_request     = default_action.value.authenticate_cognito.on_unauthenticated_request
        scope                          = default_action.value.authenticate_cognito.scope
        session_cookie_name            = default_action.value.authenticate_cognito.session_cookie_name
        session_timeout                = default_action.value.authenticate_cognito.session_timeout
      }
    }
  }

  dynamic "default_action" {
    for_each = each.value.default_action.type == "authenticate-oidc" ? [each.value.default_action] : []
    content {
      type = "authenticate-oidc"
      authenticate_oidc {
        authorization_endpoint         = default_action.value.authenticate_oidc.authorization_endpoint
        client_id                      = default_action.value.authenticate_oidc.client_id
        client_secret                  = default_action.value.authenticate_oidc.client_secret
        issuer                         = default_action.value.authenticate_oidc.issuer
        token_endpoint                 = default_action.value.authenticate_oidc.token_endpoint
        user_info_endpoint             = default_action.value.authenticate_oidc.user_info_endpoint
        on_unauthenticated_request     = default_action.value.authenticate_oidc.on_unauthenticated_request
        scope                          = default_action.value.authenticate_oidc.scope
        session_cookie_name            = default_action.value.authenticate_oidc.session_cookie_name
        session_timeout                = default_action.value.authenticate_oidc.session_timeout
      }
    }
  }

  # ── mTLS ─────────────────────────────────────────────────
  dynamic "mutual_authentication" {
    for_each = each.value.mutual_authentication != null ? [each.value.mutual_authentication] : []
    content {
      mode                             = mutual_authentication.value.mode
      trust_store_arn                  = mutual_authentication.value.trust_store_arn
      ignore_client_certificate_expiry = mutual_authentication.value.ignore_client_certificate_expiry
    }
  }
}

# ─────────────────────────────────────────────────────────────
# ADDITIONAL CERTIFICATES (SNI)
# ─────────────────────────────────────────────────────────────

locals {
  # Flatten: listener_key → [cert_arn, ...] → unique attachment records
  additional_certs = merge([
    for lk, l in var.listeners : {
      for cert_arn in l.additional_certificate_arns :
      "${lk}/${cert_arn}" => {
        listener_key    = lk
        certificate_arn = cert_arn
      }
    }
  ]...)
}

resource "aws_lb_listener_certificate" "this" {
  for_each = local.additional_certs

  listener_arn    = aws_lb_listener.this[each.value.listener_key].arn
  certificate_arn = each.value.certificate_arn
}

# ─────────────────────────────────────────────────────────────
# LISTENER RULES (ALB only)
# ─────────────────────────────────────────────────────────────

resource "aws_lb_listener_rule" "this" {
  for_each = local.is_alb ? var.listener_rules : {}

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority     = each.value.priority
  tags         = merge(local.common_tags, { RuleKey = each.key })

  # ── Conditions ───────────────────────────────────────────

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "host-header"]
    content {
      host_header { values = condition.value.values }
    }
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "path-pattern"]
    content {
      path_pattern { values = condition.value.values }
    }
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "http-header"]
    content {
      http_header {
        http_header_name = condition.value.http_header.http_header_name
        values           = condition.value.http_header.values
      }
    }
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "http-request-method"]
    content {
      http_request_method { values = condition.value.values }
    }
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "query-string"]
    content {
      dynamic "query_string" {
        for_each = condition.value.query_string
        content {
          key   = query_string.value.key
          value = query_string.value.value
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if c.type == "source-ip"]
    content {
      source_ip { values = condition.value.values }
    }
  }

  # ── Actions ──────────────────────────────────────────────

  dynamic "action" {
    for_each = [for a in each.value.actions : a if a.type == "forward" && a.weighted_targets == null]
    content {
      type             = "forward"
      order            = action.value.order
      target_group_arn = aws_lb_target_group.this[action.value.target_group_key].arn
    }
  }

  dynamic "action" {
    for_each = [for a in each.value.actions : a if a.type == "forward" && a.weighted_targets != null]
    content {
      type  = "forward"
      order = action.value.order
      forward {
        dynamic "target_group" {
          for_each = action.value.weighted_targets
          content {
            arn    = aws_lb_target_group.this[target_group.value.target_group_key].arn
            weight = target_group.value.weight
          }
        }
        dynamic "stickiness" {
          for_each = action.value.stickiness_duration != null ? [action.value.stickiness_duration] : []
          content {
            enabled  = true
            duration = stickiness.value
          }
        }
      }
    }
  }

  dynamic "action" {
    for_each = [for a in each.value.actions : a if a.type == "redirect"]
    content {
      type  = "redirect"
      order = action.value.order
      redirect {
        port        = action.value.redirect.port
        protocol    = action.value.redirect.protocol
        status_code = action.value.redirect.status_code
        host        = action.value.redirect.host
        path        = action.value.redirect.path
        query       = action.value.redirect.query
      }
    }
  }

  dynamic "action" {
    for_each = [for a in each.value.actions : a if a.type == "fixed-response"]
    content {
      type  = "fixed-response"
      order = action.value.order
      fixed_response {
        content_type = action.value.fixed_response.content_type
        message_body = action.value.fixed_response.message_body
        status_code  = action.value.fixed_response.status_code
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────
# WAF WEB ACL ASSOCIATION (ALB only)
# ─────────────────────────────────────────────────────────────

resource "aws_wafv2_web_acl_association" "this" {
  count = local.is_alb && var.waf_web_acl_arn != null ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}

# ─────────────────────────────────────────────────────────────
# SHIELD ADVANCED (optional)
# ─────────────────────────────────────────────────────────────

resource "aws_shield_protection" "this" {
  count = var.enable_shield_advanced ? 1 : 0

  name         = "${var.name}-shield"
  resource_arn = aws_lb.this.arn
  tags         = local.common_tags
}
