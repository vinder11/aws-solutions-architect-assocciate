# outputs.tf

output "public_ip" {
  description = "La dirección IP pública asignada."
  value       = aws_eip.main.public_ip
}

output "allocation_id" {
  description = "El ID de asignación de la EIP. Necesario para las asociaciones."
  value       = aws_eip.main.allocation_id
}

output "association_id" {
  description = "El ID de la asociación, si se creó una."
  value       = one(aws_eip_association.main[*].id)
}
