locals {
  # Filtrar subnets públicas y privadas para simplificar outputs
  public_subnets = {
    for k, v in aws_subnet.this : k => v if lookup(var.subnets[k], "public", false)
  }

  private_subnets = {
    for k, v in aws_subnet.this : k => v if !lookup(var.subnets[k], "public", false)
  }
}
