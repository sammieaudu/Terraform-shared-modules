locals {
  name   = "${var.env}-${var.region}"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)


  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}
################################################
# Data Blocks
################################################
data "aws_availability_zones" "available" {}

################################################
# IAM Configuration
################################################
module "iam" {
  source = "../../modules/iam"
  env              = var.env
  region           = var.region
  iam_groups_names = var.iam_groups_names
  iam_developerUser_names = var.iam_developerUser_names
  iam_devOpsUser_names = var.iam_devOpsUser_names
  devops_cgp_arn= var.devops_cgp_arn
  developer_cgp_arn= var.developer_cgp_arn
}

################################################
# VPC Netwok
################################################
module "network" {
  source = "../../modules/network"
  providers = {
    aws = aws.network
  }
  aws_profile      = var.aws_profile
  env              = var.env
  region           = var.region
  vpc_cidr         = var.vpc_cidr
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets
}

################################################
# EKS
################################################
module "eks" {
  source       = "../../modules/eks"
  cluster_version = var.cluster_version
  env              = var.env
  region           = var.region
  account          = var.account
  eks_vpc     = module.network.vpc_id
  eks_private_subnets = flatten([module.network.private_subnets_ids])
}

################################################
# RDS
################################################
# module "rds" {
#   source        = "../../modules/rds"
#   db_subnet_ids = module.network.isolated_subnet_ids
# }
