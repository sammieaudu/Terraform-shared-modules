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
# RDS Instance
################################################################################

data "aws_caller_identity" "current" {}

resource "aws_db_instance" "master" {
  count = length(var.rds_config)

  identifier = "${local.name}-${var.rds_config[count.index].name}-master"
  engine                   = var.rds_config[count.index].engine
  engine_version           = var.rds_config[count.index].engine_version
  instance_class           = var.rds_config[count.index].instance_class

  allow_major_version_upgrade = true

  allocated_storage     = var.rds_config[count.index].min_storage
  max_allocated_storage = var.rds_config[count.index].max_storage

  db_name  = "${var.rds_config[count.index].name}master"
  username = local.rds_credentials["username"]
  password = local.rds_credentials["password"]
  port     = var.rds_config[count.index].port

  multi_az               = true
  db_subnet_group_name   = var.database_subnet_group
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn

  parameter_group_name = aws_db_parameter_group.master[count.index].name

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      username,
      password,
      performance_insights_retention_period,
      backup_retention_period,
      monitoring_interval,
      parameter_group_name
    ]
  }

  depends_on = [module.rds_sg, aws_iam_role.rds_monitoring_role]
}

resource "aws_db_parameter_group" "master" {
  count = length(var.rds_config)

  name   = "${local.name}-${var.rds_config[count.index].name}-master"
  family = var.rds_config[count.index].family

  parameter {
    name  = "autovacuum"
    value = "1"
  }

  parameter {
    name  = "client_encoding"
    value = "utf8"
  }

  tags = local.tags
}

resource "aws_db_instance" "replica" {
  for_each = { for idx, config in var.rds_config : config.name => config if config.replica }

  identifier = "${local.name}-${each.value.name}-replica"
  replicate_source_db = aws_db_instance.master[index(var.rds_config, each.value)].identifier

  engine               = each.value.engine
  engine_version       = each.value.engine_version
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

  parameter_group_name = aws_db_parameter_group.replica[each.key].name

  tags = local.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      performance_insights_retention_period,
      backup_retention_period,
      monitoring_interval,
      parameter_group_name
    ]
  }

  depends_on = [aws_db_instance.master, module.rds_sg]
}

resource "aws_db_parameter_group" "replica" {
  for_each = { for idx, config in var.rds_config : config.name => config if config.replica }

  name   = "${local.name}-${each.value.name}-replica"
  family = each.value.family

  parameter {
    name  = "autovacuum"
    value = "1"
  }

  parameter {
    name  = "client_encoding"
    value = "utf8"
  }

  tags = local.tags
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
    engine = aws_db_instance.master[index(var.rds_config, each.value)].engine
    host = aws_db_instance.master[index(var.rds_config, each.value)].endpoint
    dbname = aws_db_instance.master[index(var.rds_config, each.value)].db_name
    username = try(local.rds_credentials["username"])
    password = try(local.rds_credentials["password"])
    port = aws_db_instance.master[index(var.rds_config, each.value)].port
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
