data "aws_codeartifact_authorization_token" "this" {
  domain = aws_codeartifact_domain.this.domain
  depends_on = [aws_codeartifact_domain.this]
}

data "aws_codeartifact_repository_endpoint" "this" {
  for_each = aws_codeartifact_repository.this
  repository = each.value.repository
  domain     = aws_codeartifact_domain.this.domain
  format     = split("-", each.value.repository)[1]
  depends_on = [aws_kms_key.this, aws_codeartifact_repository.this]
}

data "aws_iam_policy_document" "artifactPolicy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["codeartifact:*"]
    resources = [aws_codeartifact_domain.this.arn]
  }
}