output "rotate_secret_arn" {
  description = "The ARN of the secret"
  value       = module.secrets_manager_rotate.secret_arn
}

output "rotate_secret_id" {
  description = "The ID of the secret"
  value       = module.secrets_manager_rotate.secret_id
}

output "rotate_secret_replica" {
  description = "Attributes of the replica created"
  value       = module.secrets_manager_rotate.secret_replica
}

output "rotate_secret_version_id" {
  description = "The unique identifier of the version of the secret"
  value       = module.secrets_manager_rotate.secret_version_id
}

output "rotate_secret_string" {
  description = "The secret string"
  sensitive   = true
  value       = module.secrets_manager_rotate.secret_string
}