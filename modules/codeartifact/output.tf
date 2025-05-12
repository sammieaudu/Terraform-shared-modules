output "domain_name" {
  value = aws_codeartifact_domain.this.domain
}

output "repository_name" {
  value = aws_codeartifact_repository.this.repository
}

output "repository_arn" {
  value = aws_codeartifact_repository.this.arn
}

output "repository_endpoint" {
  value = data.aws_codeartifact_repository_endpoint.this.repository_endpoint
}
