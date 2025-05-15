provider "aws" {
  alias   = "network"
  region  = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2" # Updated to latest stable version

  providers = {
    aws = aws.network
  }

  name             = "${local.name}-vpc"
  cidr             = var.vpc_cidr
  azs              = local.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  create_database_subnet_group = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # You can also configure NAT gateways if needed
  enable_nat_gateway = true
  single_nat_gateway = true

  # Optionally, define tags for greater clarity over subnet usage
  public_subnet_tags = {
    Type = "public",
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    Type = "private applications",
    "kubernetes.io/role/internal-elb" = 1
  }
  database_subnet_tags = {
    Type = "database"
  }

  tags = local.tags
}
