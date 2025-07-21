resource "aws_instance" "this" {
  count = local.is_module_enabled ? var.instance_count : 0 # Número de instancias a crear

  # Configuración básica
  ami           = local.ami_id                                                      # AMI a usar (calculada en locals)
  instance_type = var.instance_type                                                 # Tipo de instancia
  subnet_id     = element(local.subnet_ids, count.index % length(local.subnet_ids)) # Distribuye en subnets disponibles
  key_name      = var.key_name                                                      # Key pair para SSH

  # Configuración de seguridad
  vpc_security_group_ids = local.security_group_ids        # Security groups a asignar
  iam_instance_profile   = local.iam_instance_profile_name # Perfil IAM

  # Configuración de red
  associate_public_ip_address = var.associate_public_ip_address                                            # Si asocia IP pública
  private_ip                  = var.private_ip != null ? (count.index == 0 ? var.private_ip : null) : null # IP privada específica solo para la primera instancia
  secondary_private_ips       = count.index == 0 ? var.secondary_private_ips : null                        # IPs secundarias solo para la primera instancia

  # Configuración de colocación
  availability_zone          = var.availability_zone          # AZ específica
  placement_group            = var.placement_group            # Placement group
  placement_partition_number = var.placement_partition_number # Número de partición
  tenancy                    = var.tenancy                    # Tenancy (default, dedicated, host)
  host_id                    = var.host_id                    # ID de host dedicado

  # Configuración de CPU
  cpu_options {
    core_count       = var.cpu_core_count       # Núcleos de CPU
    threads_per_core = var.cpu_threads_per_core # Threads por núcleo
  }

  ebs_optimized = var.ebs_optimized # Si está optimizado para EBS

  # Comportamiento de la instancia
  disable_api_termination              = var.disable_api_termination              # Protección contra terminación
  disable_api_stop                     = var.disable_api_stop                     # Protección contra stop
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior # Comportamiento al apagar

  # Monitoreo y características especiales
  monitoring        = var.monitoring        # Monitoreo detallado
  get_password_data = var.get_password_data # Obtener password (Windows)
  hibernation       = var.hibernation       # Hibernación habilitada

  # Configuración de red avanzada
  source_dest_check = var.source_dest_check # Verificación source/destination

  # User data (scripts de inicialización)
  user_data                   = var.user_data                   # Script directo
  user_data_base64            = var.user_data_base64            # Script en base64
  user_data_replace_on_change = var.user_data_replace_on_change # Reemplazar instancia si cambia

  # Configuración IPv6
  ipv6_address_count = var.ipv6_address_count # Número de IPv6
  ipv6_addresses     = var.ipv6_addresses     # IPv6 específicas

  # Opciones de metadatos (IMDS)
  dynamic "metadata_options" {
    for_each = [var.metadata_options]
    content {
      http_endpoint               = metadata_options.value.http_endpoint               # Habilita/deshabilita IMDS
      http_tokens                 = metadata_options.value.http_tokens                 # Requiere tokens (IMDSv2)
      http_put_response_hop_limit = metadata_options.value.http_put_response_hop_limit # Límite de hops
      instance_metadata_tags      = metadata_options.value.instance_metadata_tags      # Tags en metadatos
    }
  }

  # Dispositivo de bloque raíz (volumen principal)
  dynamic "root_block_device" {
    for_each = [var.root_block_device]
    content {
      volume_type           = root_block_device.value.volume_type                                      # Tipo de volumen (gp3, io1, etc.)
      volume_size           = root_block_device.value.volume_size                                      # Tamaño en GB
      iops                  = root_block_device.value.iops                                             # IOPS para tipos provisionados
      throughput            = root_block_device.value.throughput                                       # Throughput para gp3
      encrypted             = root_block_device.value.encrypted                                        # Si está encriptado
      kms_key_id            = root_block_device.value.kms_key_id                                       # KMS key para encriptación
      delete_on_termination = root_block_device.value.delete_on_termination                            # Eliminar al terminar
      tags                  = merge(local.default_tags, var.volume_tags, root_block_device.value.tags) # Tags combinados
    }
  }

  # Dispositivos EBS adicionales
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      device_name           = ebs_block_device.value.device_name # Nombre dispositivo (/dev/sdf, etc.)
      volume_type           = ebs_block_device.value.volume_type
      volume_size           = ebs_block_device.value.volume_size
      iops                  = ebs_block_device.value.iops
      throughput            = ebs_block_device.value.throughput
      encrypted             = ebs_block_device.value.encrypted
      kms_key_id            = ebs_block_device.value.kms_key_id
      snapshot_id           = ebs_block_device.value.snapshot_id # Snapshot de origen
      delete_on_termination = ebs_block_device.value.delete_on_termination
      tags                  = merge(local.default_tags, var.volume_tags, ebs_block_device.value.tags)
    }
  }

  # Dispositivos efímeros (almacenamiento temporal)
  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name  # Nombre dispositivo
      virtual_name = ephemeral_block_device.value.virtual_name # Nombre virtual (ephemeralN)
    }
  }

  # Configuración de capacity reservation
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_specification != null ? [var.capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = capacity_reservation_specification.value.capacity_reservation_preference

      dynamic "capacity_reservation_target" {
        for_each = capacity_reservation_specification.value.capacity_reservation_target != null ? [capacity_reservation_specification.value.capacity_reservation_target] : []
        content {
          capacity_reservation_id                 = capacity_reservation_target.value.capacity_reservation_id
          capacity_reservation_resource_group_arn = capacity_reservation_target.value.capacity_reservation_resource_group_arn
        }
      }
    }
  }

  # Opciones de mantenimiento
  dynamic "maintenance_options" {
    for_each = var.maintenance_options != null ? [var.maintenance_options] : []
    content {
      auto_recovery = maintenance_options.value.auto_recovery # Comportamiento en mantenimiento
    }
  }

  # Configuración de créditos CPU (instancias burstable)
  credit_specification {
    cpu_credits = var.cpu_credits # standard o unlimited
  }

  # Configuración de enclave (Nitro Enclave)
  enclave_options {
    enabled = try(var.enclave_options.enabled, false) # Habilita/deshabilita enclave
  }

  # Tags de la instancia
  tags = merge(local.default_tags, var.instance_tags)

  # Lifecycle: ignora cambios en estos atributos para no recrear la instancia
  lifecycle {
    ignore_changes = [
      ami,
      user_data_base64,
      ebs_block_device,
      root_block_device,
      security_groups
    ]
  }
}

