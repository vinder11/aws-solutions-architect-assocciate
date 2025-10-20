# # ==============================================================================
# # EJEMPLO 1: Launch Template Básico
# # ==============================================================================
module "basic_launch_template" {
  source = "../../modules/launch_templates"

  name          = "lauch-aws-labs-nacl"
  description   = "Launch template básico para servidores web"
  image_id      = "ami-0150ccaf51ab55a51"
  instance_type = "t2.micro"
  key_name      = module.key_pair_dev.key_name

  # vpc_security_group_ids = [module.ec2_instances.security_group_id]

  # user_data = <<-EOF
  #   #!/bin/bash
  #   yum update -y
  #   yum install -y httpd
  #   systemctl start httpd
  #   systemctl enable httpd
  # EOF

  user_data = <<-EOF
              #!/bin/bash
              # Actualizar repositorios e instalar nginx
              dnf update -y
              dnf install -y nginx

              # Iniciar y habilitar el servicio nginx
              systemctl enable nginx
              systemctl start nginx
              EOF

  tags = var.vpc_custom_tags
}

# # ==============================================================================
# # EJEMPLO 2: Launch Template con Disco EBS Personalizado
# # ==============================================================================
# module "storage_optimized_template" {
#   source = "../../modules/launch_templates"

#   name          = "storage-optimized-instance"
#   description   = "Template con configuración avanzada de almacenamiento"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "m5.large"
#   ebs_optimized = true

#   vpc_security_group_ids = ["sg-12345678"]

#   block_device_mappings = [
#     {
#       device_name = "/dev/xvda"
#       ebs = {
#         volume_size           = 100
#         volume_type           = "gp3"
#         iops                  = 3000
#         throughput            = 125
#         delete_on_termination = true
#         encrypted             = true
#         kms_key_id            = "arn:aws:kms:us-east-1:123456789012:key/abc123"
#       }
#     },
#     {
#       device_name = "/dev/sdb"
#       ebs = {
#         volume_size           = 500
#         volume_type           = "io2"
#         iops                  = 10000
#         delete_on_termination = false
#         encrypted             = true
#       }
#     }
#   ]

#   tags = {
#     Environment = "production"
#     Type        = "database"
#   }
# }

# # ==============================================================================
# # EJEMPLO 3: Launch Template para Instancias Spot
# # ==============================================================================
# module "spot_instance_template" {
#   source = "../../modules/launch_templates"

#   name          = "spot-batch-processing"
#   description   = "Template para instancias Spot de procesamiento batch"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "c5.2xlarge"

#   vpc_security_group_ids = ["sg-12345678"]

#   instance_market_options = {
#     market_type = "spot"
#     spot_options = {
#       max_price                      = "0.50"
#       spot_instance_type             = "one-time"
#       instance_interruption_behavior = "terminate"
#     }
#   }

#   user_data = file("${path.module}/scripts/batch-processing-startup.sh")

#   tags = {
#     Environment = "production"
#     Workload    = "batch"
#   }
# }

# # ==============================================================================
# # EJEMPLO 4: Launch Template con Network Interface Personalizada
# # ==============================================================================
# module "network_customized_template" {
#   source = "../../modules/launch_templates"

#   name          = "multi-nic-instance"
#   description   = "Template con múltiples interfaces de red"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "c5.xlarge"

#   # No usar vpc_security_group_ids cuando se definen network_interfaces
#   network_interfaces = [
#     {
#       device_index                = 0
#       associate_public_ip_address = true
#       delete_on_termination       = true
#       subnet_id                   = "subnet-12345678"
#       security_groups             = ["sg-web-12345"]
#     },
#     {
#       device_index          = 1
#       delete_on_termination = true
#       subnet_id             = "subnet-87654321"
#       security_groups       = ["sg-backend-67890"]
#     }
#   ]

#   tags = {
#     Environment = "production"
#     Network     = "multi-nic"
#   }
# }

# # ==============================================================================
# # EJEMPLO 5: Launch Template con IMDSv2 y Opciones de Seguridad
# # ==============================================================================
# module "secure_template" {
#   source = "../../modules/launch_templates"

#   name          = "secure-instance"
#   description   = "Template con configuración de seguridad reforzada"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.medium"

#   vpc_security_group_ids = ["sg-12345678"]

#   disable_api_termination              = true
#   instance_initiated_shutdown_behavior = "stop"

#   metadata_options = {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required" # IMDSv2 obligatorio
#     http_put_response_hop_limit = 1
#     instance_metadata_tags      = "enabled"
#   }

#   enclave_options = {
#     enabled = true
#   }

#   ebs_optimized = true

#   block_device_mappings = [
#     {
#       device_name = "/dev/xvda"
#       ebs = {
#         volume_size           = 50
#         volume_type           = "gp3"
#         encrypted             = true
#         delete_on_termination = true
#       }
#     }
#   ]

