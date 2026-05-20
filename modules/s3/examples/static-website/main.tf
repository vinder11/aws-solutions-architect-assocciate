# ============================================================
# examples/static-website/main.tf
# S3 static website with:
#   - Public read access (relaxed block_public_access)
#   - CORS for SPA (React/Vue)
#   - CloudFront-ready domain name output
#   - Lifecycle: abort multipart uploads after 7 days
#   - EventBridge notifications
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.40.0" }
  }
}

provider "aws" { region = var.aws_region }

module "website_bucket" {
  source = "../../modules/s3"

  bucket_name = "bsol-web-assets-${var.environment}"
  environment = var.environment
  force_destroy = var.environment != "prod"

  # ACLs required for public-read; relax ownership + public access
  object_ownership = "BucketOwnerPreferred"

  block_public_access = {
    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  }

  acl = "public-read"

  # SSE-S3 (public bucket — KMS adds friction for anonymous reads)
  encryption = {
    sse_algorithm = "AES256"
  }

  # Enforce HTTPS-only even for public bucket
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # Website hosting
  website = {
    index_document = "index.html"
    error_document = "404.html"
    routing_rules  = jsonencode([
      {
        Condition = { HttpErrorCodeReturnedEquals = "404" }
        Redirect  = { ReplaceKeyWith = "index.html", HttpRedirectCode = "200" }
      }
    ])
  }

  # CORS for SPA (allow API calls from the site origin)
  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://${var.domain_name}", "https://www.${var.domain_name}"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag", "Content-Length"]
      max_age_seconds = 3600
    }
  ]

  # Lifecycle: clean up stale multipart uploads
  lifecycle_rules = {
    abort_multipart = {
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      filter                                 = { prefix = "" }
    }
  }

  # EventBridge for deployment pipeline notifications
  notifications = {
    eventbridge      = true
    lambda_functions = {}
    queues           = {}
    topics           = {}
  }

  tags = {
    Project    = "bsol-website"
    Owner      = "frontend-team"
    CostCenter = "web"
  }
}

# ── Variables ─────────────────────────────────────────────────
variable "aws_region"   { type = string; default = "us-east-1" }
variable "environment"  { type = string; default = "prod" }
variable "domain_name"  { type = string }

# ── Outputs ───────────────────────────────────────────────────
output "bucket_id"                  { value = module.website_bucket.bucket_id }
output "website_endpoint"           { value = module.website_bucket.website_endpoint }
output "cloudfront_origin"          { value = module.website_bucket.cloudfront_origin }
output "route53_alias_target"       { value = module.website_bucket.route53_alias_target }
output "bucket_regional_domain_name" { value = module.website_bucket.bucket_regional_domain_name }