resource "aws_spot_instance_request" "this" {
  count = local.is_module_enabled && local.is_spot_instance ? var.instance_count : 0

  # Configuración básica (similar a la instancia regular)
  ami           = local.ami_id
  instance_type = var.instance_type
  subnet_id     = element(local.subnet_ids, count.index % length(local.subnet_ids))
  key_name      = var.key_name

  # Configuración de seguridad
  vpc_security_group_ids = local.security_group_ids
  iam_instance_profile   = local.iam_instance_profile_name

  # Parámetros específicos de spot
  spot_price                     = var.spot_price                          # Precio máximo a pagar
  spot_type                      = var.spot_type                           # one-time o persistent
  valid_from                     = var.spot_valid_from                     # Fecha de inicio validez
  valid_until                    = var.spot_valid_until                    # Fecha de fin validez
  launch_group                   = var.spot_launch_group                   # Grupo de lanzamiento
  instance_interruption_behavior = var.spot_instance_interruption_behavior # Comportamiento al interrumpir
  wait_for_fulfillment           = true                                    # Esperar a que se cumpla la request

  # (Aquí irían todos los demás parámetros iguales que en aws_instance)

  # Tags específicos para instancias spot
  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-spot-${count.index}" # Nombre incluye "spot"
  })

  lifecycle {
    ignore_changes = [
      ami,
      spot_price, # Ignora cambios en el precio spot
      user_data_base64,
      ebs_block_device,
      root_block_device,
      security_groups
    ]
  }
}
