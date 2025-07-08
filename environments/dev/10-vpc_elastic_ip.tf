# module "nat_gateway_eip" {
#   source = "../../modules/vpc_elastic_ip"

#   tags = merge(var.vpc_custom_tags, { Name = "${var.project_name}-${var.environment_name}-nat-gateway-eip" })
# }

# Posteriormente, puedes usar el ID de asignación en tu recurso de NAT Gateway:
# resource "aws_nat_gateway" "gw" {
#   allocation_id = module.nat_gateway_eip.allocation_id
#   ...
# }
