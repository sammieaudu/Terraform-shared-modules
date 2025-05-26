data "aws_caller_identity" "current" {}
############
# IAM users
############
module "user_developers" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.0.0"

  count = length(var.iam_developerUser_names)

  name = "${var.iam_developerUser_names[count.index]}"
  path = "/developers/"

  create_iam_user_login_profile = true
  create_iam_access_key         = true

  tags = local.tags
}

module "user_devops" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.0.0"

  count = length(var.iam_devOpsUser_names)

  name = "${var.iam_devOpsUser_names[count.index]}"
  path = "/devops/"

  create_iam_user_login_profile = true
  create_iam_access_key         = true

  tags = local.tags
}

# Create MFA policy
data "aws_iam_policy_document" "mfa_policy" {
  statement {
    sid    = "AllowUsersToManageTheirOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/*"
    ]
  }

  statement {
    sid    = "AllowUsersToManageTheirOwnMFAConsole"
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
      "iam:ListVirtualMFADevices"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/*"
    ]
  }
}

# Create MFA enforcement policy
data "aws_iam_policy_document" "mfa_enforcement" {
  statement {
    sid    = "EnforceMFAAccess"
    effect = "Deny"
    actions = ["*"]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

# Create MFA enforcement policy for role assumption
data "aws_iam_policy_document" "mfa_role_assumption" {
  statement {
    sid    = "EnforceMFARoleAssumption"
    effect = "Deny"
    actions = ["sts:AssumeRole"]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa_policy" {
  name        = "MFAPolicy"
  description = "Policy to allow users to manage their own MFA devices"
  policy      = data.aws_iam_policy_document.mfa_policy.json
}

resource "aws_iam_policy" "mfa_enforcement" {
  name        = "MFAEnforcementPolicy"
  description = "Policy to enforce MFA for all actions"
  policy      = data.aws_iam_policy_document.mfa_enforcement.json
}

resource "aws_iam_policy" "mfa_role_assumption" {
  name        = "MFARoleAssumptionPolicy"
  description = "Policy to enforce MFA for role assumption"
  policy      = data.aws_iam_policy_document.mfa_role_assumption.json
}

#####################################################################################
# IAM group for DevOps with full Administrator access
#####################################################################################
module "iam_group_devops" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "devops"

  group_users = module.user_devops[*].iam_user_name

  custom_group_policy_arns = concat(var.devops_cgp_arn, [
    aws_iam_policy.mfa_policy.arn,
    aws_iam_policy.mfa_enforcement.arn
  ])

  depends_on = [ module.user_devops ]
}

module "iam_group_devops_with_assumed_roles" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-assumable-roles-policy"

  name = "devops-with_AssumedRoles"
  assumable_roles = [module.eks_cluster_role.iam_role_arn]
  group_users = module.user_devops[*].iam_user_name

  depends_on = [ module.user_devops ]
}

#####################################################################################
# IAM group for Developers with Custom Access
#####################################################################################
module "iam_group_developers" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "developers"
  group_users = module.user_developers[*].iam_user_name
  custom_group_policy_arns = concat(var.developer_cgp_arn, [
    aws_iam_policy.mfa_policy.arn,
    aws_iam_policy.mfa_enforcement.arn
  ])

  depends_on = [ module.user_developers ]
}

module "iam_group_developers_with_assumed_roles" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-assumable-roles-policy"

  name = "developers-with_assumed_roles"
  assumable_roles = [module.eks_cluster_role.iam_role_arn]
  group_users = module.user_developers[*].iam_user_name

  depends_on = [ module.user_developers ]
}

#####################################################################################
# IAM Role - EKS Cluster
#####################################################################################
module "eks_cluster_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.0.0"

  role_name = "AmazonEKSClusterRole"
  create_role = true
  role_path = "/"
  role_requires_mfa = true
  trusted_role_services = ["eks.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
}