# ssh-keygen -t ed25519 -f ~/.ssh/bastiondev_connection
module "key_pair_dev" {
  source = "../../modules/key_pair"

  key_name   = "bastiondev_connection"
  public_key = file("~/.ssh/bastiondev_connection.pub")

  tags = {
    Environment = "produccion"
    Owner       = "equipo-devops"
  }
}

# # Requiere el provider TLS
# terraform {
#   required_providers {
#     tls = {
#       source  = "hashicorp/tls"
#       version = ">= 4.0"
#     }
#   }
# }

# # Genera una clave privada usando el provider TLS
# resource "tls_private_key" "generated" {
#   algorithm = "ED25519"
# }

# # Llama a tu módulo para subir la clave pública a AWS
# module "key_pair_automatizado" {
#   source = "./aws-key-pair"

#   key_name   = "acceso-temporal-ci-cd"
#   public_key = tls_private_key.generated.public_key_openssh

#   tags = {
#     Automation = "true"
#   }
# }

# (Opcional pero recomendado) Guarda la clave privada generada en un lugar seguro
# ¡ADVERTENCIA! Esto escribirá la clave privada en un archivo local.
# En producción, deberías guardarla en AWS Secrets Manager o HashiCorp Vault.
# resource "local_file" "private_key_pem" {
#   content  = tls_private_key.generated.private_key_pem
#   filename = "${path.module}/generated-key.pem"
#   file_permission = "0400" # Permisos de solo lectura para el usuario
# }
