
output "instance_ids" {
  description = "IDs de las instancias EC2 creadas"
  value = compact(concat(
    aws_instance.this[*].id,
    aws_spot_instance_request.this[*].id
  ))
}

output "instance_arns" {
  description = "ARNs de las instancias EC2 creadas"
  value = compact(concat(
    aws_instance.this[*].arn,
    aws_spot_instance_request.this[*].arn
  ))
}

output "instance_public_ips" {
  description = "IPs públicas de las instancias"
  value = compact(concat(
    aws_instance.this[*].public_ip,
    aws_spot_instance_request.this[*].public_ip
  ))
}

output "instance_private_ips" {
  description = "IPs privadas de las instancias"
  value = compact(concat(
    aws_instance.this[*].private_ip,
    aws_spot_instance_request.this[*].private_ip
  ))
}

output "security_group_id" {
  description = "ID del security group creado"
  value       = try(aws_security_group.this[0].id, null)
}

output "iam_role_name" {
  description = "Nombre del IAM role creado"
  value       = try(aws_iam_role.this[0].name, null)
}

output "iam_instance_profile_arn" {
  description = "ARN del IAM instance profile creado"
  value       = try(aws_iam_instance_profile.this[0].arn, null)
}

output "backup_plan_arn" {
  description = "ARN del plan de backup creado"
  value       = try(aws_backup_plan.this[0].arn, null)
}
