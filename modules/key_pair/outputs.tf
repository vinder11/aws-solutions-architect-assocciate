# outputs.tf

output "key_name" {
  description = "El nombre del Key Pair creado."
  value       = aws_key_pair.main.key_name
}

output "key_pair_id" {
  description = "El ID del Key Pair."
  value       = aws_key_pair.main.id
}

output "arn" {
  description = "El ARN del Key Pair."
  value       = aws_key_pair.main.arn
}

output "fingerprint" {
  description = "El fingerprint de la clave pública (SHA256)."
  value       = aws_key_pair.main.fingerprint
}
