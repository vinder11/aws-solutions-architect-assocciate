# Configuración Básica (Entorno Dev)
module "ec2_instances" {
  source = "../../modules/ec2_instance"

  name                        = "aws-labs-nacl" # el modulo mejora el nombre
  environment                 = var.environment_name
  instance_type               = "t2.micro"
  iam_role_existing_name      = module.ec2_role.role_name # Perfil IAM para la instancia
  create_iam_instance_profile = true                      # Crear perfil IAM para la instancia

  # ami_filter = {
  #   name         = "al2023-ami-kernel-6.1-*"
  #   owners       = ["amazon"]
  #   architecture = "x86_64"
  # }
  ami_id                      = "ami-0150ccaf51ab55a51"      # AMI de Amazon Linux 2 en us-east-1
  key_name                    = module.key_pair_dev.key_name # Nombre del Key Pair creado
  associate_public_ip_address = true                         # Asociar IP pública para acceso directo

  # Configuración de red
  vpc_id    = module.vpc.vpc_id
  subnet_id = module.subnets.public_subnet_ids[0] # Subred pública por defecto

  # Seguridad básica
  security_group_rules = {
    ssh = {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["181.188.150.66/32"] # Solo acceso desde la VPC
      # cidr_blocks = ["181.188.150.66/32"] # Solo acceso desde la VPC
    },
    http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["181.188.150.66/32"] # Solo acceso desde la VPC
    },
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Almacenamiento
  root_block_device = {
    volume_size = 20
    volume_type = "gp3" # Tipo de volumen SSD general
    encrypted   = true
  }

  # User Data para configurar drivers y entorno
  user_data = <<-EOF
              #!/bin/bash
              # Actualizar repositorios e instalar nginx
              dnf update -y
              dnf install -y nginx

              # Iniciar y habilitar el servicio nginx
              systemctl enable nginx
              systemctl start nginx
              EOF

  # user_data_base64 = base64encode(<<-EOF
  # 						#!/bin/bash
  # 						yum update -y
  # 						yum install -y httpd
  # 						systemctl start httpd
  # 						systemctl enable httpd
  # 						echo "¡Hola desde EC2!" > /var/www/html/index.html
  # 						EOF
  # )

  tags = var.vpc_custom_tags
}

##### Configuración Media (Entorno Staging con Alta Disponibilidad) #####
# module "staging_app_servers" {
#   source = "../../modules/ec2_instance"

#   name           = "app-staging"
#   environment    = "staging"
#   project        = "ecommerce"
#   instance_type  = "t3.medium"
#   instance_count = 2 # Multi-AZ

#   # Configuración de AMI
#   ami_filter = {
#     name         = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
#     owners       = ["amazon"]
#     architecture = "x86_64"
#   }

#   # Red avanzada
#   vpc_id                      = "vpc-12345678"
#   subnet_ids                  = ["subnet-1a2b3c4d", "subnet-5e6f7g8h"] # Multi-AZ
#   associate_public_ip_address = false

#   # Seguridad mejorada
#   security_group_rules = {
#     http_internal = {
#       type        = "ingress"
#       from_port   = 8080
#       to_port     = 8080
#       protocol    = "tcp"
#       cidr_blocks = ["10.0.0.0/16"]
#     },
#     ssh_bastion = {
#       type                     = "ingress"
#       from_port                = 22
#       to_port                  = 22
#       protocol                 = "tcp"
#       source_security_group_id = "sg-bastion-host"
#     },
#     egress_all = {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   # Almacenamiento
#   root_block_device = {
#     volume_type = "gp3"
#     volume_size = 30
#     throughput  = 150
#     encrypted   = true
#   }

#   ebs_block_device = [{
#     device_name = "/dev/sdf"
#     volume_size = 50
#     volume_type = "gp3"
#     encrypted   = true
#   }]

#   # IAM
#   create_iam_instance_profile = true
#   iam_role_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   ]

#   # User Data para configuración inicial
#   user_data = <<-EOF
#               #!/bin/bash
#               yum install -y docker
#               systemctl start docker
#               systemctl enable docker
#               EOF

#   # Monitoreo
#   monitoring = true

#   tags = {
#     Component = "application"
#     Team      = "devops"
#   }
# }

##### Configuración Avanzada (Producción Crítica) #####
# module "prod_database_servers" {
#   source = "../../modules/ec2_instance"

#   name           = "db-prod"
#   environment    = "prod"
#   project        = "financial-system"
#   instance_type  = "r5.2xlarge"
#   instance_count = 3

