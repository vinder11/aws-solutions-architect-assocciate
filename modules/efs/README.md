# terraform-aws-efs

Módulo Terraform reutilizable para AWS Elastic File System (EFS). Una sola interfaz cubre desde NFS compartido simple hasta file systems de alta disponibilidad con replicación cross-region, access points multi-tenant para Kubernetes, y almacenamiento One Zone de bajo costo con archivado profundo.

## Features soportadas

| Feature | Descripción |
|---|---|
| Performance modes | `generalPurpose` (latency-optimized) / `maxIO` (throughput-optimized) |
| Throughput modes | `bursting` / `provisioned` (MiB/s fija) / `elastic` (auto-scaling) |
| Encryption | SSE-KMS con CMK o AWS-managed key |
| One Zone storage | AZ única, ~47% más barato para staging/backup |
| Intelligent-Tiering | IA (7–365 días), Archive (90–730 días), restore on access |
| Mount targets | Multi-AZ con SGs por MT, IPs estáticas opcionales |
| Security group managed | Module crea SG con reglas granulares (ingress/egress) |
| Access points | Multi-tenant: root dir, POSIX UID/GID, creation_info, secondary_gids |
| File system policy | Resource-based IAM: deny non-TLS managed + custom policy override |
| Replication | Cross-region / same-region, destino existente o nuevo, KMS en destino |
| AWS Backup | Integración directa con la política de backup de EFS |
| Data protection | `replication_overwrite` ENABLED/DISABLED |

## Requisitos

- Terraform `>= 1.6.0`
- AWS Provider `>= 5.34.0`

## Estructura

```
modules/efs/
├── variables.tf   # ~390 líneas — tipado exhaustivo + validación
├── main.tf        # ~310 líneas — recursos con dynamic blocks
├── outputs.tf     # ~140 líneas — outputs + helpers K8s/mount
└── versions.tf

examples/
├── basic-shared-storage/    NFS multi-AZ, SG managed, Intelligent-Tiering
├── eks-persistent-volume/   Access points por namespace, IRSA policy, K8s spec
├── multi-az-ha/             maxIO + provisioned, replicación CRR, IPs estáticas
└── backup-compliance/       One Zone, cross-account policy, deep archive
```

## Uso rápido

### NFS multi-AZ básico

```hcl
module "efs" {
  source = "./modules/efs"

  name        = "mi-efs"
  environment = "prod"
  vpc_id      = "vpc-0abc123"

  encrypted  = true
  kms_key_id = "alias/mi-clave"

  throughput_mode  = "elastic"
  performance_mode = "generalPurpose"

  lifecycle_policy = {
    transition_to_ia      = "AFTER_30_DAYS"
    transition_to_primary = "AFTER_1_ACCESS"
  }

  mount_targets = {
    az1 = { subnet_id = "subnet-aaa" }
    az2 = { subnet_id = "subnet-bbb" }
    az3 = { subnet_id = "subnet-ccc" }
  }

  # SG managed por el módulo
  create_security_group = true
  security_group_rules = {
    nfs_app = {
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      source_security_group_id = "sg-app123"
    }
    egress = {
      type        = "egress"
      from_port   = 0; to_port = 0; protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

### Access points para Kubernetes

```hcl
module "efs_eks" {
  source = "./modules/efs"

  name   = "efs-eks"
  vpc_id = "vpc-0abc123"
  # ... mount targets ...

