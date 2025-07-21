locals {
  # Control de habilitación del módulo
  is_module_enabled = var.module_enabled && var.create_ec2_instance

  # Generación de nombres de recursos combinando name, environment y project
  name_prefix = join("-", compact([var.name, var.environment, var.project]))

  # Lógica de selección de AMI: usa ami_id si está definida, sino busca con los filtros
  ami_id = coalesce(
    var.ami_id,
    try(data.aws_ami.selected[0].id, null)
  )

  # Tags base que se aplicarán a todos los recursos
  default_tags = merge(
    {
      Name        = local.name_prefix
      Environment = var.environment
      Project     = var.project
      Terraform   = "true"
    },
    var.tags
  )

  # Manejo de security groups: crea uno nuevo o usa los existentes
  security_group_ids = var.create_security_group ? concat(
    [aws_security_group.this[0].id],
    var.security_group_ids
  ) : var.security_group_ids

  # Manejo de IAM: crea un perfil nuevo o usa uno existente
  iam_instance_profile_name = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : var.iam_instance_profile

  # Selección de subnets: usa la lista de subnets o la subnet individual
  subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : [var.subnet_id]

  # Determina si son instancias spot (basado en si se definió spot_price)
  is_spot_instance = var.spot_price != null
}

# Data source para buscar AMIs basado en filtros
data "aws_ami" "selected" {
  count = var.ami_id == null && length(var.ami_filter) > 0 ? 1 : 0

  most_recent = true                                   # Siempre usa la AMI más reciente que cumpla los filtros
  owners      = try(var.ami_filter.owners, ["amazon"]) # Por defecto busca AMIs de Amazon

  # Filtros dinámicos basados en la variable ami_filter
  dynamic "filter" {
    for_each = {
      name         = try(var.ami_filter.name, "amzn2-ami-hvm-*") # Por defecto busca AMIs de Amazon Linux 2
      architecture = try(var.ami_filter.architecture, "x86_64")  # Por defecto arquitectura x86_64
      state        = try(var.ami_filter.state, "available")      # Por defecto solo AMIs disponibles
    }

    content {
      name   = filter.key     # Nombre del filtro (name, architecture, state)
      values = [filter.value] # Valor del filtro
    }
  }
}
