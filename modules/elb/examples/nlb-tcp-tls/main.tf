# ============================================================
# examples/nlb-tcp-tls/main.tf
# NLB with:
#   - Per-AZ EIP pinning (subnet_mapping)
#   - TCP listener (port 80)
#   - TLS listener (port 443) with mTLS verify mode
#   - Cross-zone disabled (cost optimisation)
#   - NLB preserve_client_ip enabled
#   - target_failover configuration
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.40.0" }
  }
}

provider "aws" { region = var.aws_region }

module "nlb" {
  source = "../../modules/elb"

  name        = "bsol-internal-nlb"
  lb_type     = "network"
  internal    = true
  environment = "prod"

  vpc_id     = var.vpc_id
  subnet_ids = []  # empty when using subnet_mapping

  # Pin one EIP per AZ
  subnet_mapping = [
    {
      subnet_id            = var.subnet_az1
      allocation_id        = var.eip_allocation_az1
      private_ipv4_address = null
    },
    {
      subnet_id            = var.subnet_az2
      allocation_id        = var.eip_allocation_az2
      private_ipv4_address = null
    },
  ]

  enable_deletion_protection = true

  nlb = {
    enable_cross_zone_load_balancing = false
    ip_address_type                  = "ipv4"
    dns_record_client_routing_policy = "availability_zone_affinity"
  }

  access_logs = {
    enabled = true
    bucket  = var.log_bucket
    prefix  = "nlb/bsol-internal"
  }

  # ── Target groups ───────────────────────────────────────────
  target_groups = {
    tcp_backends = {
      protocol             = "TCP"
      port                 = 8080
      target_type          = "instance"
      deregistration_delay = 120
      preserve_client_ip   = "true"
      proxy_protocol_v2    = false
      connection_termination = false

      target_failover = {
        on_deregistration = "rebalance"
        on_unhealthy      = "rebalance"
      }

      health_check = {
        protocol            = "TCP"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 10
      }
    }

    tls_backends = {
      protocol             = "TLS"
      port                 = 8443
      target_type          = "instance"
      deregistration_delay = 120
      preserve_client_ip   = "true"
      connection_termination = true  # drain TLS sessions on deregistration

      health_check = {
        protocol            = "HTTPS"
        path                = "/health"
        port                = "8443"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 15
        timeout             = 10
        matcher             = "200"
      }
    }
  }

  # ── Listeners ───────────────────────────────────────────────
  listeners = {
    tcp_80 = {
      port     = 80
      protocol = "TCP"
      default_action = {
        type             = "forward"
        target_group_key = "tcp_backends"
      }
    }

    tls_443 = {
      port            = 443
      protocol        = "TLS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = var.certificate_arn
      alpn_policy     = "HTTP2Preferred"

      default_action = {
        type             = "forward"
        target_group_key = "tls_backends"
      }

      mutual_authentication = {
        mode                             = "verify"
        trust_store_arn                  = var.mtls_trust_store_arn
        ignore_client_certificate_expiry = false
      }
    }
  }

  tags = {
    Project    = "bsol-internal"
    Owner      = "platform-engineering"
    CostCenter = "infra"
  }
}

# ── Variables ─────────────────────────────────────────────────

variable "aws_region"            { type = string; default = "us-east-1" }
variable "vpc_id"                { type = string }
variable "subnet_az1"            { type = string }
variable "subnet_az2"            { type = string }
variable "eip_allocation_az1"    { type = string }
variable "eip_allocation_az2"    { type = string }
variable "log_bucket"            { type = string }
variable "certificate_arn"       { type = string }
variable "mtls_trust_store_arn"  { type = string }

# ── Outputs ───────────────────────────────────────────────────

output "nlb_dns_name"      { value = module.nlb.lb_dns_name }
output "nlb_zone_id"       { value = module.nlb.lb_zone_id }
output "listener_arns"     { value = module.nlb.listener_arns }
output "target_group_arns" { value = module.nlb.target_group_arns }
