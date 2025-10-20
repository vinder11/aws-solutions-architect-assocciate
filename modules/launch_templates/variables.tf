# variables.tf
variable "name" {
  description = "Nombre del Launch Template"
  type        = string
}

variable "description" {
  description = "Descripción del Launch Template"
  type        = string
  default     = ""
}

variable "image_id" {
  description = "ID de la AMI a utilizar"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair para SSH"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Lista de IDs de security groups"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "Nombre del IAM instance profile"
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "ARN del IAM instance profile"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Script de user data (base64 encoded automáticamente)"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Script de user data ya codificado en base64"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Habilitar monitoring detallado"
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "Habilitar EBS optimized"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Deshabilitar terminación vía API"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Comportamiento al hacer shutdown (stop o terminate)"
  type        = string
  default     = "stop"
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "El valor debe ser 'stop' o 'terminate'."
  }
}

variable "network_interfaces" {
  description = "Configuración de interfaces de red"
  type = list(object({
    associate_public_ip_address = optional(bool)
    delete_on_termination       = optional(bool, true)
    device_index                = number
    subnet_id                   = optional(string)
    security_groups             = optional(list(string))
    ipv4_address_count          = optional(number)
    ipv4_addresses              = optional(list(string))
  }))
  default = []
}

variable "block_device_mappings" {
  description = "Configuración de dispositivos de bloques"
  type = list(object({
    device_name  = string
    no_device    = optional(string)
    virtual_name = optional(string)
    ebs = optional(object({
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, true)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      volume_size           = optional(number)
      volume_type           = optional(string, "gp3")
      throughput            = optional(number)
    }))
  }))
  default = []
}

variable "capacity_reservation_specification" {
  description = "Especificación de reserva de capacidad"
  type = object({
    capacity_reservation_preference = optional(string)
    capacity_reservation_target = optional(object({
      capacity_reservation_id = optional(string)
    }))
  })
  default = null
}

variable "cpu_options" {
  description = "Opciones de CPU"
  type = object({
    core_count       = optional(number)
    threads_per_core = optional(number)
  })
  default = null
}

variable "credit_specification" {
  description = "Especificación de créditos para instancias T2/T3"
  type = object({
    cpu_credits = string
  })
  default = { cpu_credits = "standard" }
  validation {
    condition = var.credit_specification == null || (
      var.credit_specification != null &&
      contains(["standard", "unlimited"], var.credit_specification.cpu_credits)
    )
    error_message = "cpu_credits debe ser 'standard' o 'unlimited'."
  }
}

variable "elastic_gpu_specifications" {
  description = "Especificaciones de Elastic GPU"
  type = list(object({
    type = string
  }))
  default = []
}

variable "elastic_inference_accelerator" {
  description = "Acelerador de Elastic Inference"
  type = object({
    type = string
  })
  default = null
}

variable "enclave_options" {
  description = "Opciones de Nitro Enclaves"
  type = object({
    enabled = bool
  })
  default = null
}

variable "hibernation_options" {
  description = "Opciones de hibernación"
  type = object({
    configured = bool
  })
  default = null
}

variable "instance_market_options" {
  description = "Opciones de mercado de instancias (Spot)"
  type = object({
    market_type = string
    spot_options = optional(object({
      block_duration_minutes         = optional(number)
      instance_interruption_behavior = optional(string)
      max_price                      = optional(string)
      spot_instance_type             = optional(string)
      valid_until                    = optional(string)
    }))
  })
  default = null
}

variable "license_specifications" {
  description = "Especificaciones de licencias"
  type = list(object({
    license_configuration_arn = string
  }))
  default = []
}

variable "metadata_options" {
  description = "Opciones de metadata service"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    http_protocol_ipv6          = optional(string)
    instance_metadata_tags      = optional(string)
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

variable "placement" {
  description = "Configuración de placement"
  type = object({
    affinity                = optional(string)
    availability_zone       = optional(string)
    group_name              = optional(string)
    host_id                 = optional(string)
    host_resource_group_arn = optional(string)
    partition_number        = optional(number)
    spread_domain           = optional(string)
    tenancy                 = optional(string)
  })
  default = null
}

variable "private_dns_name_options" {
  description = "Opciones de nombre DNS privado"
  type = object({
    enable_resource_name_dns_aaaa_record = optional(bool)
    enable_resource_name_dns_a_record    = optional(bool)
    hostname_type                        = optional(string)
  })
  default = null
}

variable "ram_disk_id" {
  description = "ID del RAM disk"
  type        = string
  default     = null
}

variable "kernel_id" {
  description = "ID del kernel"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags para el Launch Template"
  type        = map(string)
  default     = {}
}

variable "tag_specifications" {
  description = "Tags para recursos creados por el Launch Template"
  type = list(object({
    resource_type = string
    tags          = map(string)
  }))
  default = []
}

variable "update_default_version" {
  description = "Actualizar la versión default al crear nueva versión"
  type        = bool
  default     = true
}
