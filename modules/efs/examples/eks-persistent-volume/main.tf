# ============================================================
# examples/eks-persistent-volume/main.tf
#
# EFS for Kubernetes / EKS workloads using the EFS CSI driver:
#   - One Access Point per namespace/application (multi-tenant)
#   - POSIX UID/GID enforcement per access point
#   - Root directory created automatically with correct permissions
#   - SG rule sourced from the EKS node group SG
#   - Elastic throughput (handles bursty K8s workloads)
#   - IAM policy for EFS CSI driver service account (IRSA)
#
# Kubernetes resources (StorageClass, PV, PVC) generated as
# local_file outputs for reference — apply separately with kubectl.
# ============================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.34.0" }
  }
}

provider "aws" { region = var.aws_region }

# ── EFS module ────────────────────────────────────────────

module "efs_eks" {
  source = "../../modules/efs"

  name        = "bsol-eks-efs"
  environment = var.environment

  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  encrypted  = true
  kms_key_id = var.kms_key_arn

  # Intelligent-Tiering for persistent volume data
  lifecycle_policy = {
    transition_to_ia      = "AFTER_60_DAYS"
    transition_to_primary = "AFTER_1_ACCESS"
    transition_to_archive = null
  }

  vpc_id = var.vpc_id

  # SG: only EKS nodes can NFS-mount
  create_security_group      = true
  security_group_description = "EFS NFS for EKS node groups"

  security_group_rules = {
    nfs_from_eks_nodes = {
      type                     = "ingress"
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "NFS from EKS node group SG"
      source_security_group_id = var.eks_node_group_sg_id
    }
    all_egress = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # One mount target per AZ where EKS nodes run
  mount_targets = {
    az1 = { subnet_id = var.eks_subnet_az1 }
    az2 = { subnet_id = var.eks_subnet_az2 }
    az3 = { subnet_id = var.eks_subnet_az3 }
  }

  # ── Access Points: one per application namespace ──────────
  # Each enforces its own root dir and POSIX identity.
  # EFS CSI driver uses access points for dynamic provisioning.
  access_points = {
    # Namespace: monitoring (Prometheus TSDB, Grafana data)
    monitoring = {
      root_directory = {
        path = "/monitoring"
        creation_info = {
          owner_uid   = 1000
          owner_gid   = 1000
          permissions = "0755"
        }
      }
      posix_user = {
        uid = 1000
        gid = 1000
      }
      tags = { K8sNamespace = "monitoring" }
    }

    # Namespace: data-pipeline (Spark/Flink shared staging)
    data_pipeline = {
      root_directory = {
        path = "/data-pipeline"
        creation_info = {
          owner_uid   = 2000
          owner_gid   = 2000
          permissions = "0770"
        }
      }
      posix_user = {
        uid            = 2000
        gid            = 2000
        secondary_gids = [3000, 3001] # supplementary groups for shared access
      }
      tags = { K8sNamespace = "data-pipeline" }
    }

    # Namespace: app-backend (uploads and shared config)
    app_backend = {
      root_directory = {
        path = "/app-backend"
        creation_info = {
          owner_uid   = 1001
          owner_gid   = 1001
          permissions = "0750"
        }
      }
      posix_user = {
        uid = 1001
        gid = 1001
      }
      tags = { K8sNamespace = "app-backend" }
    }

    # Root access point for admin/ops tooling
    admin = {
      root_directory = { path = "/" }
      posix_user     = { uid = 0, gid = 0 }
      tags           = { K8sNamespace = "kube-system" }
    }
  }

  enable_backup              = true
  attach_deny_non_tls_policy = true

  tags = {
    Project    = "bsol-eks"
    Owner      = "platform-engineering"
    CostCenter = "k8s"
    EKSCluster = var.eks_cluster_name
  }
}

# ── IAM policy for EFS CSI driver (IRSA) ────────────────────

data "aws_iam_policy_document" "efs_csi" {
  statement {
    sid    = "AllowDescribeFileSystems"
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCreateAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateAccessPoint",
    ]
    resources = [module.efs_eks.file_system_arn]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid    = "AllowDeleteAccessPoint"
    effect = "Allow"
    actions = ["elasticfilesystem:DeleteAccessPoint"]
    resources = [module.efs_eks.file_system_arn]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid    = "AllowClientMount"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess",
    ]
    resources = [module.efs_eks.file_system_arn]
    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "efs_csi" {
  name        = "${var.eks_cluster_name}-efs-csi-policy"
  description = "IAM policy for EFS CSI driver service account"
  policy      = data.aws_iam_policy_document.efs_csi.json
  tags        = { EKSCluster = var.eks_cluster_name }
}

# ── Variables ──────────────────────────────────────────────

variable "aws_region"              { type = string; default = "us-east-1" }
variable "environment"             { type = string; default = "prod" }
variable "vpc_id"                  { type = string }
variable "eks_subnet_az1"          { type = string }
variable "eks_subnet_az2"          { type = string }
variable "eks_subnet_az3"          { type = string }
variable "kms_key_arn"             { type = string }
variable "eks_node_group_sg_id"    { type = string }
variable "eks_cluster_name"        { type = string }

# ── Outputs ────────────────────────────────────────────────

output "file_system_id"        { value = module.efs_eks.file_system_id }
output "file_system_dns_name"  { value = module.efs_eks.file_system_dns_name }
output "access_point_ids"      { value = module.efs_eks.access_point_ids }
output "access_point_arns"     { value = module.efs_eks.access_point_arns }
output "security_group_id"     { value = module.efs_eks.security_group_id }
output "efs_csi_policy_arn"    { value = aws_iam_policy.efs_csi.arn }
output "k8s_pv_spec"           { value = module.efs_eks.kubernetes_persistent_volume_spec }
