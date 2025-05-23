#aws_profile = "default"
region = "us-east-1"
env    = "dex-backend"

# S3 Buckets
buckets_list = [{ name = "terraform-state-bucket", acl = "private" }]

# Code Artifacts
artifact_repo = "devpkg"
external_packages = {
  "npm"   = "npmjs"
  "pypi"  = "pypi"
  "maven" = "maven-central"
  "nuget" = "nuget"
  "rubygems" = "rubygems"
}
# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Subnet Configuration
public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
database_subnets = ["10.0.100.0/24", "10.0.101.0/24"]

# EKS Configuration
cluster_version = "1.32"

# IAM Configurations
iam_groups_names        = ["Developers", "DevOps"]
iam_developerUser_names = ["samuel", "peter", "lekan"]
iam_devOpsUser_names    = ["sammy", "joseph", "saul"]
devops_cgp_arn          = ["arn:aws:iam::aws:policy/AdministratorAccess"]
developer_cgp_arn       = ["arn:aws:iam::aws:policy/PowerUserAccess"]

# RDS Configuration
rds_config = [
  { name = "db", engine = "postgres", engine_version = "17.5", family = "postgres17", major_engine_version = "17.5", instance_class = "db.t3.micro", username = "dex_pgadmin", min_storage = 20, max_storage = 50, port = 5432, replica = true },
  { name = "test", engine = "postgres", engine_version = "17.5", family = "postgres17", major_engine_version = "17.5", instance_class = "db.t3.micro", username = "test_pgadmin", min_storage = 20, max_storage = 30, port = 5432, replica = false }
]

# Amplify Frontend
amp_config = [
  {
    name            = "popupuibackend",
    framework       = "React"
    repo            = "https://github.com/aws-samples/aws-amplify-react-sample"
    github_pat_path = "/amplify/public"
    branch_name     = "main"
    stage           = "PRODUCTION"
    backend         = true
    domain_name     = "awsamplifyapp.com"
  },
  {
    name            = "angularuiform",
    framework       = "Angular"
    repo            = "https://github.com/aws-samples/aws-amplify-angular-sample"
    github_pat_path = "/amplify/public"
    branch_name     = "main"
    stage           = "DEVELOPMENT"
    backend         = false
    domain_name     = "awsamplifyapp.com"
  }
]
amp_custom_rules = [
  { source = "/<*>", status = "404", target = "/index.html" },
  { source = "/api/*", status = "200", target = "/api/index.html" }
]
