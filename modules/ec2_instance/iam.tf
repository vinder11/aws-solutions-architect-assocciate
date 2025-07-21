# Resource - IAM Role
resource "aws_iam_role" "this" {
  count = local.is_module_enabled && var.create_iam_instance_profile ? 1 : 0
  # ^ Crea el rol solo si el módulo está habilitado Y se solicita crear un perfil IAM
  # count permite creación condicional (0 o 1 veces)

  name = "${local.name_prefix}-ec2-role"
  # ^ Nombre del rol, usando el prefijo generado en locals
  # Formato: <nombre>-<ambiente>-<proyecto>-ec2-role

  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  # ^ Política que define qué entidades pueden asumir este rol
  # Referencia al data source definido abajo que contiene la política

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-ec2-role"
    # ^ Tags combinados: los default_tags más un tag Name específico
  })
}

# Resource - IAM Role Policy Attachment (para políticas gestionadas por AWS)
resource "aws_iam_role_policy_attachment" "managed" {
  count = local.is_module_enabled && var.create_iam_instance_profile ? length(var.iam_role_policy_arns) : 0
  # ^ Crea adjuntos de políticas por cada ARN proporcionado
  # Solo si el módulo está habilitado Y se crea perfil IAM
  # count = número de ARNs proporcionados en var.iam_role_policy_arns

  role = aws_iam_role.this[0].name
  # ^ Nombre del rol creado anteriormente
  # [0] porque aunque count=1, es una lista

  policy_arn = var.iam_role_policy_arns[count.index]
  # ^ ARN de la política a adjuntar
  # count.index recorre cada elemento de var.iam_role_policy_arns
}

# Resource - IAM Role Policy (para políticas personalizadas inline)
resource "aws_iam_role_policy" "custom" {
  count = local.is_module_enabled && var.create_iam_instance_profile ? length(var.iam_role_policies) > 0 ? 1 : 0 : 0
  # ^ Crea una política inline si:
  # 1. Módulo habilitado
  # 2. Se crea perfil IAM
  # 3. Hay políticas personalizadas definidas (length > 0)
  # Nota: Solo crea UNA política que agrupa todos los permisos

  name = "${local.name_prefix}-ec2-custom-policy"
  # ^ Nombre de la política inline

  role = aws_iam_role.this[0].name
  # ^ Rol al que se asocia esta política

  policy = jsonencode({
    # ^ Política en formato JSON (convertido de HCL con jsonencode)
    Version = "2012-10-17"
    Statement = [for policy in var.iam_role_policies : {
      # ^ Crea un Statement por cada política definida en var.iam_role_policies
      Effect = "Allow"
      # ^ Todos los statements son de tipo Allow
      Action = split(",", policy)
      # ^ Divide la cadena de acciones (separadas por comas) en una lista
      Resource = "*"
      # ^ Aplica a todos los recursos (se podría parametrizar esto)
    }]
  })
}

# Resource - IAM Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = local.is_module_enabled && var.create_iam_instance_profile ? 1 : 0
  # ^ Crea el instance profile si:
  # 1. Módulo habilitado
  # 2. Se solicita crear perfil IAM (var.create_iam_instance_profile)

  name = "${local.name_prefix}-ec2-profile"
  # ^ Nombre del instance profile

  role = aws_iam_role.this[0].name
  # ^ Rol IAM que se asociará a las instancias EC2

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-ec2-profile"
    # ^ Tags combinados con nombre específico
  })
}

# Data Source - IAM Policy Document (para la política de asunción de roles)
data "aws_iam_policy_document" "assume_role" {
  count = var.create_iam_instance_profile ? 1 : 0
  # ^ Crea el documento de política solo si se va a crear un perfil IAM

  statement {
    effect = "Allow"
    # ^ El efecto es permitir
    actions = ["sts:AssumeRole"]
    # ^ Acción permitida: asumir este rol

    principals {
      type = "Service"
      # ^ Tipo de entidad que puede asumir el rol
      identifiers = ["ec2.amazonaws.com"]
      # ^ Servicio EC2 puede asumir este rol
    }
  }
}
