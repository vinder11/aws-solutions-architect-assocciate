# Módulo para crear subredes
module "subnets" {
  source = "../../modules/subnets"

  name   = "${var.project_name}-subnet-${var.environment_name}"
  vpc_id = module.vpc.vpc_id
  azs    = ["${var.aws_region}a"] # ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  # Definición de subredes usando formato de mapa
  subnets = {
    public = {
      cidr_block = var.public_subnet_cidr
      public     = true
      tags = {
        Type = "Public"
      }
    },
    private = {
      cidr_block = var.private_subnet_cidr
      public     = false
      tags = {
        Type = "Private"
      }
    }
  }

  tags = var.vpc_custom_tags # Etiquetas personalizadas del entorno
}
