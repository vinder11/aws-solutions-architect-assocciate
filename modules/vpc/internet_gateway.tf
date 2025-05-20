resource "aws_internet_gateway" "igw" {
  count = var.create_igw ? 1 : 0 # Esto creará 1 recurso si es true, 0 si es false

  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${var.vpc_name}-igw"
    },
    var.common_tags
  )
}
