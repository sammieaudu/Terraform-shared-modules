resource "aws_ecr_account_setting" "registry_policy_scope" {
  name  = "REGISTRY_POLICY_SCOPE"
  value = "V2"
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "ENHANCED"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

resource "aws_ecr_repository" "this" {
  name                 = var.env
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags_all = local.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = templatefile("${path.module}/policy/lifecycle.json", {})

  depends_on = [ aws_ecr_repository.this ]
}

