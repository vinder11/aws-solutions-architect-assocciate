# ==================================================
# locals.tf
# ==================================================

locals {
  # Generar la política de asunción basada en trusted_entities si no se proporciona assume_role_policy
  default_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Servicios de AWS
      length(var.trusted_entities.services) > 0 ? [{
        Effect = "Allow"
        Principal = {
          Service = var.trusted_entities.services
        }
        Action = "sts:AssumeRole"
      }] : [],

      # Cuentas de AWS
      length(var.trusted_entities.aws_accounts) > 0 ? [{
        Effect = "Allow"
        Principal = {
          AWS = [for account in var.trusted_entities.aws_accounts : "arn:aws:iam::${account}:root"]
        }
        Action = "sts:AssumeRole"
      }] : [],

      # Proveedores federados
      length(var.trusted_entities.federated) > 0 ? [{
        Effect = "Allow"
        Principal = {
          Federated = var.trusted_entities.federated
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }] : [],

      # Usuarios específicos
      length(var.trusted_entities.users) > 0 ? [{
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_entities.users
        }
        Action = "sts:AssumeRole"
      }] : [],

      # Roles específicos
      length(var.trusted_entities.roles) > 0 ? [{
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_entities.roles
        }
        Action = "sts:AssumeRole"
      }] : []
    )
  })

  # Usar la política proporcionada o generar una por defecto
  assume_role_policy = var.assume_role_policy != null ? var.assume_role_policy : local.default_assume_role_policy

  # Combinar tags por defecto con las proporcionadas
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "aws-iam-role"
  }

  final_tags = merge(local.default_tags, var.tags)
}
