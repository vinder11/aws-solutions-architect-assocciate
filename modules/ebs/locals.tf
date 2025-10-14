# ============================================
# LOCALS
# ============================================

locals {
  # Combinar tags por defecto con tags específicos del volumen
  volume_tags = {
    for k, v in var.ebs_volumes : k => merge(
      var.default_tags,
      v.tags,
      {
        Name      = k
        ManagedBy = "Terraform"
      }
    )
  }

  # Calcular IOPS automáticamente para gp3 si no se especifica
  volume_iops = {
    for k, v in var.ebs_volumes : k => (
      v.iops != null ? v.iops :
      v.type == "gp3" ? min(16000, max(3000, v.size * 3)) :
      v.type == "io1" || v.type == "io2" ? max(100, min(64000, v.size * 50)) :
      null
    )
  }

  # Calcular throughput para gp3 si no se especifica
  volume_throughput = {
    for k, v in var.ebs_volumes : k => (
      v.throughput != null ? v.throughput :
      v.type == "gp3" ? 125 :
      null
    )
  }
}
