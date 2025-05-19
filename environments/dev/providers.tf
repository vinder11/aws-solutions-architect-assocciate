# /vpc-project/environments/dev/providers.tf

# Configuración del backend y versiones requeridas de Terraform y proveedores
terraform {
  required_version = ">= 1.0" # Especifica la versión mínima de Terraform

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Especifica una versión compatible del proveedor de AWS
    }
  }

  # Opcional: Configuración del backend para el estado de Terraform.
  # Es una buena práctica para entornos colaborativos o de producción.
  # backend "s3" {
  #   bucket         = "mi-terraform-state-bucket-unico" # Reemplazar con tu bucket S3
  #   key            = "environments/dev/vpc/terraform.tfstate"
  #   region         = "us-east-1" # Región del bucket S3
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock-table" # Reemplazar con tu tabla DynamoDB para locks
  # }
}

# Configuración del proveedor de AWS
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
