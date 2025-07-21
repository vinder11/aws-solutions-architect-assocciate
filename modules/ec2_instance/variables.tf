
# variables.tf
# Añadido al inicio del archivo
variable "module_enabled" {
  description = "Habilita o deshabilita la creación de recursos en este módulo"
  type        = bool
  default     = true
}

variable "create_ec2_instance" {
  description = "Controla si se crea la instancia EC2"
  type        = bool
  default     = true
}

# Añadido para soportar launch templates
variable "launch_template_version" {
  description = "Versión del launch template a usar"
  type        = string
  default     = "$Latest"
}

# Añadido para soportar capacity reservations
variable "capacity_reservation_specification" {
  description = "Configuración de capacity reservation"
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_id                 = optional(string)
      capacity_reservation_resource_group_arn = optional(string)
    }))
  })
  default = null
}

# Añadido para soportar maintenance options
variable "maintenance_options" {
  description = "Opciones de mantenimiento de la instancia"
  type = object({
    auto_recovery = optional(string, "default")
  })
  default = {}
}
# Variables de configuración general
variable "name" {
  description = "Nombre base para los recursos"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "El nombre debe contener solo letras, números y guiones."
  }
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  default     = "dev"
  # validation {
  #   condition     = contains(["dev", "staging", "prod"], var.environment)
  #   error_message = "El ambiente debe ser: dev, staging, o prod."
  # }
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = ""
}

# Configuración básica de la instancia
variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
  validation {
    condition     = can(regex("^[a-z][0-9]+(n|a|d)?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "Tipo de instancia inválido."
  }
}

variable "ami_id" {
  description = "ID de la AMI a usar"
  type        = string
  default     = null
}

variable "ami_filter" {
  description = "Filtros para buscar AMI automáticamente"
  type = object({
    name         = optional(string, "amzn2-ami-hvm-*")
    owners       = optional(list(string), ["amazon"])
    architecture = optional(string, "x86_64")
    state        = optional(string, "available")
  })
  default = {}
}

variable "key_name" {
  description = "Nombre del key pair para acceso SSH"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ID de la VPC donde crear la instancia"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde crear la instancia"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Lista de subnet IDs para múltiples instancias"
  type        = list(string)
  default     = []
}

variable "instance_count" {
  description = "Número de instancias a crear"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 20
    error_message = "El número de instancias debe estar entre 1 y 20."
  }
}

# Configuración de red
variable "associate_public_ip_address" {
  description = "Asociar IP pública a la instancia"
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "IP privada específica para la instancia"
  type        = string
  default     = null
}

variable "secondary_private_ips" {
  description = "IPs privadas secundarias"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Lista de security groups existentes"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Crear security group automáticamente"
  type        = bool
  default     = true
}

variable "security_group_rules" {
  description = "Reglas del security group"
  type = map(object({
    type                     = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string))
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = {
    ssh = {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    }
    egress = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All outbound traffic"
    }
  }
}

# Configuración de almacenamiento
variable "root_block_device" {
  description = "Configuración del dispositivo de bloque raíz"
  type = object({
    volume_type           = optional(string, "gp3")
    volume_size           = optional(number, 20)
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool, true)
    tags                  = optional(map(string), {})
  })
  default = {}
}

variable "ebs_block_device" {
  description = "Dispositivos EBS adicionales"
  type = list(object({
    device_name           = string
    volume_type           = optional(string, "gp3")
    volume_size           = number
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool, true)
    kms_key_id            = optional(string)
    snapshot_id           = optional(string)
    delete_on_termination = optional(bool, true)
    tags                  = optional(map(string), {})
  }))
  default = []
}

variable "ephemeral_block_device" {
  description = "Dispositivos efímeros"
  type = list(object({
    device_name  = string
    virtual_name = string
  }))
  default = []
}

# Configuración de IAM
variable "iam_instance_profile" {
  description = "Nombre del instance profile IAM"
  type        = string
  default     = null
}

variable "create_iam_instance_profile" {
  description = "Crear instance profile IAM automáticamente"
  type        = bool
  default     = false
}

variable "iam_role_policies" {
  description = "Políticas IAM para adjuntar al role"
  type        = list(string)
  default     = []
}

variable "iam_role_policy_arns" {
  description = "ARNs de políticas IAM managed"
  type        = list(string)
  default     = []
}

# Configuración avanzada
variable "user_data" {
  description = "Script user data para la instancia"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Script user data en base64"
  type        = string
  default     = null
}

