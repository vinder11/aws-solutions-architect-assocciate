module "alb" {
  source = "../../modules/elb"

  name        = "${var.project_name}-web-alb"
  lb_type     = "application"
  internal    = false
  environment = var.environment_name

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.subnets.public_subnet_ids
  security_group_ids = [module.security_groups.security_group_id]

  enable_deletion_protection = false

  # ── ALB tuning ─────────────────────────────────────────────
  # alb = {
  #   idle_timeout               = 120
  #   drop_invalid_header_fields = true
  #   preserve_host_header       = true
  #   desync_mitigation_mode     = "defensive"
  #   enable_http2               = true
  #   xff_header_processing_mode = "append"
  #   ip_address_type            = "dualstack"
  #   client_keep_alive          = 3600
  # }

  # ── Access & connection logs ────────────────────────────────
  # access_logs = {
  #   enabled = true
  #   bucket  = var.log_bucket
  #   prefix  = "alb/bsol-web"
  # }

  # connection_logs = {
  #   enabled = true
  #   bucket  = var.log_bucket
  #   prefix  = "alb/bsol-web/connections"
  # }

  # ── Target groups ───────────────────────────────────────────
  target_groups = {
    # Main app — instance targets
    app-main = {
      protocol                      = "HTTP"
      port                          = 80
      protocol_version              = "HTTP1"
      target_type                   = "instance"
      deregistration_delay          = 60
      slow_start                    = 60
      load_balancing_algorithm_type = "round_robin"

      health_check = {
        path                = "/"
        protocol            = "HTTP"
        healthy_threshold   = 5
        unhealthy_threshold = 2
        interval            = 30
        timeout             = 5
        matcher             = "200-299"
      }

      # stickiness = {
      #   enabled         = true
      #   type            = "lb_cookie"
      #   cookie_duration = 86400
      # }
    }

    # gRPC microservice — IP targets
    # grpc_svc = {
    #   protocol         = "HTTP"
    #   port             = 9090
    #   protocol_version = "GRPC"
    #   target_type      = "ip"

    #   health_check = {
    #     path     = "/grpc.health.v1.Health/Check"
    #     protocol = "HTTP"
    #     matcher  = "0,12"
    #   }
    # }

    # Canary / blue-green target
    # app_canary = {
    #   protocol             = "HTTP"
    #   port                 = 8080
    #   target_type          = "instance"
    #   deregistration_delay = 30

    #   health_check = {
    #     path    = "/health"
    #     matcher = "200"
    #   }
    # }
  }

  target_group_attachments = {
    ec2-instance = {
      target_group_key = "app-main"
      target_id        = module.ec2_instances.instance_ids[0] # module.ec2_instances.web_instance_ids
      port             = 80
    }
  }

  # ── Listeners ───────────────────────────────────────────────
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      # default_action = {
      #   type = "redirect"
      #   redirect = {
      #     port        = "443"
      #     protocol    = "HTTPS"
      #     status_code = "HTTP_301"
      #   }
      # }
      default_action = {
        type             = "forward"
        target_group_key = "app-main"
      }
    }

    # https = {
    #   port                        = 443
    #   protocol                    = "HTTPS"
    #   ssl_policy                  = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    #   certificate_arn             = var.certificate_arn
    #   additional_certificate_arns = var.additional_certificate_arns

    #   default_action = {
    #     type             = "forward"
    #     target_group_key = "app_main"
    #   }

    #   mutual_authentication = {
    #     mode            = "passthrough"
    #     trust_store_arn = null # passthrough doesn't require a trust store
    #   }
    # }
  }

  # ── ALB listener rules ──────────────────────────────────────
  # listener_rules = {
  #   # Route /api/v1/* to main app
  #   api_path = {
  #     listener_key = "https"
  #     priority     = 10
  #     conditions = [
  #       { type = "path-pattern", values = ["/api/v1/*"] }
  #     ]
  #     actions = [
  #       { type = "forward", target_group_key = "app_main" }
  #     ]
  #   }

  #   # Route gRPC requests by content-type header
  #   # grpc_header = {
  #   #   listener_key = "https"
  #   #   priority     = 20
  #   #   conditions = [
  #   #     {
  #   #       type = "http-header"
  #   #       http_header = {
  #   #         http_header_name = "Content-Type"
  #   #         values           = ["application/grpc*"]
  #   #       }
  #   #     }
  #   #   ]
  #   #   actions = [
  #   #     { type = "forward", target_group_key = "grpc_svc" }
  #   #   ]
  #   # }

  #   # Canary: 10% of /beta/* traffic to canary TG
  #   # canary_weighted = {
  #   #   listener_key = "https"
  #   #   priority     = 30
  #   #   conditions = [
  #   #     { type = "path-pattern", values = ["/beta/*"] }
  #   #   ]
  #   #   actions = [
  #   #     {
  #   #       type = "forward"
  #   #       weighted_targets = [
  #   #         { target_group_key = "app_main", weight = 90 },
  #   #         { target_group_key = "app_canary", weight = 10 }
  #   #       ]
  #   #       stickiness_duration = 300
  #   #     }
  #   #   ]
  #   # }

  #   # Health check bypass (return 200 immediately)
  #   # healthcheck_bypass = {
  #   #   listener_key = "https"
  #   #   priority     = 1
  #   #   conditions = [
  #   #     { type = "path-pattern", values = ["/ping"] }
  #   #   ]
  #   #   actions = [
  #   #     {
  #   #       type = "fixed-response"
  #   #       fixed_response = {
  #   #         content_type = "text/plain"
  #   #         message_body = "pong"
  #   #         status_code  = "200"
  #   #       }
  #   #     }
  #   #   ]
  #   # }
  # }

  # waf_web_acl_arn = var.waf_web_acl_arn

  tags = var.vpc_custom_tags
}
