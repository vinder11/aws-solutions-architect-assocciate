module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id                 = module.vpc.vpc_id
  name                   = "${var.project_name}-sg-${var.environment_name}"
  description            = "Security groups for ${var.project_name} in ${var.environment_name} environment"
  revoke_rules_on_delete = true
  additional_tags        = var.vpc_custom_tags
  enable_http            = true
  enable_https           = true
  # enable_ssh = true
  # ssh_cidr_blocks = [""]
  ingress_rules = [
    {
      description = "Allow HTTP traffic"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["10.110.100.24/32", "10.110.100.17/32"]
    },
    {
      description = "Allow RDS Postgres traffic"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.110.100.24/32", "10.110.100.17/32"]
    },
  ]

}
