module "nacl_allow_ingress" {
  source = "../../modules/nacl-allow-deny"

  acl_id      = module.vpc.default_network_acl_id
  rule_number = 100
  protocol    = "tcp"
  type        = "ingress" # o "egress" según sea necesario
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
}

module "nacl_allow_egress" {
  source = "../../modules/nacl-allow-deny"

  acl_id      = module.vpc.default_network_acl_id
  rule_number = 100
  protocol    = "tcp"
  type        = "egress"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  icmp_type   = null
  icmp_code   = null
}
