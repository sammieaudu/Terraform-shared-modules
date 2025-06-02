###
################################################
# Data Blocks
################################################
data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

################################################
# S3 Buckets
################################################
module "s3" {
  source       = "../../modules/s3"
  env          = var.env
  region       = var.region
  buckets_list = var.buckets_list
}

################################################
# Code Artifacts
################################################
module "artifact" {
  source               = "../../modules/codeartifact"
  env                  = var.env
  repository_name      = var.artifact_repo
  external_connections = var.external_packages
}

################################################
# ECR Repo
################################################
module "ecr" {
  source = "../../modules/ecr"
  env    = var.env
}

################################################
# IAM Configuration
################################################
module "iam" {
  source                  = "../../modules/iam"
  env                     = var.env
  region                  = var.region
  iam_groups_names        = var.iam_groups_names
  iam_developerUser_names = var.iam_developerUser_names
  iam_devOpsUser_names    = var.iam_devOpsUser_names
  devops_cgp_arn          = var.devops_cgp_arn
  developer_cgp_arn       = var.developer_cgp_arn
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
  source              = "../../modules/eks"
  cluster_version     = var.cluster_version
  env                 = var.env
  region              = var.region
  eks_vpc             = module.network.vpc_id
  eks_private_subnets = module.network.private_subnets
}

################################################
# RDS
################################################
module "rds" {
  source                  = "../../modules/rds"
  env                     = var.env
  region                  = var.region
  rds_config              = var.rds_config
  database_subnet_group   = module.network.database_subnet_group_name
  password_rotation_rules = "rate(15 days)"
  vpc_id                  = module.network.vpc_id
  vpc_cidr                = module.network.vpc_cidr_block
}

################################################
# Amplify
################################################
module "amplify" {
  source       = "../../modules/amplify"
  env          = var.env
  region       = var.region
  amp_config   = var.amp_config
  custom_rules = var.amp_custom_rules
}

################################################
# Redis Elasticache
################################################
module "redis" {
  source              = "../../modules/elasticache"
  env                 = var.env
  region              = var.region
  database_subnet_ids = module.network.database_subnets
  vpc_id              = module.network.vpc_id
  vpc_cidr            = module.network.vpc_cidr_block
}
