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
  # ── ENCRIPTACIÓN: SSE-KMS con clave administrada por el cliente ──
  # encryption = {
  #   sse_algorithm      = "aws:kms"
  #   kms_key_id         = "arn:aws:kms:us-east-1:223619873766:key/0e955eda-467c-4a31-9f63-6cad1a4c3569" # ← ARN de tu clave
  #   bucket_key_enabled = true                                                                          # ← Recomendado para reducir costos
  # }
  # ── VERSIONADO (recomendado para datos importantes) ──
  versioning = {
    enabled    = true
    mfa_delete = false
  }
  # ── LIFECYCLE RULE: Standard → Standard-IA a los 45 días ──
  lifecycle_rules = {
    "Rule-GoTo-IA" = {
      enabled = true
      # Sin prefix ni filter = aplica a TODOS los objetos del bucket
      transitions = [
        {
          days          = 45
          storage_class = "STANDARD_IA"
        }
      ]
    },
    "GoToGlacier" = {
      enabled = true
      # Sin prefix ni filter = aplica a TODOS los objetos del bucket
      transitions = [
        {
          days          = 120
          storage_class = "GLACIER"
        }
      ]
    },
    "Delete-365-days" = {
      enabled = true
      # Sin prefix ni filter = aplica a TODOS los objetos del bucket
      noncurrent_version_expiration = {
        noncurrent_days = 365
      }
    }
  }
}


# module "s3_static_website" {
#   source      = "../../modules/s3"
#   bucket_name = "${var.project_name}-${var.environment_name}-static-website"
#   environment = "dev"
#   tags = merge(var.vpc_custom_tags, {
#     Purpose = "StaticWebsite"
#   })

#   # ── SEGURIDAD: Permitir acceso público para website ──
#   object_ownership = "BucketOwnerEnforced"
#   block_public_access = {
#     block_public_acls       = false # ← Necesario para website público
#     block_public_policy     = false # ← Permitir policy pública
#     ignore_public_acls      = false
#     restrict_public_buckets = false
#   }

#   # ── ENCRIPTACIÓN ──
#   encryption = {
#     sse_algorithm      = "AES256"
#     kms_key_id         = null
#     bucket_key_enabled = false
#   }

#   # ── WEBSITE HOSTING ──
#   website = {
#     index_document = "index.html"
#     error_document = "error.html"
#   }

#   # ── POLÍTICA PÚBLICA PARA WEBSITE ──
#   bucket_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "PublicReadGetObject"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = "s3:GetObject"
#         Resource  = "arn:aws:s3:::${var.project_name}-${var.environment_name}-static-website/*"
#       }
#     ]
#   })
# }

module "s3_bucket_with_object_lock" {
  source      = "../../modules/s3"
  bucket_name = "${var.project_name}-${var.environment_name}-s3-bucket-with-object-lock"
  environment = "dev"
  tags        = var.vpc_custom_tags

  # ── OBJECT LOCK: Habilitar al crear el bucket ──
  object_lock_enabled = true

  # ── OBJECT LOCK CONFIGURATION: Governance con 1 día ──
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE" # Puede ser sobreescrito con permisos especiales
        days = 1            # Período de retención: 1 día
      }
    }
  }

  # ── SEGURIDAD BÁSICA ──
  object_ownership = "BucketOwnerEnforced"
  block_public_access = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  # ── ENCRIPTACIÓN ──
  encryption = {
    sse_algorithm      = "AES256"
    kms_key_id         = null
    bucket_key_enabled = false
  }

  # ── VERSIONADO (OBLIGATORIO para Object Lock) ──
  versioning = {
    enabled    = true
    mfa_delete = false
  }
}
