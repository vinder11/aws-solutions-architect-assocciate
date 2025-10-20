# outputs.tf
output "id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.this.id
}

output "arn" {
  description = "ARN del Launch Template"
  value       = aws_launch_template.this.arn
}

output "latest_version" {
  description = "Última versión del Launch Template"
  value       = aws_launch_template.this.latest_version
}

output "default_version" {
  description = "Versión default del Launch Template"
  value       = aws_launch_template.this.default_version
}

output "name" {
  description = "Nombre del Launch Template"
  value       = aws_launch_template.this.name
}