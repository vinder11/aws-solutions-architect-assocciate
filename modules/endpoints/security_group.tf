data "aws_vpc" "main" {
  count = var.default_security_group ? 1 : 0
  id    = var.vpc_id
}
# Security Group por defecto para endpoints de interfaz
resource "aws_security_group" "vpc_endpoints" {
  count = var.default_security_group ? 1 : 0

  name_prefix = "vpc-df-endpoints-"
  description = "Security group por defecto para VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS desde VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main[0].cidr_block]
  }

  ingress {
    description = "HTTP desde VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main[0].cidr_block]
  }

  egress {
    description = "Todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "vpc-endpoints-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
