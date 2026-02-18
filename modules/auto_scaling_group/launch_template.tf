# Security Group
resource "aws_security_group" "asg" {
  count = local.create_launch_template ? 1 : 0

  name_prefix = "${var.name}-asg-"
  description = "Security group for ${var.name} Auto Scaling Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-asg-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template
resource "aws_launch_template" "this" {
  count = local.create_launch_template ? 1 : 0

  name_prefix   = "${var.name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data != "" ? base64encode(var.user_data) : null

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  monitoring {
    enabled = var.enable_monitoring
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = true
    security_groups = concat(
      [aws_security_group.asg[0].id],
      var.additional_security_group_ids
    )
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = var.root_block_device.volume_type
      volume_size           = var.root_block_device.volume_size
      delete_on_termination = var.root_block_device.delete_on_termination
      encrypted             = var.root_block_device.encrypted
    }
  }

  ebs_optimized = var.ebs_optimized

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      var.instance_tags,
      {
        Name = "${var.name}-instance"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      {
        Name = "${var.name}-volume"
      }
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-lt"
    }
  )
}
