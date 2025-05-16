################################################################################
# Standard
################################################################################

output "standard_secret_arn" {
  description = "The ARN of the secret"
  value       = module.secrets_manager.secret_arn
}

output "standard_secret_id" {
  description = "The ID of the secret"
  value       = module.secrets_manager.secret_id
}

output "standard_secret_name" {
  description = "The name of the secret"
  value       = module.secrets_manager.secret_name
}

output "standard_secret_replica" {
  description = "Attributes of the replica created"
  value       = module.secrets_manager.secret_replica
}

output "standard_secret_version_id" {
  description = "The unique identifier of the version of the secret"
  value       = module.secrets_manager.secret_version_id
}

output "standard_secret_string" {
  description = "The secret string"
  sensitive   = true
  value       = jsonencode({
    random_password = module.secrets_manager.secret_string
  })
}