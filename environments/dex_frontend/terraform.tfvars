aws_profile = "sandbox"
region      = "us-east-1"
env         = "dev"
account     = "986323537898"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Subnet Configuration
public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
database_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

# EKS Configuration
cluster_version = "1.32"

# eks_cluster_name = "dev-eks-cluster"

# IAM Configurations
iam_groups_names        = ["Developers", "DevOps"]
iam_developerUser_names = ["samuel", "peter", "lekan"]
iam_devOpsUser_names    = ["sammy", "joseph"]
devops_cgp_arn          = ["arn:aws:iam::aws:policy/AdministratorAccess"]
developer_cgp_arn       = ["arn:aws:iam::aws:policy/PowerUserAccess"]

