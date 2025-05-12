data "aws_codeartifact_authorization_token" "this" {
  domain = aws_codeartifact_domain.this.domain
}

data "aws_codeartifact_repository_endpoint" "this" {
  domain     = aws_codeartifact_domain.this.domain
  repository = aws_codeartifact_repository.this.repository
  format     = "npm" # or "pypi", "maven", etc.
}