#   tags = {
#     Environment = "production"
#     Security    = "high"
#     Compliance  = "pci-dss"
#   }
# }

# # ==============================================================================
# # EJEMPLO 6: Launch Template para Auto Scaling Group
# # ==============================================================================
# module "asg_launch_template" {
#   source = "../../modules/launch_templates"

#   name          = "asg-web-application"
#   description   = "Template para Auto Scaling Group de aplicación web"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.medium"

#   iam_instance_profile_name = "web-app-instance-profile"

#   vpc_security_group_ids = ["sg-web-app-12345"]

#   enable_monitoring = true
#   ebs_optimized     = true

#   user_data = templatefile("${path.module}/templates/web-app-init.tpl", {
#     environment = "production"
#     region      = "us-east-1"
#   })

#   block_device_mappings = [
#     {
#       device_name = "/dev/xvda"
#       ebs = {
#         volume_size           = 30
#         volume_type           = "gp3"
#         iops                  = 3000
#         throughput            = 125
#         encrypted             = true
#         delete_on_termination = true
#       }
#     }
#   ]

#   tag_specifications = [
#     {
#       resource_type = "instance"
#       tags = {
#         Name        = "web-app-asg-instance"
#         Environment = "production"
#         Application = "web-app"
#         ManagedBy   = "asg"
#       }
#     },
#     {
#       resource_type = "volume"
#       tags = {
#         Name        = "web-app-asg-volume"
#         Environment = "production"
#         ManagedBy   = "asg"
#       }
#     }
#   ]

#   tags = {
#     Environment = "production"
#     Application = "web-app"
#     ManagedBy   = "terraform"
#   }
# }

# # ==============================================================================
# # EJEMPLO 7: Launch Template con CPU Credits (T3 Unlimited)
# # ==============================================================================
# module "cpu_optimized_template" {
#   source = "../../modules/launch_templates"

#   name          = "t3-unlimited-instance"
#   description   = "Template con CPU credits unlimited para T3"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.large"

#   vpc_security_group_ids = ["sg-12345678"]

#   credit_specification = {
#     cpu_credits = "unlimited"
#   }

#   cpu_options = {
#     core_count       = 1
#     threads_per_core = 2
#   }

#   tags = {
#     Environment = "production"
#     Type        = "compute"
#   }
# }

# # ==============================================================================
# # EJEMPLO 8: Launch Template con Placement Group
# # ==============================================================================
# module "hpc_template" {
#   source = "../../modules/launch_templates"

#   name          = "hpc-cluster-node"
#   description   = "Template para nodos de cluster HPC"
#   image_id      = "ami-0c55b159cbfafe1f0"
#   instance_type = "c5n.18xlarge"

#   vpc_security_group_ids = ["sg-hpc-12345"]

#   placement = {
#     group_name = "hpc-placement-group"
#     tenancy    = "default"
#   }

#   ebs_optimized = true

#   network_interfaces = [
#     {
#       device_index                = 0
#       associate_public_ip_address = false
#       delete_on_termination       = true
#       subnet_id                   = "subnet-private-12345"
#       security_groups             = ["sg-hpc-12345"]
#     }
#   ]

#   tags = {
#     Environment = "production"
#     Workload    = "hpc"
#   }
# }

# # ==============================================================================
# # EJEMPLO 9: Uso del Output del Módulo
# # ==============================================================================
# resource "aws_autoscaling_group" "example" {
#   name                = "example-asg"
#   min_size            = 1
#   max_size            = 5
#   desired_capacity    = 2
#   vpc_zone_identifier = ["subnet-12345678", "subnet-87654321"]

#   launch_template {
#     id      = module.asg_launch_template.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Name"
#     value               = "example-asg-instance"
#     propagate_at_launch = true
#   }
# }

# # ==============================================================================
# # EJEMPLO 10: Launch Template Mínimo (Solo Requeridos)
# # ==============================================================================
# module "minimal_template" {
#   source = "../../modules/launch_templates"

#   name     = "minimal-template"
#   image_id = "ami-0c55b159cbfafe1f0"

#   # Todos los demás valores tomarán sus defaults
# }

# # ==============================================================================
# # OUTPUTS PARA USAR EN OTROS RECURSOS
# # ==============================================================================
# output "launch_template_id" {
#   description = "ID del Launch Template creado"
#   value       = module.asg_launch_template.id
# }

# output "launch_template_arn" {
#   description = "ARN del Launch Template creado"
#   value       = module.asg_launch_template.arn
# }

# output "launch_template_latest_version" {
#   description = "Última versión del Launch Template"
#   value       = module.asg_launch_template.latest_version
# }
