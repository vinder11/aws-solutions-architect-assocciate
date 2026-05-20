# ============================================================
# versions.tf — terraform-aws-s3 module
# ============================================================

terraform {
  required_version = ">= 1.6.0" # optional() defaults in objects + lifecycle preconditions

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0" # partitioned_prefix logging, DSSE-KMS, connection_logs
    }
  }
}
