module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = var.lambda_secret_manager_name
  description   = "Secrets Manager secret rotation lambda function"

  handler     = "function.lambda_handler"
  runtime     = "python3.10"
  timeout     = 60
  memory_size = 512
  source_path = "${path.module}/function.py"

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.this.json

  publish = true
  allowed_triggers = {
    secrets = {
      principal = "secretsmanager.amazonaws.com"
    }
  }

  cloudwatch_logs_retention_in_days = 7

  # Enable X-Ray tracing
  attach_tracing_policy = true
  tracing_mode         = "Active"

  tags = local.tags
}