#   # AMI personalizada
#   ami_id = "ami-0123456789abcdef0"

#   # Configuración de red avanzada
#   vpc_id                = "vpc-financial-prod"
#   subnet_ids            = ["subnet-db1", "subnet-db2", "subnet-db3"] # Multi-AZ
#   private_ip            = "10.0.100.10"                              # IP fija para la primera instancia
#   secondary_private_ips = ["10.0.100.11", "10.0.100.12"]

#   # Placement avanzado
#   placement_group            = "db-placement-group"
#   placement_partition_number = 1
#   tenancy                    = "dedicated"

#   # Seguridad estricta
#   security_group_rules = {
#     db_port = {
#       type                     = "ingress"
#       from_port                = 5432
#       to_port                  = 5432
#       protocol                 = "tcp"
#       source_security_group_id = "sg-app-servers"
#     },
#     ssh_bastion = {
#       type                     = "ingress"
#       from_port                = 22
#       to_port                  = 22
#       protocol                 = "tcp"
#       source_security_group_id = "sg-bastion-host"
#     },
#     egress_restricted = {
#       type        = "egress"
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   # Almacenamiento de alto rendimiento
#   root_block_device = {
#     volume_type = "io1"
#     volume_size = 100
#     iops        = 5000
#     encrypted   = true
#     kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/db-encryption-key"
#   }

#   ebs_block_device = [
#     {
#       device_name = "/dev/sdf"
#       volume_type = "io1"
#       volume_size = 500
#       iops        = 10000
#       encrypted   = true
#     },
#     {
#       device_name = "/dev/sdg"
#       volume_type = "st1"
#       volume_size = 2000
#       encrypted   = true
#     }
#   ]

#   # IAM avanzado
#   create_iam_instance_profile = true
#   iam_role_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#     "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
#   ]
#   iam_role_policies = [
#     "kms:Decrypt,kms:Encrypt",
#     "secretsmanager:GetSecretValue"
#   ]

#   # Configuración de instancia avanzada
#   disable_api_termination = true
#   metadata_options = {
#     http_tokens                 = "required" # IMDSv2 obligatorio
#     http_put_response_hop_limit = 1
#   }

#   cpu_credits   = "unlimited"
#   ebs_optimized = true

#   # Backups automatizados
#   backup_enabled        = true
#   backup_retention_days = 35
#   backup_schedule       = "cron(0 1 * * ? *)" # Diario a la 1 AM

#   # Configuración de mantenimiento
#   maintenance_options = {
#     auto_recovery = "default"
#   }

#   tags = {
#     Component    = "database"
#     Critical     = "true"
#     Compliance   = "pci-dss"
#     BackupPolicy = "daily"
#   }
# }

##### Configuración para Spot Instances (Carga de Trabajo Flexible) #####
# module "batch_processing_workers" {
#   source = "../../modules/ec2_instance"

#   name           = "batch-worker"
#   environment    = "prod"
#   project        = "data-processing"
#   instance_type  = "m5.2xlarge"
#   instance_count = 10

#   # Configuración Spot
#   spot_price                          = "0.05" # Precio máximo por hora
#   spot_type                           = "persistent"
#   spot_instance_interruption_behavior = "stop"

#   # Optimización de costos
#   cpu_credits = "unlimited"

#   # Configuración de red
#   vpc_id     = "vpc-data-processing"
#   subnet_ids = ["subnet-data1", "subnet-data2", "subnet-data3"]

#   # Seguridad
#   security_group_rules = {
#     worker_api = {
#       type                     = "ingress"
#       from_port                = 8080
#       to_port                  = 8080
#       protocol                 = "tcp"
#       source_security_group_id = "sg-control-plane"
#     },
#     egress_all = {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   # Almacenamiento efímero
#   root_block_device = {
#     volume_size = 30
#     encrypted   = true
#   }

#   ephemeral_block_device = [{
#     device_name  = "/dev/sdb"
#     virtual_name = "ephemeral0"
#   }]

#   # IAM para acceso a S3
#   create_iam_instance_profile = true
#   iam_role_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonS3FullAccess"
#   ]

#   # User Data para unirse al cluster
#   user_data_base64 = base64encode(<<-EOF
#                 #!/bin/bash
#                 ./join-cluster.sh --token ${var.cluster_token}
#                 EOF
#   )

#   tags = {
#     Component  = "batch-processing"
#     WorkerType = "spot"
#   }
# }

##### Configuración para Windows Server (Enterprise) #####
# module "windows_ad_server" {
#   source = "../../modules/ec2_instance"

