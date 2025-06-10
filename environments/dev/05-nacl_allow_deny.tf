module "nacl_allow_ingress" {
  source = "../../modules/nacl_allow_deny"

  acl_id           = module.vpc.default_network_acl_id
  type             = "ingress" # o "egress" según sea necesario
  allow_deny_rules = var.nacl_allow_deny_ingress_rules
}

module "nacl_allow_egress" {
  source = "../../modules/nacl_allow_deny"

  acl_id           = module.vpc.default_network_acl_id
  type             = "egress"
  allow_deny_rules = var.nacl_allow_deny_egress_rules
}
