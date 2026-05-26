# ============================================================
# versions.tf — terraform-aws-efs module
# ============================================================

terraform {
  required_version = ">= 1.6.0" # lifecycle preconditions + optional() object defaults

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34.0" # aws_vpc_security_group_ingress/egress_rule GA, EFS Archive tier
    }
  }
}
