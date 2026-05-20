# ============================================================
# outputs.tf — terraform-aws-s3 module
# ============================================================

# ─────────────────────────────────────────────────────────────
# BUCKET CORE
# ─────────────────────────────────────────────────────────────

output "bucket_id" {
  description = "The name of the bucket (same as bucket_id in AWS provider)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name (bucket-name.s3.amazonaws.com)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name. Use this with CloudFront Origins."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region where the bucket is created."
  value       = aws_s3_bucket.this.region
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 hosted zone ID for the bucket's region (for alias records)."
  value       = aws_s3_bucket.this.hosted_zone_id
}

# ─────────────────────────────────────────────────────────────
# WEBSITE
# ─────────────────────────────────────────────────────────────

output "website_endpoint" {
  description = "The S3 static website endpoint URL (null if website hosting not configured)."
  value       = try(aws_s3_bucket_website_configuration.this[0].website_endpoint, null)
}

output "website_domain" {
  description = "The domain of the S3 static website endpoint (for Route 53 alias records)."
  value       = try(aws_s3_bucket_website_configuration.this[0].website_domain, null)
}

# ─────────────────────────────────────────────────────────────
# ENCRYPTION
# ─────────────────────────────────────────────────────────────

output "encryption_sse_algorithm" {
  description = "The SSE algorithm configured on the bucket."
  value       = var.encryption.sse_algorithm
}

output "encryption_kms_key_id" {
  description = "The KMS key ID used for SSE-KMS encryption (null for SSE-S3 or AWS-managed key)."
  value       = var.encryption.kms_key_id
  sensitive   = false
}

# ─────────────────────────────────────────────────────────────
# VERSIONING
# ─────────────────────────────────────────────────────────────

output "versioning_enabled" {
  description = "Whether versioning is enabled on the bucket."
  value       = var.versioning.enabled
}

# ─────────────────────────────────────────────────────────────
# TRANSFER ACCELERATION
# ─────────────────────────────────────────────────────────────

output "bucket_acceleration_endpoint" {
  description = "The accelerated endpoint URL (null if transfer acceleration not enabled)."
  value       = var.transfer_acceleration ? "${aws_s3_bucket.this.id}.s3-accelerate.amazonaws.com" : null
}

# ─────────────────────────────────────────────────────────────
# POLICY
# ─────────────────────────────────────────────────────────────

output "bucket_policy_applied" {
  description = "Whether a bucket policy was applied to this bucket."
  value       = local.final_policy != null
}

# ─────────────────────────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────────────────────────

output "logging_target_bucket" {
  description = "The target bucket for server access logs (null if logging not configured)."
  value       = try(aws_s3_bucket_logging.this[0].target_bucket, null)
}

output "logging_target_prefix" {
  description = "The prefix for server access logs."
  value       = try(aws_s3_bucket_logging.this[0].target_prefix, null)
}

# ─────────────────────────────────────────────────────────────
# REPLICATION
# ─────────────────────────────────────────────────────────────

output "replication_configuration_id" {
  description = "The ID of the replication configuration (null if not configured)."
  value       = try(aws_s3_bucket_replication_configuration.this[0].id, null)
}

# ─────────────────────────────────────────────────────────────
# OBJECT LOCK
# ─────────────────────────────────────────────────────────────

output "object_lock_enabled" {
  description = "Whether Object Lock is enabled on the bucket."
  value       = var.object_lock_enabled
}

output "object_lock_configuration" {
  description = "The Object Lock default retention configuration (null if not set)."
  value       = var.object_lock_configuration
}

# ─────────────────────────────────────────────────────────────
# CONVENIENCE HELPERS
# ─────────────────────────────────────────────────────────────

output "s3_uri" {
  description = "S3 URI in s3://bucket-name format."
  value       = "s3://${aws_s3_bucket.this.id}"
}

output "cloudfront_origin" {
  description = "Ready-to-use object for CloudFront S3 origin configuration."
  value = {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.this.id
    s3_origin_config_enabled = true
  }
}

output "route53_alias_target" {
  description = "Ready-to-use alias target object for aws_route53_record (website endpoint)."
  value = var.website != null ? {
    name                   = aws_s3_bucket_website_configuration.this[0].website_domain
    zone_id                = aws_s3_bucket.this.hosted_zone_id
    evaluate_target_health = false
  } : null
}

output "inventory_configuration_ids" {
  description = "Map of inventory configuration name → bucket ID."
  value       = { for k, v in aws_s3_bucket_inventory.this : k => v.id }
}

output "metrics_configuration_ids" {
  description = "Map of metrics configuration name → bucket ID."
  value       = { for k, v in aws_s3_bucket_metric.this : k => v.id }
}
