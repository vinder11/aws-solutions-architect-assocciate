# Resource - AWS Backup Plan
resource "aws_backup_plan" "this" {
  count = local.is_module_enabled && var.backup_enabled ? 1 : 0
  # ^ Crea el plan de backup solo si:
  # 1. El módulo está habilitado (local.is_module_enabled)
  # 2. Los backups están activados (var.backup_enabled = true)
  # count=0 o 1 para creación condicional

  name = "${local.name_prefix}-backup-plan"
  # ^ Nombre del plan de backup usando el prefijo generado en locals
  # Formato: <nombre>-<ambiente>-<proyecto>-backup-plan

  rule {
    rule_name = "${local.name_prefix}-daily-backup"
    # ^ Nombre de la regla dentro del plan
    target_vault_name = aws_backup_vault.this[0].name
    # ^ Nombre del vault donde se guardarán los backups
    # Referencia al vault creado más abajo

    schedule = var.backup_schedule
    # ^ Programación de los backups en formato cron
    # Por defecto: "cron(0 2 * * ? *)" (diario a las 2 AM)

    lifecycle {
      delete_after = var.backup_retention_days
      # ^ Días de retención antes de borrar automáticamente
      # Valor por defecto: 7 días
    }
  }

  tags = local.default_tags
  # ^ Tags aplicados al plan de backup
}

# Resource - AWS Backup Vault
resource "aws_backup_vault" "this" {
  count = local.is_module_enabled && var.backup_enabled ? 1 : 0
  # ^ Crea el vault de backup bajo las mismas condiciones que el plan

  name = "${local.name_prefix}-backup-vault"
  # ^ Nombre del vault usando el prefijo
  # Formato: <nombre>-<ambiente>-<proyecto>-backup-vault

  kms_key_arn = var.root_block_device.kms_key_id
  # ^ ARN de la clave KMS para encriptar los backups
  # Usa la misma clave que el dispositivo raíz de la instancia
  # Si no se especifica, AWS usa su clave por defecto

  tags = local.default_tags
  # ^ Tags aplicados al vault
}

# Resource - AWS Backup Selection
resource "aws_backup_selection" "this" {
  count = local.is_module_enabled && var.backup_enabled ? 1 : 0
  # ^ Crea la selección de recursos a respaldar bajo las mismas condiciones

  name = "${local.name_prefix}-backup-selection"
  # ^ Nombre de la selección

  plan_id = aws_backup_plan.this[0].id
  # ^ ID del plan de backup creado anteriormente

  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSBackupDefaultServiceRole"
  # ^ Rol IAM que AWS Backup usará
  # Usa el rol por defecto del servicio (debe existir previamente)

  resources = local.is_spot_instance ? (
    aws_spot_instance_request.this[*].arn
    ) : (
    aws_instance.this[*].arn
  )
  # ^ ARNs de los recursos a respaldar:
  # - Si son instancias spot, usa sus ARNs
  # - Si son instancias regulares, usa esos ARNs
  # [*] es el splat operator para obtener todos los elementos
}

# Data Source - AWS Caller Identity
data "aws_caller_identity" "current" {}
# ^ Data source que obtiene información sobre la cuenta AWS actual
# Necesario para construir el ARN del rol IAM de Backup
