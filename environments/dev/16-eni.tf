# # ========================================
# # EJEMPLOS DE USO
# # ========================================

# # Ejemplo 1: ENI básico sin attachment
# module "eni_basic" {
#   source = "../../modules/eni"

#   eni_name           = "app-eni-basic"
#   subnet_id          = "subnet-12345678"
#   security_group_ids = ["sg-12345678"]
#   environment        = "dev"
#   project            = "my-project"
# }

# # Ejemplo 2: ENI con IP específica y adjunto a instancia
# module "eni_with_attachment" {
#   source = "../../modules/eni"

#   eni_name           = "app-eni-attached"
#   subnet_id          = "subnet-12345678"
#   private_ips        = ["10.0.1.100"]
#   security_group_ids = ["sg-12345678"]

#   attach_to_instance = true
#   instance_id        = "i-1234567890abcdef0"
#   device_index       = 1

#   environment = "prod"
#   project     = "my-project"
# }

# # Ejemplo 3: ENI con múltiples IPs privadas
# module "eni_multi_ip" {
#   source = "../../modules/eni"

#   eni_name  = "lb-eni-multi"
#   subnet_id = "subnet-12345678"
#   private_ips = [
#     "10.0.1.100",
#     "10.0.1.101",
#     "10.0.1.102"
#   ]
#   security_group_ids = ["sg-12345678"]
#   description        = "ENI for load balancer with multiple IPs"
#   environment        = "prod"
# }

# # Ejemplo 4: ENI para NAT (sin source/dest check)
# module "eni_nat" {
#   source = "../../modules/eni"

#   eni_name           = "nat-eni"
#   subnet_id          = "subnet-12345678"
#   security_group_ids = ["sg-nat-12345678"]
#   source_dest_check  = false

#   attach_to_instance = true
#   instance_id        = "i-nat-instance"
#   device_index       = 1

#   environment = "prod"
#   project     = "networking"

#   tags = {
#     Role = "NAT"
#   }
# }

# # Ejemplo 5: ENI con IPs automáticas
# module "eni_auto_ips" {
#   source = "../../modules/eni"

#   eni_name           = "app-eni-auto"
#   subnet_id          = "subnet-12345678"
#   private_ip_count   = 3
#   security_group_ids = ["sg-12345678"]
#   environment        = "staging"
# }

# # Ejemplo 6: ENI con IPv6
# module "eni_ipv6" {
#   source = "../../modules/eni"

#   eni_name           = "app-eni-ipv6"
#   subnet_id          = "subnet-12345678"
#   security_group_ids = ["sg-12345678"]
#   ipv6_address_count = 1
#   environment        = "dev"
# }

# # Ejemplo 7: ENI condicional (usando create_eni)
# module "eni_conditional" {
#   source = "../../modules/eni"

#   create_eni         = var.enable_secondary_eni
#   eni_name           = "app-eni-conditional"
#   subnet_id          = "subnet-12345678"
#   security_group_ids = ["sg-12345678"]
#   environment        = "dev"
# }
