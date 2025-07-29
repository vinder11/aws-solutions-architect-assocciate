
# ==================================================
# main.tf
# ==================================================

# Rol IAM principal
resource "aws_iam_role" "this" {
  name                  = var.role_name
  description           = var.role_description
  assume_role_policy    = local.assume_role_policy
  max_session_duration  = var.max_session_duration
  path                  = var.path
  permissions_boundary  = var.permissions_boundary
  force_detach_policies = var.force_detach_policies

  tags = local.final_tags
}

# Adjuntar políticas administradas
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = toset(var.managed_policies)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Crear y adjuntar políticas inline
resource "aws_iam_role_policy" "inline_policies" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}
