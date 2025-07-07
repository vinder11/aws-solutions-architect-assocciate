# --- IAM Role and Policy for Flow Logs ---
# Rol que asume el servicio de Flow Logs para publicar en el destino.
resource "aws_iam_role" "flow_logs_role" {
  count = var.log_destination_arn == null ? 1 : 0 # Solo crear el rol si no se proporciona un destino existente

  name = "vpc-flow-logs-role-${var.vpc_id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
  tags = var.tags
}

# Política que permite escribir en el destino (CloudWatch o S3)
resource "aws_iam_role_policy" "flow_logs_policy" {
  count = var.log_destination_arn == null ? 1 : 0 # Adjuntar política solo si creamos el rol

  name = "vpc-flow-logs-policy-${var.vpc_id}"
  role = aws_iam_role.flow_logs_role[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "*" # Simplificado por brevedad, se puede restringir al ARN específico
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ],
        Effect   = "Allow",
        Resource = var.log_destination_type == "s3" ? "arn:aws:s3:::${local.s3_bucket_name}/*" : "arn:aws:s3:::dummy" # Se aplica solo si el destino es S3
      }
    ]
  })
}
