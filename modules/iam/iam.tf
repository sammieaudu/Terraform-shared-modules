# resource "aws_iam_role" "eks_cluster" {
#   name = "${var.name}-eks-cluster-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "eks.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
#   tags = var.tags
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
#   role       = aws_iam_role.eks_cluster.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role" "eks_node_group" {
#   name = "${var.name}-eks-node-group-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
#   tags = var.tags
# }

# resource "aws_iam_role_policy_attachment" "eks_node_group_policies" {
#   count      = length(var.node_group_policy_arns)
#   role       = aws_iam_role.eks_node_group.name
#   policy_arn = var.node_group_policy_arns[count.index]
# }

# resource "aws_iam_role" "codebuild" {
#   name = "${var.name}-codebuild-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "codebuild.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
#   tags = var.tags
# }

# resource "aws_iam_role_policy_attachment" "codebuild_policies" {
#   count      = length(var.codebuild_policy_arns)
#   role       = aws_iam_role.codebuild.name
#   policy_arn = var.codebuild_policy_arns[count.index]
# }

# resource "aws_iam_policy" "ecr_readonly_custom" {
#   name = "ecr-readonly"
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
# resource "aws_iam_role_policy_attachment" "eks_node_group_ecr_custom" {
#   role       = aws_iam_role.eks_node_group.name
#   policy_arn = aws_iam_policy.ecr_readonly_custom.arn
# }

# #add oidc configuraion and at least 3 roles ( 1 role for provision infrastructure, application pipeline 1, 1 application) (cicd pipelin)