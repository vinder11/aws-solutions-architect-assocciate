module "s3" {
  source      = "../../modules/s3"
  bucket_name = "${var.project_name}-${var.environment_name}-s3-bucket"
  environment = "dev"
  tags        = var.vpc_custom_tags
  # ── SEGURIDAD BÁSICA (ya vienen por defecto, explícito por claridad) ──
  object_ownership = "BucketOwnerEnforced"
  block_public_access = {
    block_public_acls       = true # default
    block_public_policy     = true # default
    ignore_public_acls      = true # default
    restrict_public_buckets = true # default
  }
  # ── ENCRIPTACIÓN (SSE-S3 gratuita, default es aws:kms) ──
  encryption = {
    sse_algorithm      = "AES256" # SSE-S3 sin KMS
    kms_key_id         = null
    bucket_key_enabled = false
  }
  # ── VERSIONADO (recomendado para datos importantes) ──
  versioning = {
    enabled    = true
    mfa_delete = false
  }
}
