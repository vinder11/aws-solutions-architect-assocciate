# ============================================================
# variables.tf — terraform-aws-elb module
# Supports: ALB, NLB, GWLB
# ============================================================

# ─────────────────────────────────────────────────────────────
# CORE
# ─────────────────────────────────────────────────────────────

variable "name" {
  description = "Name prefix for all resources. Max 32 chars (AWS limit for LB names)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,31}$", var.name))
    error_message = "name must start with a letter, contain only alphanumerics/hyphens, and be ≤ 32 characters."
  }
}

variable "lb_type" {
  description = "Type of load balancer: 'application' (ALB), 'network' (NLB), or 'gateway' (GWLB)."
  type        = string

  validation {
    condition     = contains(["application", "network", "gateway"], var.lb_type)
    error_message = "lb_type must be one of: application, network, gateway."
  }
}

variable "internal" {
  description = "Set to true to create an internal (private) load balancer."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where the load balancer resides."
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8,17}$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (e.g., vpc-0abc12345)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach to the LB. ALB/NLB require ≥ 2 AZs; GWLB requires ≥ 1."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet_id is required."
  }

  validation {
    condition     = alltrue([for s in var.subnet_ids : can(regex("^subnet-[0-9a-f]{8,17}$", s))])
    error_message = "All subnet_ids must be valid subnet IDs (e.g., subnet-0abc12345)."
  }
}

variable "tags" {
  description = "Map of tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment label (e.g., dev, staging, prod). Merged into tags."
  type        = string
  default     = ""
}

# ─────────────────────────────────────────────────────────────
# SECURITY GROUPS  (ALB only — NLB/GWLB do not use SGs)
# ─────────────────────────────────────────────────────────────

variable "security_group_ids" {
  description = "Security group IDs to attach. Only applicable for ALB; ignored for NLB/GWLB."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for sg in var.security_group_ids : can(regex("^sg-[0-9a-f]{8,17}$", sg))])
    error_message = "All security_group_ids must be valid SG IDs (e.g., sg-0abc12345)."
  }
}

# ─────────────────────────────────────────────────────────────
# ACCESS LOGS
# ─────────────────────────────────────────────────────────────

variable "access_logs" {
  description = "S3 access log configuration."
  type = object({
    enabled = bool
    bucket  = optional(string, "")
    prefix  = optional(string, "")
  })
  default = {
    enabled = false
    bucket  = ""
    prefix  = ""
  }

  validation {
    condition     = !var.access_logs.enabled || (var.access_logs.enabled && var.access_logs.bucket != "")
    error_message = "access_logs.bucket must be set when access_logs.enabled = true."
  }
}

# ─────────────────────────────────────────────────────────────
# CONNECTION LOGS (ALB only, separate from access logs)
# ─────────────────────────────────────────────────────────────

variable "connection_logs" {
  description = "ALB connection log configuration (separate from access logs, ALB only)."
  type = object({
    enabled = bool
    bucket  = optional(string, "")
    prefix  = optional(string, "")
  })
  default = {
    enabled = false
    bucket  = ""
    prefix  = ""
  }

  validation {
    condition     = !var.connection_logs.enabled || (var.connection_logs.enabled && var.connection_logs.bucket != "")
    error_message = "connection_logs.bucket must be set when connection_logs.enabled = true."
  }
}

# ─────────────────────────────────────────────────────────────
# DELETION PROTECTION
# ─────────────────────────────────────────────────────────────

variable "enable_deletion_protection" {
  description = "Protect the LB from accidental deletion via AWS API/console."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────────────────────────
# ALB-SPECIFIC SETTINGS
# ─────────────────────────────────────────────────────────────

variable "alb" {
  description = "ALB-specific options. Only evaluated when lb_type = 'application'."
  type = object({
    idle_timeout                = optional(number, 60)
    drop_invalid_header_fields  = optional(bool, true)
    preserve_host_header        = optional(bool, false)
    xff_header_processing_mode  = optional(string, "append")
    desync_mitigation_mode      = optional(string, "defensive")
    enable_http2                = optional(bool, true)
    enable_waf_fail_open        = optional(bool, false)
    client_keep_alive           = optional(number, 3600)
    ip_address_type             = optional(string, "ipv4")
  })
  default = {}

  validation {
    condition     = contains(["append", "preserve", "remove"], var.alb.xff_header_processing_mode)
    error_message = "alb.xff_header_processing_mode must be one of: append, preserve, remove."
  }

  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.alb.desync_mitigation_mode)
    error_message = "alb.desync_mitigation_mode must be one of: monitor, defensive, strictest."
  }

  validation {
    condition     = contains(["ipv4", "dualstack", "dualstack-without-public-ipv4"], var.alb.ip_address_type)
    error_message = "alb.ip_address_type must be one of: ipv4, dualstack, dualstack-without-public-ipv4."
  }

  validation {
    condition     = var.alb.idle_timeout >= 1 && var.alb.idle_timeout <= 4000
    error_message = "alb.idle_timeout must be between 1 and 4000 seconds."
  }

  validation {
    condition     = var.alb.client_keep_alive >= 60 && var.alb.client_keep_alive <= 604800
    error_message = "alb.client_keep_alive must be between 60 and 604800 seconds."
  }
}