#   name          = "ad-primary"
#   environment   = "prod"
#   project       = "enterprise-it"
#   instance_type = "m5.large"

#   # AMI Windows Server 2019
#   ami_filter = {
#     name         = "Windows_Server-2019-English-Full-Base-*"
#     owners       = ["amazon"]
#     architecture = "x86_64"
#   }

#   # Configuración de red
#   vpc_id     = "vpc-enterprise"
#   subnet_id  = "subnet-ad-services"
#   private_ip = "10.10.100.10"

#   # Seguridad para AD
#   security_group_rules = {
#     rdp = {
#       type        = "ingress"
#       from_port   = 3389
#       to_port     = 3389
#       protocol    = "tcp"
#       cidr_blocks = ["10.10.0.0/16"]
#     },
#     ad_ports = {
#       type        = "ingress"
#       from_port   = 88
#       to_port     = 88
#       protocol    = "tcp"
#       cidr_blocks = ["10.10.0.0/16"]
#     },
#     egress_all = {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   # Almacenamiento para AD
#   root_block_device = {
#     volume_size = 100
#     volume_type = "gp3"
#     encrypted   = true
#   }

#   ebs_block_device = [{
#     device_name = "/dev/sdf"
#     volume_size = 50
#     volume_type = "gp3"
#     encrypted   = true
#   }]

#   # IAM para integración con AWS
#   create_iam_instance_profile = true
#   iam_role_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#     "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
#   ]

#   # Configuración específica de Windows
#   get_password_data = true
#   metadata_options = {
#     http_tokens   = "required"
#     http_endpoint = "enabled"
#   }

#   # Backups diarios
#   backup_enabled        = true
#   backup_retention_days = 14

#   tags = {
#     Component = "active-directory"
#     Role      = "domain-controller"
#   }
# }

# # Recurso adicional para la configuración de licencias
# resource "aws_licensemanager_association" "windows_license" {
#   resource_arn              = module.windows_ad_server.instance_arns[0]
#   license_configuration_arn = "arn:aws:license-manager:us-east-1:123456789012:license-configuration/win-lic-config"
# }

# Si prefieres especificar la licencia directamente en la AMI (sin License Manager), puedes usar:
# En el data source de la AMI, busca AMIs con licencia incluida
# data "aws_ami" "windows" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["Windows_Server-2019-English-Full-Base-*"]
#   }

#   filter {
#     name   = "platform"
#     values = ["windows"]
#   }

#   filter {
#     name   = "license-included"
#     values = ["true"] # Busca AMIs con licencia incluida
#   }
# }

##### Configuración para GPU (Machine Learning) #####
# module "ml_training_instance" {
#   source = "../../modules/ec2_instance"

#   name          = "ml-training"
#   environment   = "prod"
#   project       = "ai-platform"
#   instance_type = "p3.2xlarge" # Instancia con GPU NVIDIA

#   # AMI con drivers de GPU preinstalados
#   ami_id = "ami-0abcdef1234567890"

#   # Configuración de red
#   vpc_id    = "vpc-ml-services"
#   subnet_id = "subnet-ml-zone"

#   # Seguridad
#   security_group_rules = {
#     jupyter = {
#       type        = "ingress"
#       from_port   = 8888
#       to_port     = 8888
#       protocol    = "tcp"
#       cidr_blocks = ["10.20.0.0/16"]
#     },
#     ssh = {
#       type        = "ingress"
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["10.20.1.0/24"]
#     },
#     egress_all = {
#       type        = "egress"
#       from_port   = 0
#       to_port     = 0
#       protocol    = "-1"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   # Almacenamiento de alto rendimiento
#   root_block_device = {
#     volume_size = 100
#     volume_type = "gp3"
#     throughput  = 250
#     encrypted   = true
#   }

#   ebs_block_device = [{
#     device_name = "/dev/sdf"
#     volume_size = 500
#     volume_type = "io1"
#     iops        = 5000
#     encrypted   = true
#   }]

#   # Configuración avanzada de GPU
#   enclave_options = {
#     enabled = false
#   }

#   # IAM para acceso a datos
#   create_iam_instance_profile = true
#   iam_role_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
#     "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
#   ]

#   # User Data para configurar drivers y entorno
#   user_data = <<-EOF
#               #!/bin/bash
#               nvidia-smi -pm 1
#               docker pull tensorflow/tensorflow:latest-gpu
#               EOF

#   # Optimización
#   ebs_optimized = true
#   monitoring    = true

#   tags = {
#     Component = "machine-learning"
#     Task      = "model-training"
#   }
# }
