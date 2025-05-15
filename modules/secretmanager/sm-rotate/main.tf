data "aws_caller_identity" "current" {}

module "secrets_manager_rotate" {
  source = "terraform-aws-modules/secrets-manager/aws"

  # Secret
  name_prefix             = var.secret_manager_name
  description             = "Rotated Secrets Manager secret"
  recovery_window_in_days = 0

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    lambda = {
      sid = "LambdaReadWrite"
      principals = [{
        type        = "AWS"
        identifiers = var.lambda_role_arn #[module.lambda.lambda_role_arn]
      }]
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage",
      ]
      resources = ["*"]
    }
    account = {
      sid = "AccountDescribe"
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      actions   = ["secretsmanager:DescribeSecret"]
      resources = ["*"]
    }
  }

  # Version
  ignore_secret_changes = true
  secret_string = jsonencode({
    engine   = var.engine,
    host     = var.host,
    username = var.username,
    password = var.password,
    dbname   = var.dbname,
    port     = var.port
  })

  # Rotation
  enable_rotation     = true
  rotation_lambda_arn = var.lambda_function_arn # module.lambda.lambda_function_arn
  rotation_rules = {
    # This should be more sensible in production
    schedule_expression = var.rotation_rule
  }

  tags = local.tags
}