  access_points = {
    app_ns = {
      root_directory = {
        path = "/app"
        creation_info = { owner_uid = 1000, owner_gid = 1000, permissions = "0755" }
      }
      posix_user = { uid = 1000, gid = 1000 }
    }
  }
}
# Usar en PV: module.efs_eks.access_point_ids["app_ns"]
```

### Replicación cross-region

```hcl
replication_configuration = {
  destination = {
    region     = "us-west-2"
    kms_key_id = "alias/efs-dr-key"
  }
}
```

### One Zone (cost-optimized)

```hcl
availability_zone_name = "us-east-1a"
# Un solo mount target en esa AZ
mount_targets = {
  az1 = { subnet_id = "subnet-in-us-east-1a" }
}
```

## Variables principales

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `name` | `string` | — | Nombre (regex validado) |
| `performance_mode` | `string` | `generalPurpose` | `generalPurpose` \| `maxIO` |
| `throughput_mode` | `string` | `elastic` | `bursting` \| `provisioned` \| `elastic` |
| `provisioned_throughput_in_mibps` | `number` | `null` | Requerido si `throughput_mode = provisioned` |
| `encrypted` | `bool` | `true` | Cifrado en reposo |
| `kms_key_id` | `string` | `null` | KMS key ARN o alias |
| `availability_zone_name` | `string` | `null` | One Zone AZ (null = Regional) |
| `lifecycle_policy` | `object` | `{}` | IA, Archive, restore transitions |
| `mount_targets` | `map(object)` | `{}` | Subnet, SGs por AZ, IP estática opcional |
| `create_security_group` | `bool` | `true` | Módulo crea y gestiona el SG |
| `security_group_rules` | `map(object)` | NFS+egress | Reglas ingress/egress para SG managed |
| `access_points` | `map(object)` | `{}` | Root dir, POSIX user, creation info |
| `file_system_policy` | `string` | `null` | JSON policy (override de managed) |
| `attach_deny_non_tls_policy` | `bool` | `true` | Deniega conexiones sin TLS |
| `replication_configuration` | `object` | `null` | CRR/SRR config |
| `enable_backup` | `bool` | `true` | Integración con AWS Backup |
| `protection` | `object` | `ENABLED` | Replication overwrite protection |

## Outputs principales

| Output | Descripción |
|---|---|
| `file_system_id` | ID del EFS (`fs-...`) |
| `file_system_arn` | ARN del EFS |
| `file_system_dns_name` | DNS para montaje NFS |
| `mount_target_ips` | Map key → IP por AZ |
| `mount_target_dns_names` | Map key → DNS específico por AZ |
| `security_group_id` | ID del SG managed |
| `access_point_ids` | Map key → AP ID |
| `access_point_arns` | Map key → AP ARN |
| `mount_command` | Comando NFS listo para usar |
| `efs_utils_mount_command` | Comando con TLS via amazon-efs-utils |
| `fstab_entry` | Entrada /etc/fstab con TLS + IAM |
| `kubernetes_persistent_volume_spec` | Spec para EFS CSI driver |
| `replication_destination_file_system_id` | ID del EFS destino de replicación |

## Notas de diseño

**`lifecycle.precondition` en `aws_efs_file_system`** — capturadas en `plan`:
- `provisioned_throughput_in_mibps` requerido si y solo si `throughput_mode = provisioned`
- `maxIO` es incompatible con `elastic` throughput mode (AWS limitation)
- `kms_key_id` solo válido cuando `encrypted = true`

**`ignore_changes` en atributos inmutables:**
`performance_mode` y `availability_zone_name` no pueden cambiar post-creación. El bloque `ignore_changes` evita que Terraform proponga una recreación destructiva si se detecta drift.

**Security group con recursos separados:**
Se usan `aws_vpc_security_group_ingress_rule` y `aws_vpc_security_group_egress_rule` (AWS provider ≥ 5.x) en lugar del bloque `ingress`/`egress` inline en `aws_security_group`. Esto evita el problema de conflictos cuando otros módulos o recursos añaden reglas al mismo SG.

**SG resolution por capas:**
`per-MT security_group_ids` → `var.security_group_ids` → `managed_sg`. Los locals calculan la lista efectiva por mount target de forma determinista.

**Policy composition:**
`var.file_system_policy` toma ownership total. Si no se provee, el módulo puede generar automáticamente una policy de deny-non-TLS vía `data.aws_iam_policy_document`.
