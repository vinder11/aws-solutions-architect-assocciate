# /vpc-project/environments/dev/vpc.tf

# Llamada al módulo VPC
# Aquí es donde se instancia el módulo VPC definido en /modules/vpc
module "vpc" {
  source = "../../modules/vpc" # Ruta relativa al módulo local

  vpc_name       = "${var.project_name}-vpc-${var.environment_name}"
  vpc_cidr_block = var.vpc_cidr_block_env

  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  create_igw           = true

  common_tags = merge(
    {
      Environment = var.environment_name
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.vpc_custom_tags # Incorpora etiquetas personalizadas del entorno
  )
}
