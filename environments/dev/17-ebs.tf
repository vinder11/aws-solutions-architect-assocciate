# # ============================================
# # EJEMPLO 1: Volúmenes básicos sin attachment
# # ============================================

# module "ebs_basic" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "data-volume-01" = {
#       availability_zone = "us-east-1a"
#       size              = 100
#       type              = "gp3"
#       encrypted         = true
#     }
#     "logs-volume-01" = {
#       availability_zone = "us-east-1a"
#       size              = 50
#       type              = "gp3"
#       encrypted         = true
#       tags = {
#         Purpose = "Logs"
#         Backup  = "daily"
#       }
#     }
#   }

#   default_tags = {
#     Environment = "production"
#     Project     = "myapp"
#     Terraform   = "true"
#   }
# }

# # ============================================
# # EJEMPLO 2: Volúmenes de alto rendimiento (io2)
# # ============================================

# module "ebs_high_performance" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "db-primary-volume" = {
#       availability_zone = "us-east-1a"
#       size              = 500
#       type              = "io2"
#       iops              = 10000
#       encrypted         = true
#       kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/xxx"
#       tags = {
#         Database = "postgresql"
#         Role     = "primary"
#       }
#     }
#     "db-replica-volume" = {
#       availability_zone = "us-east-1b"
#       size              = 500
#       type              = "io2"
#       iops              = 8000
#       encrypted         = true
#       kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/xxx"
#       tags = {
#         Database = "postgresql"
#         Role     = "replica"
#       }
#     }
#   }

#   default_tags = {
#     Environment = "production"
#     Tier        = "database"
#   }
# }

# # ============================================
# # EJEMPLO 3: Volúmenes con attachment a instancias
# # ============================================

# module "ebs_with_attachments" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "app-data-volume" = {
#       availability_zone = "us-east-1a"
#       size              = 200
#       type              = "gp3"
#       iops              = 5000
#       throughput        = 250
#       encrypted         = true
#     }
#     "app-logs-volume" = {
#       availability_zone = "us-east-1a"
#       size              = 100
#       type              = "gp3"
#       encrypted         = true
#     }
#   }

#   attachment_config = {
#     "app-data-attachment" = {
#       volume_key  = "app-data-volume"
#       instance_id = "i-1234567890abcdef0"
#       device_name = "/dev/sdf"
#       force_detach = false
#       skip_destroy = false
#     }
#     "app-logs-attachment" = {
#       volume_key  = "app-logs-volume"
#       instance_id = "i-1234567890abcdef0"
#       device_name = "/dev/sdg"
#       force_detach = false
#       skip_destroy = true
#     }
#   }

#   default_tags = {
#     Environment = "production"
#     Application = "web-app"
#   }
# }

# # ============================================
# # EJEMPLO 4: Volúmenes con snapshots automáticos
# # ============================================

# module "ebs_with_snapshots" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "critical-data" = {
#       availability_zone = "us-east-1a"
#       size              = 1000
#       type              = "gp3"
#       iops              = 8000
#       throughput        = 500
#       encrypted         = true
#       final_snapshot    = true
#       tags = {
#         SnapshotBackup = "true"  # Requerido para DLM
#         CriticalData   = "true"
#       }
#     }
#   }

#   enable_volume_snapshots = true

#   snapshot_schedule = {
#     name         = "critical-data-snapshots"
#     description  = "Daily snapshots of critical data volumes"
#     interval     = 24
#     interval_unit = "hours"
#     times        = ["02:00"]
#     retain_count = 14
#     tags = {
#       BackupType = "automated"
#       Retention  = "14-days"
#     }
#   }

#   default_tags = {
#     Environment = "production"
#     DataClass   = "critical"
#   }
# }

# # ============================================
# # EJEMPLO 5: Volúmenes desde snapshot
# # ============================================

# module "ebs_from_snapshot" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "restored-volume" = {
#       availability_zone = "us-east-1a"
#       snapshot_id       = "snap-0123456789abcdef0"
#       size              = 150  # Puede ser mayor que el snapshot
#       type              = "gp3"
#       encrypted         = true
#       tags = {
#         RestoredFrom = "snap-0123456789abcdef0"
#         Purpose      = "disaster-recovery"
#       }
#     }
#   }

#   default_tags = {
#     Environment = "production"
#     Recovery    = "true"
#   }
# }

# # ============================================
# # EJEMPLO 6: Volúmenes para diferentes ambientes
# # ============================================

# module "ebs_multi_environment" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "dev-app-volume" = {
#       availability_zone = "us-east-1a"
#       size              = 50
#       type              = "gp3"
#       encrypted         = false  # Dev sin encriptación
#       tags = {
#         Environment = "development"
#       }
#     }
#     "staging-app-volume" = {
#       availability_zone = "us-east-1a"
#       size              = 100
#       type              = "gp3"
#       encrypted         = true
#       tags = {
#         Environment = "staging"
#       }
#     }
#     "prod-app-volume" = {
#       availability_zone = "us-east-1a"
#       size              = 500
#       type              = "gp3"
#       iops              = 10000
#       throughput        = 500
#       encrypted         = true
#       kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/xxx"
#       tags = {
#         Environment = "production"
#         SnapshotBackup = "true"
#       }
#     }
#   }

#   enable_volume_snapshots = true

#   snapshot_schedule = {
#     name         = "prod-snapshots"
#     interval     = 24
#     times        = ["03:00"]
#     retain_count = 30
#   }

#   default_tags = {
#     Project   = "myapp"
#     ManagedBy = "terraform"
#   }
# }

# # ============================================
# # EJEMPLO 7: Volúmenes económicos (st1/sc1)
# # ============================================

# module "ebs_economical" {
#   source = "../../modules/ebs"

#   ebs_volumes = {
#     "archive-logs" = {
#       availability_zone = "us-east-1a"
#       size              = 500
#       type              = "sc1"  # Cold HDD - más económico
#       encrypted         = true
#       tags = {
#         Purpose     = "archival"
#         AccessFreq  = "infrequent"
#       }
#     }
#     "big-data-processing" = {
#       availability_zone = "us-east-1a"
#       size              = 1000
#       type              = "st1"  # Throughput Optimized HDD
#       encrypted         = true
#       tags = {
#         Purpose     = "big-data"
#         Workload    = "sequential"
#       }
#     }
#   }

#   default_tags = {
#     Environment = "production"
#     CostCenter  = "analytics"
#   }
# }

# # ============================================
# # OUTPUTS DE EJEMPLO
# # ============================================

# output "volume_ids" {
#   description = "IDs de todos los volúmenes creados"
#   value       = module.ebs_basic.volume_ids
# }

# output "volume_details" {
#   description = "Detalles completos de los volúmenes"
#   value       = module.ebs_basic.volume_details
# }

# output "high_perf_volumes" {
#   description = "Volúmenes de alto rendimiento"
#   value       = module.ebs_high_performance.volume_details
# }

# # ============================================
# # VARIABLES PARA REUTILIZACIÓN
# # ============================================

# variable "availability_zones" {
#   description = "Zonas de disponibilidad a usar"
#   type        = list(string)
#   default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
# }

# variable "environment" {
#   description = "Ambiente de despliegue"
#   type        = string
#   default     = "production"

#   validation {
#     condition     = contains(["development", "staging", "production"], var.environment)
#     error_message = "El ambiente debe ser: development, staging o production."
#   }
# }

# variable "kms_key_arn" {
#   description = "ARN de la llave KMS para encriptación"
#   type        = string
#   default     = ""
# }