variable "user_data_replace_on_change" {
  description = "Reemplazar instancia cuando cambie user_data"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone específica"
  type        = string
  default     = null
}

variable "placement_group" {
  description = "Nombre del placement group"
  type        = string
  default     = null
}

variable "placement_partition_number" {
  description = "Número de partición del placement group"
  type        = number
  default     = null
}

variable "tenancy" {
  description = "Tenancy de la instancia"
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "Tenancy debe ser: default, dedicated, o host."
  }
}

variable "host_id" {
  description = "ID del Dedicated Host"
  type        = string
  default     = null
}

variable "cpu_credits" {
  description = "Opción de CPU credits para instancias burstable"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "CPU credits debe ser: standard o unlimited."
  }
}

variable "disable_api_termination" {
  description = "Deshabilitar terminación via API"
  type        = bool
  default     = false
}

variable "disable_api_stop" {
  description = "Deshabilitar stop via API"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Comportamiento al hacer shutdown desde la instancia"
  type        = string
  default     = "stop"
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "Debe ser: stop o terminate."
  }
}

variable "monitoring" {
  description = "Habilitar monitoreo detallado"
  type        = bool
  default     = false
}

variable "get_password_data" {
  description = "Obtener datos de password para instancias Windows"
  type        = bool
  default     = false
}

variable "hibernation" {
  description = "Habilitar hibernación"
  type        = bool
  default     = false
}

variable "cpu_core_count" {
  description = "Número de CPU cores"
  type        = number
  default     = null
}

variable "cpu_threads_per_core" {
  description = "Número de threads por CPU core"
  type        = number
  default     = null
}

variable "ebs_optimized" {
  description = "Optimizar para EBS"
  type        = bool
  default     = null
}

variable "source_dest_check" {
  description = "Verificación source/destination"
  type        = bool
  default     = true
}

# Configuración de red avanzada
variable "ipv6_address_count" {
  description = "Número de direcciones IPv6"
  type        = number
  default     = null
}

variable "ipv6_addresses" {
  description = "Lista de direcciones IPv6"
  type        = list(string)
  default     = []
}

# Modificado el bloque de metadata_options para mayor precisión
variable "metadata_options" {
  description = "Opciones de metadatos de la instancia"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 2)
    instance_metadata_tags      = optional(string, "disabled")
  })
  default = {}
}

# Configuración de red mejorada
variable "ena_support" {
  description = "Habilitar Enhanced Networking"
  type        = bool
  default     = null
}

variable "sriov_net_support" {
  description = "Habilitar SR-IOV"
  type        = string
  default     = null
}

# Configuración de enclave
variable "enclave_options" {
  description = "Opciones de Nitro Enclave"
  type = object({
    enabled = optional(bool, false)
  })
  default = {}
}

# Configuración de instancia spot
variable "spot_price" {
  description = "Precio máximo para instancia spot"
  type        = string
  default     = null
}

variable "spot_type" {
  description = "Tipo de request spot"
  type        = string
  default     = "one-time"
  validation {
    condition     = contains(["one-time", "persistent"], var.spot_type)
    error_message = "Spot type debe ser: one-time o persistent."
  }
}

variable "spot_valid_from" {
  description = "Fecha de inicio válida para spot request"
  type        = string
  default     = null
}

variable "spot_valid_until" {
  description = "Fecha de fin válida para spot request"
  type        = string
  default     = null
}

variable "spot_launch_group" {
  description = "Launch group para spot instances"
  type        = string
  default     = null
}

variable "spot_instance_interruption_behavior" {
  description = "Comportamiento al interrumpir spot instance"
  type        = string
  default     = "terminate"
  validation {
    condition     = contains(["hibernate", "stop", "terminate"], var.spot_instance_interruption_behavior)
    error_message = "Debe ser: hibernate, stop, o terminate."
  }
}

# Tags
variable "tags" {
  description = "Tags para aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "Tags adicionales para volúmenes"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Tags adicionales para instancias"
  type        = map(string)
  default     = {}
}

# Configuración de backup
variable "backup_enabled" {
  description = "Habilitar backup automático"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Días de retención de backup"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days > 0 && var.backup_retention_days <= 365
    error_message = "Retención debe estar entre 1 y 365 días."
  }
}

variable "backup_schedule" {
  description = "Expresión cron para backup"
  type        = string
  default     = "cron(0 2 * * ? *)"
}
