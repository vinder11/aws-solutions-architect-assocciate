# ============================================
# VARIABLES
# ============================================

variable "ebs_volumes" {
  description = "Mapa de volúmenes EBS a crear"
  type = map(object({
    availability_zone = string
    size              = number
    type              = optional(string, "gp3")
    iops              = optional(number)
    throughput        = optional(number)
    encrypted         = optional(bool, true)
    kms_key_id        = optional(string)
    snapshot_id       = optional(string)
    outpost_arn       = optional(string)
    multi_attach      = optional(bool, false)
    final_snapshot    = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.ebs_volumes : contains(
        ["gp2", "gp3", "io1", "io2", "sc1", "st1", "standard"],
        v.type
      )
    ])
    error_message = "El tipo de volumen debe ser: gp2, gp3, io1, io2, sc1, st1 o standard."
  }

  validation {
    condition = alltrue([
      for k, v in var.ebs_volumes : v.size >= 1 && v.size <= 16384
    ])
    error_message = "El tamaño del volumen debe estar entre 1 GB y 16384 GB (16 TB)."
  }

  validation {
    condition = alltrue([
      for k, v in var.ebs_volumes :
      v.iops == null || (
        (v.type == "gp3" && v.iops >= 3000 && v.iops <= 16000) ||
        (v.type == "io1" && v.iops >= 100 && v.iops <= 64000) ||
        (v.type == "io2" && v.iops >= 100 && v.iops <= 64000)
      )
    ])
    error_message = "IOPS debe estar en el rango válido según el tipo de volumen."
  }

  validation {
    condition = alltrue([
      for k, v in var.ebs_volumes :
      v.throughput == null || (v.type == "gp3" && v.throughput >= 125 && v.throughput <= 1000)
    ])
    error_message = "Throughput solo es válido para gp3 y debe estar entre 125-1000 MB/s."
  }
}

variable "attachment_config" {
  description = "Configuración para adjuntar volúmenes a instancias EC2"
  type = map(object({
    volume_key                     = string
    instance_id                    = string
    device_name                    = string
    force_detach                   = optional(bool, false)
    skip_destroy                   = optional(bool, false)
    stop_instance_before_detaching = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.attachment_config :
      can(regex("^/dev/(sd[a-z]|xvd[a-z])$", v.device_name))
    ])
    error_message = "device_name debe tener formato /dev/sd[a-z] o /dev/xvd[a-z]."
  }
}

variable "default_tags" {
  description = "Tags por defecto para todos los volúmenes"
  type        = map(string)
  default     = {}
}

variable "enable_volume_snapshots" {
  description = "Habilitar creación de snapshots automáticos"
  type        = bool
  default     = false
}

variable "snapshot_schedule" {
  description = "Configuración de snapshots programados"
  type = object({
    name          = optional(string, "ebs-snapshot-schedule")
    description   = optional(string, "Automated EBS snapshots")
    interval      = optional(number, 24)
    interval_unit = optional(string, "hours")
    times         = optional(list(string), ["03:00"])
    retain_count  = optional(number, 7)
    tags          = optional(map(string), {})
  })
  default = {
    name = "ebs-snapshot-schedule"
  }

  validation {
    condition     = contains(["hours"], var.snapshot_schedule.interval_unit)
    error_message = "interval_unit debe ser 'hours'."
  }
}
