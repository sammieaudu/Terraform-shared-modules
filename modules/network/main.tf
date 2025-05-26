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

  # Enable VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  # Configure Network ACLs
  public_dedicated_network_acl = true
  private_dedicated_network_acl = true
  database_dedicated_network_acl = true

  # Public Network ACL rules
  public_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow HTTP"
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow HTTPS"
    },
    {
      rule_number = 120
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow ephemeral ports"
    }
  ]

  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow HTTP"
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow HTTPS"
    },
    {
      rule_number = 120
      rule_action = "allow"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow ephemeral ports"
    }
  ]

  # Private Network ACL rules
  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = var.vpc_cidr
      description = "Allow all internal traffic"
    }
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

  # Database Network ACL rules
  database_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = var.vpc_cidr
      description = "Allow all internal traffic"
    }
  ]

  database_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  ]

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
