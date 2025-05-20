resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = lookup(each.value, "availability_zone", element(var.azs, index(keys(var.subnets), each.key) % length(var.azs)))
  map_public_ip_on_launch = lookup(each.value, "public", false)

  tags = merge(
    {
      "Name" = format("%s-%s", var.name, each.key)
    },
    var.tags,
    lookup(each.value, "tags", {}),
    {
      "Type" = lookup(each.value, "public", false) ? "public" : "private"
    }
  )
}
