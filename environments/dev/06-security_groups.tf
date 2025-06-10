module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id                 = module.vpc.vpc_id
  name                   = "${var.project_name}-sg-${var.environment_name}"
  description            = "Security groups for ${var.project_name} in ${var.environment_name} environment"
  revoke_rules_on_delete = var.sg_revoke_rules_on_delete
  additional_tags        = var.vpc_custom_tags
  enable_http            = var.sg_enable_http
  enable_https           = var.sg_enable_https
  enable_ssh             = var.sg_enable_ssh
  ssh_cidr_blocks        = var.sg_ssh_cidr_blocks
  ingress_rules          = var.sg_ingress_rules
}
