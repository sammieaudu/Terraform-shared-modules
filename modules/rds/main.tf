################################################################################
# RDS Monitoring Role
################################################################################
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# Generate Random Password
################################################################################
resource "aws_secretsmanager_secret_version" "rds_secret_version_update" {
  for_each = { for idx, config in var.rds_config : config.name => config if config.username != null && config.username != "" }
  secret_id     = module.secret_manager.standard_secret_arn
  secret_string = jsonencode({
    username = each.value.username,
    password = jsondecode(module.secret_manager.standard_secret_string)["random_password"]
  })

  version_stages = ["AWSCURRENT"]

  depends_on = [module.secret_manager]
}

data "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id = module.secret_manager.standard_secret_arn
  version_stage = "AWSCURRENT"
  depends_on = [aws_secretsmanager_secret_version.rds_secret_version_update]
}

################################################################################
# RDS Module
################################################################################

data "aws_caller_identity" "current" {}

module "master" {
  source = "terraform-aws-modules/rds/aws"

  count = length(var.rds_config)

  identifier = "${local.name}-${var.rds_config[count.index].name}-master"
  engine                   = var.rds_config[count.index].engine
  engine_version           = var.rds_config[count.index].engine_version
  family                   = var.rds_config[count.index].family
  major_engine_version     = var.rds_config[count.index].major_engine_version
  instance_class           = var.rds_config[count.index].instance_class

  allow_major_version_upgrade = true

  allocated_storage     = var.rds_config[count.index].min_storage
  max_allocated_storage = var.rds_config[count.index].max_storage

  db_name  = "${var.rds_config[count.index].name}master"
  username = local.rds_credentials["username"]
  password = local.rds_credentials["password"]
  port     = var.rds_config[count.index].port

  manage_master_user_password = false

  multi_az               = true
  db_subnet_group_name   = var.database_subnet_group
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role = false
  monitoring_interval                   = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = local.tags

  depends_on = [module.rds_sg, aws_iam_role.rds_monitoring_role]
}

################################################################################
# Replica DB
################################################################################

module "replica" {
  source = "terraform-aws-modules/rds/aws"

  for_each = { for idx, config in var.rds_config : config.name => config if config.replica }

  identifier = "${local.name}-${each.value.name}-replica"
  create_db_instance        = each.value.replica
  create_db_parameter_group = each.value.replica
  create_db_option_group    = each.value.replica

  # Source database. For cross-region use db_instance_arn
  replicate_source_db = local.master_map[each.value.name].db_instance_identifier

  engine               = each.value.engine
  engine_version       = each.value.engine_version
  family = each.value.family 
  instance_class       = each.value.instance_class
  port                = each.value.port


  multi_az               = false
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  maintenance_window              = "Tue:00:00-Tue:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  storage_encrypted       = false

  tags = local.tags

  depends_on = [module.master,module.rds_sg]
}

################################################################################
# Lambda Function
################################################################################
module "lambda_rds" {
    source = "../lambda/secretrotation"
    env = var.env
    lambda_secret_manager_name = "${local.name}-rds-lambda-secret-rotation"
    secret_manager_arn = module.secret_manager.standard_secret_arn
}

################################################################################
# Secret Manager
################################################################################
module "secret_manager" {
    source = "../secretmanager"
    env = var.env
    secret_manager_name = "${local.name}-rds-sec-mgr"
}

module "rds_secret_rotate" {
    source = "../secretmanager/sm-rotate"
    for_each = { for config in var.rds_config : config.name => config }
    env = var.env
    secret_manager_name = "${local.name}-${each.value.name}-rds-secret"
    lambda_role_arn = [module.lambda_rds.lambda_role_arn]
    lambda_function_arn = module.lambda_rds.lambda_function_arn
    engine = local.master_map[each.value.name].db_instance_engine
    host = local.master_map[each.value.name].db_instance_endpoint
    dbname = local.master_map[each.value.name].db_instance_name
    username = try(local.rds_credentials["username"])
    password = try(local.rds_credentials["password"])
    port = local.master_map[each.value.name].db_instance_port
    rotation_rule = var.password_rotation_rules

    depends_on = [ module.lambda_rds ]
}

################################################################################
# Security Group
################################################################################
module "rds_sg" {
    source = "../sg"
    env = var.env
    sg_name = "${local.name}-rds-master-sg"
    sg_description = "Complete PostgreSQL example security group"
    vpc_id = var.vpc_id
    ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = var.vpc_cidr
    },
  ]
  
}
