module "efs_one_zone" {
  source = "../../modules/efs" # o tu path al módulo
  name   = "${var.project_name}-${var.environment_name}-efs-one-zone"

  # ── PERFORMANCE MODE ──
  # NOTA: Según tus variables, solo acepta "generalPurpose" o "maxIO"
  # "Bursting" no es un performance_mode válido en tu módulo
  # Es un throughput_mode. Asumo que quieres:
  performance_mode = "generalPurpose" # ← General Purpose (baja latencia)

  # ── THROUGHPUT MODE ──
  # "Bursting" es throughput_mode, no performance_mode
  throughput_mode = "bursting"

  # ── ENCRIPTACIÓN ──
  encrypted = true
  # kms_key_id = null  # ← Usa AWS-managed key (default)

  # ── LIFECYCLE: IA a 30 días ──
  lifecycle_policy = {
    transition_to_ia      = "AFTER_30_DAYS" # ← Mueve a IA después de 30 días
    transition_to_primary = null            # ← None
    transition_to_archive = null            # ← None
  }

  # ── BACKUPS AUTOMÁTICOS ──
  enable_backup = true

  # ── NETWORKING (ejemplo, ajusta a tu VPC) ──
  vpc_id                 = module.vpc.vpc_id
  availability_zone_name = module.subnets.subnet_azs["public"] # Ajusta a tu AZ

  mount_targets = {
    "us-east-1a" = {
      subnet_id          = module.subnets.public_subnet_ids[0] # Ajusta al ID de tu subred en us-east-1a
      security_group_ids = []                                  # o ["sg-0abc1234567890def"]
      ip_address         = null
    }
  }

  # ── SECURITY GROUP ──
  create_security_group = true
  security_group_rules = {
    nfs_ingress = {
      type        = "ingress"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS inbound from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block] # Ajusta a tu VPC CIDR
    }
    all_egress = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # ── TAGS ──
  tags = merge(var.vpc_custom_tags, {
    Purpose = "EFS"
  })

}
