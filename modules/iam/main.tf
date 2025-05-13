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

#####################################################################################
# IAM group for DevOps with full Administrator access
#####################################################################################
module "iam_group_devops" {
  source = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "devops"

  group_users = module.user_devops[*].iam_user_name

  custom_group_policy_arns = var.devops_cgp_arn

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
  custom_group_policy_arns = var.developer_cgp_arn
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
  role_requires_mfa = false
  trusted_role_services = ["eks.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"]
}