# ─────────────────────────────────────────────────────────────
# NLB-SPECIFIC SETTINGS
# ─────────────────────────────────────────────────────────────

variable "nlb" {
  description = "NLB-specific options. Only evaluated when lb_type = 'network'."
  type = object({
    enable_cross_zone_load_balancing  = optional(bool, false)
    enable_deletion_protection        = optional(bool, false)
    ip_address_type                   = optional(string, "ipv4")
    dns_record_client_routing_policy  = optional(string, "any_availability_zone")
  })
  default = {}

  validation {
    condition     = contains(["ipv4", "dualstack"], var.nlb.ip_address_type)
    error_message = "nlb.ip_address_type must be one of: ipv4, dualstack."
  }

  validation {
    condition     = contains(["any_availability_zone", "availability_zone_affinity", "partial_availability_zone_affinity"], var.nlb.dns_record_client_routing_policy)
    error_message = "nlb.dns_record_client_routing_policy must be one of: any_availability_zone, availability_zone_affinity, partial_availability_zone_affinity."
  }
}

# ─────────────────────────────────────────────────────────────
# NLB SUBNET MAPPING (EIPs / private IPs per AZ)
# ─────────────────────────────────────────────────────────────

variable "subnet_mapping" {
  description = <<-EOT
    Per-AZ subnet mapping for NLB. Allows pinning Elastic IPs or private IPs.
    Each element maps a subnet to optional allocation_id (EIP) and/or private_ipv4_address.
    Leave empty to use var.subnet_ids with auto-assigned IPs.
  EOT
  type = list(object({
    subnet_id            = string
    allocation_id        = optional(string, null) # EIP allocation ID
    private_ipv4_address = optional(string, null)
    ipv6_address         = optional(string, null)
  }))
  default = []

  validation {
    condition = alltrue([
      for m in var.subnet_mapping :
      can(regex("^subnet-[0-9a-f]{8,17}$", m.subnet_id))
    ])
    error_message = "All subnet_mapping[*].subnet_id must be valid subnet IDs."
  }

  validation {
    condition = alltrue([
      for m in var.subnet_mapping :
      m.allocation_id == null || can(regex("^eipalloc-[0-9a-f]{8,17}$", m.allocation_id))
    ])
    error_message = "subnet_mapping[*].allocation_id must be a valid EIP allocation ID (e.g., eipalloc-0abc12345) or null."
  }
}

# ─────────────────────────────────────────────────────────────
# TARGET GROUPS
# ─────────────────────────────────────────────────────────────

