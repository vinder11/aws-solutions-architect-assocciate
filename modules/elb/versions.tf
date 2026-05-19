# ============================================================
# versions.tf — terraform-aws-elb module
# ============================================================

terraform {
  required_version = ">= 1.6.0" # lifecycle preconditions + optional() object defaults

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0" # connection_logs, client_keep_alive, mTLS GA
    }
  }
}
