output "domain_name" {
  value = aws_codeartifact_domain.this.domain
  depends_on = [aws_kms_key.this, aws_codeartifact_domain.this]
}

output "repository_names" {
  value = { for k, v in aws_codeartifact_repository.this : k => v.repository }
  depends_on = [aws_kms_key.this, aws_codeartifact_repository.this]
}

output "repository_arns" {
  value = { for k, v in aws_codeartifact_repository.this : k => v.arn }
  depends_on = [aws_kms_key.this, aws_codeartifact_repository.this]
}

output "repository_endpoints" {
  value = { for k, v in data.aws_codeartifact_repository_endpoint.this : k => v.repository_endpoint }
  depends_on = [aws_kms_key.this, data.aws_codeartifact_repository_endpoint.this]
}
