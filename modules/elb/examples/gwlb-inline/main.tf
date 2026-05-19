# ============================================================
# examples/gwlb-inline/main.tf
# Gateway Load Balancer for inline traffic inspection:
#   - GENEVE protocol target group (virtual appliances)
#   - Single GENEVE listener on port 6081
#   - IP targets (appliance ENI IPs)
#   - Cross-zone enabled (appliances may span AZs)
# Typical use: Palo Alto, Fortinet, CheckPoint NGFW inline
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.40.0" }
  }
}

provider "aws" { region = var.aws_region }

module "gwlb" {
  source = "../../modules/elb"

  name        = "bsol-fw-gwlb"
  lb_type     = "gateway"
  internal    = true   # GWLB is always internal
  environment = "prod"

  vpc_id     = var.vpc_id
  subnet_ids = var.appliance_subnet_ids

  enable_deletion_protection = true

  access_logs = {
    enabled = true
    bucket  = var.log_bucket
    prefix  = "gwlb/bsol-fw"
  }

  # ── Target group — GENEVE is mandatory for GWLB ─────────────
  target_groups = {
    fw_appliances = {
      protocol             = "GENEVE"
      port                 = 6081
      target_type          = "ip"  # point at appliance ENI IPs
      deregistration_delay = 300

      # GWLB health check: typically TCP or HTTPS to appliance mgmt port
      health_check = {
        protocol            = "TCP"
        port                = "80"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 10
      }
    }
  }

  # ── Listener — GWLB only supports GENEVE/6081 ───────────────
  listeners = {
    geneve = {
      port     = 6081
      protocol = "GENEVE"
      default_action = {
        type             = "forward"
        target_group_key = "fw_appliances"
      }
    }
  }

  # Static appliance IP registrations
  target_group_attachments = {
    fw_az1 = {
      target_group_key  = "fw_appliances"
      target_id         = var.appliance_ip_az1
      availability_zone = null
    }
    fw_az2 = {
      target_group_key  = "fw_appliances"
      target_id         = var.appliance_ip_az2
      availability_zone = null
    }
  }

  tags = {
    Project    = "bsol-security"
    Owner      = "security-engineering"
    CostCenter = "security"
  }
}

# ── VPC Endpoint Service (expose GWLB to spoke VPCs) ─────────
resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [module.gwlb.lb_arn]

  tags = {
    Name = "bsol-fw-gwlb-endpoint-service"
  }
}

# ── Variables ─────────────────────────────────────────────────

variable "aws_region"             { type = string; default = "us-east-1" }
variable "vpc_id"                 { type = string }
variable "appliance_subnet_ids"   { type = list(string) }
variable "appliance_ip_az1"       { type = string }
variable "appliance_ip_az2"       { type = string }
variable "log_bucket"             { type = string }

# ── Outputs ───────────────────────────────────────────────────

output "gwlb_arn"                    { value = module.gwlb.lb_arn }
output "gwlb_dns_name"               { value = module.gwlb.lb_dns_name }
output "target_group_arns"           { value = module.gwlb.target_group_arns }
output "endpoint_service_name"       { value = aws_vpc_endpoint_service.gwlb.service_name }
output "endpoint_service_id"         { value = aws_vpc_endpoint_service.gwlb.id }
