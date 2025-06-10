# Configuración de Route53 Private Hosted Zone para endpoints de servicio
resource "aws_route53_zone" "endpoint" {
  count = var.create_route53_private_zone ? 1 : 0

  name          = var.route53_zone_name
  comment       = "Private hosted zone for VPC endpoints"
  force_destroy = false

  vpc {
    vpc_id = var.vpc_id
  }

  tags = var.tags
}

resource "aws_route53_record" "endpoint" {
  for_each = var.create_route53_private_zone ? {
    for endpoint in var.endpoints : endpoint.name => endpoint
    if try(endpoint.private_dns_enabled, true)
  } : {}

  zone_id = aws_route53_zone.endpoint[0].id
  name = replace(
    replace(each.value.service_name, "com.amazonaws.", ""),
    ".${var.aws_region}", ""
  )
  type    = "CNAME"
  ttl     = 300
  records = [aws_vpc_endpoint.this[each.value.name].dns_entry[0].dns_name]
}
