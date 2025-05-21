# GitHub Actions IAM Role for OIDC AssumeRole

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "github_actions_role" {
  name = var.github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          StringLike : {
            "token.actions.githubusercontent.com:sub" : "repo:${var.github_org_or_user}/*:*"
          }
        }
      }
    ]
  })
}

# Custom IAM policy with scoped permissions
resource "aws_iam_policy" "github_actions_provisioning_policy" {
  name = "GHA_TF_ProvisioningPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "sts:GetServiceBearerToken",
        Resource = "*",
        Condition = {
          StringEquals = {
            "sts:AWSServiceName" : "codeartifact.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_provisioning_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_provisioning_policy.arn
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "986323537898"
}

variable "github_actions_role_name" {
  description = "Name of the IAM Role for GitHub Actions"
  type        = string
  default     = "openid-gha-role"
}

variable "github_org_or_user" {
  description = "GitHub Organization or User"
  type        = string
  default     = "sammieaudu"
}
