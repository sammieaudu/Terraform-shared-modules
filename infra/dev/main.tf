locals {
  name   = "${var.env}-vpc"
  region = var.region

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

data "aws_availability_zones" "available" {}

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
# module "eks" {
#   source       = "../../modules/eks"
#   cluster_name = var.eks_cluster_name
#   subnets      = module.network.private_subnet_ids
# }

################################################
# RDS
################################################
# module "rds" {
#   source        = "../../modules/rds"
#   db_subnet_ids = module.network.isolated_subnet_ids
# }
