// Code Artifact KMS
resource "aws_kms_key" "this" {
  description = "domain key"
  enable_key_rotation = true
  rotation_period_in_days = 90
}

// Code Artifact Domain
resource "aws_codeartifact_domain" "this" {
  domain = var.env
  encryption_key = aws_kms_key.this.arn
  tags   = local.tags
  depends_on = [aws_kms_key.this]
}

resource "aws_codeartifact_domain_permissions_policy" "test" {
  domain          = aws_codeartifact_domain.this.domain
  policy_document = data.aws_iam_policy_document.artifactPolicy.json
  depends_on = [ aws_kms_key.this, aws_codeartifact_domain.this, data.aws_iam_policy_document.artifactPolicy]
}

// Code Artifact Repository
resource "aws_codeartifact_repository" "this" {
  for_each = { for k, v in var.external_connections: k => v }
  repository = "${var.repository_name}-${each.key}"
  domain     = aws_codeartifact_domain.this.domain
  description = "Code Artifact Repo for ${var.env}"

  external_connections {
    external_connection_name = "public:${each.value}"
  }

  tags = local.tags
  depends_on = [aws_kms_key.this, aws_codeartifact_domain.this]
}

resource "aws_codeartifact_repository_permissions_policy" "this" {
  for_each = aws_codeartifact_repository.this
  repository      = each.value.repository
  domain          = aws_codeartifact_domain.this.domain
  policy_document = data.aws_iam_policy_document.artifactPolicy.json
  depends_on = [aws_kms_key.this, aws_codeartifact_domain.this, aws_codeartifact_repository.this, data.aws_iam_policy_document.artifactPolicy]
}

// Add a delay to allow external connections to be established
resource "time_sleep" "wait_for_external_connections" {
  depends_on = [aws_codeartifact_repository.this]
  create_duration = "30s"
}
