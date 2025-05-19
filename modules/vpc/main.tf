# /vpc-project/modules/vpc/main.tf

# Creación del recurso VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    var.common_tags,
    {
      Name = var.vpc_name
    }
  )
}

# Gestión del Grupo de Seguridad por defecto de la VPC.
# Esto permite modificar sus reglas (aunque no se hace aquí) y, crucialmente, etiquetarlo.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id # Asocia este recurso con el SG por defecto de la VPC creada.

  # Ejemplo: podrías añadir reglas de egreso aquí si fuera necesario.
  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-default-sg"
    }
  )
}

# Gestión de la ACL de Red por defecto de la VPC.
# Permite aplicar etiquetas y gestionar sus reglas (no se añaden reglas aquí).
resource "aws_default_network_acl" "default" {
  # Este ID es el de la ACL por defecto creada automáticamente con la VPC.
  # Este recurso la "adopta" para gestionarla con Terraform.
  default_network_acl_id = aws_vpc.main.default_network_acl_id

  # Ejemplo: podrías añadir reglas de entrada/salida aquí.
  # subnet_ids = [aws_subnet.example.id] # Si quisieras asociarla explícitamente, aunque es la default.

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-default-nacl" # Corregido el nombre para consistencia
    }
  )
}

# Gestión de la Tabla de Ruteo por defecto de la VPC.
# Permite aplicar etiquetas y gestionar sus rutas (no se añaden rutas aquí).
resource "aws_default_route_table" "default" {
  # Este ID es el de la tabla de ruteo por defecto creada automáticamente con la VPC.
  # Este recurso la "adopta" para gestionarla con Terraform.
  default_route_table_id = aws_vpc.main.default_route_table_id

  # Ejemplo: podrías añadir rutas aquí, aunque las rutas para subredes específicas
  # se gestionan mejor en tablas de ruteo dedicadas.
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.gw.id # Si tuvieras un IGW
  # }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-default-rt"
    }
  )
}
