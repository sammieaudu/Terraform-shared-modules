resource "aws_codeartifact_domain" "this" {
  domain = var.domain_name
  tags   = var.tags
}

resource "aws_codeartifact_repository" "this" {
  repository = var.repository_name
  domain     = aws_codeartifact_domain.this.domain
  description = var.description

  dynamic "external_connections" {
    for_each = var.external_connections
    content {
      external_connection_name = external_connections.value
    }
  }


  tags = var.tags
}