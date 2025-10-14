# ============================================
# RECURSOS
# ============================================

resource "aws_ebs_volume" "this" {
  for_each = var.ebs_volumes

  availability_zone    = each.value.availability_zone
  size                 = each.value.size
  type                 = each.value.type
  encrypted            = each.value.encrypted
  kms_key_id           = each.value.kms_key_id
  snapshot_id          = each.value.snapshot_id
  outpost_arn          = each.value.outpost_arn
  multi_attach_enabled = each.value.multi_attach

  # IOPS solo para tipos que lo soportan
  iops = contains(["gp3", "io1", "io2"], each.value.type) ? local.volume_iops[each.key] : null

  # Throughput solo para gp3
  throughput = each.value.type == "gp3" ? local.volume_throughput[each.key] : null

  final_snapshot = each.value.final_snapshot

  tags = local.volume_tags[each.key]

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_volume_attachment" "this" {
  for_each = var.attachment_config

  device_name                    = each.value.device_name
  volume_id                      = aws_ebs_volume.this[each.value.volume_key].id
  instance_id                    = each.value.instance_id
  force_detach                   = each.value.force_detach
  skip_destroy                   = each.value.skip_destroy
  stop_instance_before_detaching = each.value.stop_instance_before_detaching
}

# Política de ciclo de vida DLM para snapshots
resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  count = var.enable_volume_snapshots ? 1 : 0

  description        = var.snapshot_schedule.description
  execution_role_arn = aws_iam_role.dlm_lifecycle_role[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = var.snapshot_schedule.name

      create_rule {
        interval      = var.snapshot_schedule.interval
        interval_unit = var.snapshot_schedule.interval_unit
        times         = var.snapshot_schedule.times
      }

      retain_rule {
        count = var.snapshot_schedule.retain_count
      }

      tags_to_add = merge(
        var.snapshot_schedule.tags,
        {
          SnapshotType = "automated"
          ManagedBy    = "Terraform-DLM"
        }
      )

      copy_tags = true
    }

    target_tags = {
      SnapshotBackup = "true"
    }
  }

  tags = merge(
    var.default_tags,
    {
      Name = var.snapshot_schedule.name
    }
  )
}

# IAM Role para DLM
resource "aws_iam_role" "dlm_lifecycle_role" {
  count = var.enable_volume_snapshots ? 1 : 0

  name = "dlm-lifecycle-role-${var.snapshot_schedule.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })

  tags = var.default_tags
}

resource "aws_iam_role_policy" "dlm_lifecycle_policy" {
  count = var.enable_volume_snapshots ? 1 : 0

  name = "dlm-lifecycle-policy"
  role = aws_iam_role.dlm_lifecycle_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots",
          "ec2:DeleteSnapshot",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*::snapshot/*"
      }
    ]
  })
}