variable "target_groups" {
  description = <<-EOT
    Map of target group configurations. Key = logical name (used in outputs/listeners).
    target_type: instance | ip | alb | lambda (ALB only for lambda/alb)
    protocol:
      ALB  → HTTP | HTTPS
      NLB  → TCP | UDP | TCP_UDP | TLS
      GWLB → GENEVE (fixed)
  EOT
  type = map(object({
    port                               = optional(number, null)
    protocol                           = string
    protocol_version                   = optional(string, null)  # HTTP1, HTTP2, GRPC (ALB only)
    target_type                        = optional(string, "instance")
    deregistration_delay               = optional(number, 300)
    slow_start                         = optional(number, 0)     # ALB only, 30-900s or 0
    load_balancing_algorithm_type      = optional(string, null)  # round_robin | least_outstanding_requests | weighted_random (ALB)
    load_balancing_cross_zone_enabled  = optional(string, "use_load_balancer_configuration")
    lambda_multi_value_headers_enabled = optional(bool, false)   # ALB + lambda only
    proxy_protocol_v2                  = optional(bool, false)   # NLB only
    preserve_client_ip                 = optional(string, null)  # NLB only: "true"/"false"
    connection_termination             = optional(bool, false)   # NLB only

    health_check = optional(object({
      enabled             = optional(bool, true)
      path                = optional(string, null)
      port                = optional(string, "traffic-port")
      protocol            = optional(string, null)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      interval            = optional(number, 30)
      timeout             = optional(number, null)
      matcher             = optional(string, null)  # HTTP codes e.g. "200-299"
    }), {})

    stickiness = optional(object({
      enabled         = optional(bool, false)
      type            = string  # lb_cookie | app_cookie (ALB) | source_ip (NLB)
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string, null)  # required for app_cookie
    }), null)

    target_failover = optional(object({  # NLB only
      on_deregistration = optional(string, "no_rebalance")
      on_unhealthy      = optional(string, "no_rebalance")
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, tg in var.target_groups :
      contains(["instance", "ip", "alb", "lambda"], tg.target_type)
    ])
    error_message = "target_groups[*].target_type must be one of: instance, ip, alb, lambda."
  }

  validation {
    condition = alltrue([
      for k, tg in var.target_groups :
      contains(["HTTP", "HTTPS", "TCP", "UDP", "TCP_UDP", "TLS", "GENEVE"], tg.protocol)
    ])
    error_message = "target_groups[*].protocol must be one of: HTTP, HTTPS, TCP, UDP, TCP_UDP, TLS, GENEVE."
  }

  validation {
    condition = alltrue([
      for k, tg in var.target_groups :
      tg.deregistration_delay >= 0 && tg.deregistration_delay <= 3600
    ])
    error_message = "target_groups[*].deregistration_delay must be between 0 and 3600 seconds."
  }

  validation {
    condition = alltrue([
      for k, tg in var.target_groups :
      tg.slow_start == 0 || (tg.slow_start >= 30 && tg.slow_start <= 900)
    ])
    error_message = "target_groups[*].slow_start must be 0 (disabled) or between 30 and 900 seconds."
  }

  validation {
    condition = alltrue([
      for k, tg in var.target_groups :
      tg.protocol_version == null ||
      contains(["HTTP1", "HTTP2", "GRPC"], tg.protocol_version)
    ])
    error_message = "target_groups[*].protocol_version must be one of: HTTP1, HTTP2, GRPC (or null)."
  }
}

# ─────────────────────────────────────────────────────────────
# LISTENERS
# ─────────────────────────────────────────────────────────────

variable "listeners" {
  description = <<-EOT
    Map of listener configurations. Key = logical name.
    default_action.type: forward | redirect | fixed-response | authenticate-cognito | authenticate-oidc
    For NLB/GWLB only 'forward' is valid.
  EOT
  type = map(object({
    port              = number
    protocol          = string
    ssl_policy        = optional(string, null)  # Required for HTTPS/TLS
    certificate_arn   = optional(string, null)  # Required for HTTPS/TLS
    alpn_policy       = optional(string, null)  # NLB TLS: HTTP1Only|HTTP2Only|HTTP2Optional|HTTP2Preferred|None

    default_action = object({
      type             = string
      target_group_key = optional(string, null)  # References key in var.target_groups

      # redirect action
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
        host        = optional(string, null)
        path        = optional(string, null)
        query       = optional(string, null)
      }), null)

      # fixed-response action
      fixed_response = optional(object({
        content_type = string  # text/plain | text/html | application/json
        message_body = optional(string, null)
        status_code  = optional(string, "200")
      }), null)

      # authenticate-cognito (ALB only)
      authenticate_cognito = optional(object({
        user_pool_arn       = string
        user_pool_client_id = string
        user_pool_domain    = string
        on_unauthenticated_request = optional(string, "authenticate")
        scope                      = optional(string, "openid")
        session_cookie_name        = optional(string, "AWSELBAuthSessionCookie")
        session_timeout            = optional(number, 604800)
      }), null)

      # authenticate-oidc (ALB only)
      authenticate_oidc = optional(object({
        authorization_endpoint = string
        client_id              = string
        client_secret          = string
        issuer                 = string
        token_endpoint         = string
        user_info_endpoint     = string
        on_unauthenticated_request = optional(string, "authenticate")
        scope                      = optional(string, "openid")
        session_cookie_name        = optional(string, "AWSELBAuthSessionCookie")
        session_timeout            = optional(number, 604800)
      }), null)
    })

    # Additional certificates (SNI) — ALB/NLB TLS only
    additional_certificate_arns = optional(list(string), [])

    # Mutual TLS (mTLS) — ALB HTTPS / NLB TLS only
    mutual_authentication = optional(object({
      mode                             = string  # off | verify | passthrough
      trust_store_arn                  = optional(string, null)
      ignore_client_certificate_expiry = optional(bool, false)
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, l in var.listeners :
      contains(["HTTP", "HTTPS", "TCP", "UDP", "TCP_UDP", "TLS", "GENEVE"], l.protocol)
    ])
    error_message = "listeners[*].protocol must be one of: HTTP, HTTPS, TCP, UDP, TCP_UDP, TLS, GENEVE."
  }

  validation {
    condition = alltrue([
      for k, l in var.listeners :
      contains(["forward", "redirect", "fixed-response", "authenticate-cognito", "authenticate-oidc"], l.default_action.type)
    ])
    error_message = "listeners[*].default_action.type must be one of: forward, redirect, fixed-response, authenticate-cognito, authenticate-oidc."
  }

  validation {
    condition = alltrue([
      for k, l in var.listeners :
      !contains(["HTTPS", "TLS"], l.protocol) || l.ssl_policy != null
    ])
    error_message = "listeners[*].ssl_policy must be set when protocol is HTTPS or TLS."
  }

  validation {
    condition = alltrue([
      for k, l in var.listeners :
      !contains(["HTTPS", "TLS"], l.protocol) || l.certificate_arn != null
    ])
    error_message = "listeners[*].certificate_arn must be set when protocol is HTTPS or TLS."
  }

  validation {
    condition = alltrue([
      for k, l in var.listeners :
      l.alpn_policy == null ||
      contains(["HTTP1Only", "HTTP2Only", "HTTP2Optional", "HTTP2Preferred", "None"], l.alpn_policy)
    ])
    error_message = "listeners[*].alpn_policy must be one of: HTTP1Only, HTTP2Only, HTTP2Optional, HTTP2Preferred, None (or null)."
  }
}

# ─────────────────────────────────────────────────────────────
# LISTENER RULES (ALB only)
# ─────────────────────────────────────────────────────────────

variable "listener_rules" {
  description = <<-EOT
    ALB listener rules (path-based, host-based, header, etc.).
    Key format: "<listener_key>/<rule_name>" to associate with a specific listener.
  EOT
  type = map(object({
    listener_key = string
    priority     = number

    conditions = list(object({
      type   = string  # host-header | path-pattern | http-header | http-request-method | query-string | source-ip
      values = optional(list(string), [])

      # http-header condition
      http_header = optional(object({
        http_header_name = string
        values           = list(string)
      }), null)

      # query-string condition
      query_string = optional(list(object({
        key   = optional(string, null)
        value = string
      })), null)
    }))

    actions = list(object({
      type             = string
      order            = optional(number, null)
      target_group_key = optional(string, null)

      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
        host        = optional(string, null)
        path        = optional(string, null)
        query       = optional(string, null)
      }), null)

      fixed_response = optional(object({
        content_type = string
        message_body = optional(string, null)
        status_code  = optional(string, "200")
      }), null)

      # Weighted forward
      weighted_targets = optional(list(object({
        target_group_key = string
        weight           = number
      })), null)

      stickiness_duration = optional(number, null) # for weighted forward
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, r in var.listener_rules :
      r.priority >= 1 && r.priority <= 50000
    ])
    error_message = "listener_rules[*].priority must be between 1 and 50000."
  }

  validation {
    condition = alltrue([
      for k, r in var.listener_rules : alltrue([
        for c in r.conditions :
        contains(["host-header", "path-pattern", "http-header", "http-request-method", "query-string", "source-ip"], c.type)
      ])
    ])
    error_message = "listener_rules[*].conditions[*].type must be one of: host-header, path-pattern, http-header, http-request-method, query-string, source-ip."
  }
}

# ─────────────────────────────────────────────────────────────
# TARGET GROUP ATTACHMENTS (static, optional)
# ─────────────────────────────────────────────────────────────

variable "target_group_attachments" {
  description = <<-EOT
    Static target registrations. Useful for IP or fixed-instance targets.
    Key = unique identifier per attachment.
    For dynamic ASG-managed targets, leave empty and use ASG attachment outside this module.
  EOT
  type = map(object({
    target_group_key  = string
    target_id         = string  # Instance ID, IP, Lambda ARN
    port              = optional(number, null)
    availability_zone = optional(string, null)  # "all" for cross-zone (NLB IPs outside VPC)
  }))
  default = {}
}

# ─────────────────────────────────────────────────────────────
# WAF (ALB only)
# ─────────────────────────────────────────────────────────────

variable "waf_web_acl_arn" {
  description = "ARN of a WAFv2 WebACL to associate with the ALB. Leave null to skip."
  type        = string
  default     = null

  validation {
    condition     = var.waf_web_acl_arn == null || can(regex("^arn:aws[a-z-]*:wafv2:", var.waf_web_acl_arn))
    error_message = "waf_web_acl_arn must be a valid WAFv2 WebACL ARN or null."
  }
}

# ─────────────────────────────────────────────────────────────
# SHIELD ADVANCED (opt-in)
# ─────────────────────────────────────────────────────────────

variable "enable_shield_advanced" {
  description = "Register the LB with AWS Shield Advanced for DDoS protection."
  type        = bool
  default     = false
}

# ─────────────────────────────────────────────────────────────
# TIMEOUTS
# ─────────────────────────────────────────────────────────────

variable "timeouts" {
  description = "Custom resource timeouts for the aws_lb resource."
  type = object({
    create = optional(string, "10m")
    update = optional(string, "10m")
    delete = optional(string, "10m")
  })
  default = {}
}
