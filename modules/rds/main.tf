################################################################################
# Generate Random Password
################################################################################
resource "random_password" "rds_password" {
  length           = 11
  special          = true
  override_special = "!@#$%^&*()_+"
}

################################################################################
# RDS Module
################################################################################

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
  username = "${var.rds_config[count.index].username}"
  password = "${random_password.rds_password.result}"
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
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "rds-monitoring-role"

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

  depends_on = [module.rds_sg, random_password.rds_password]
}

################################################################################
# Replica DB
################################################################################

module "replica" {
  source = "terraform-aws-modules/rds/aws"

  count = length(var.rds_config)

  identifier = "${local.name}-${var.rds_config[count.index].name}-replica"
  create_db_instance        = var.rds_config[count.index].replica
  create_db_parameter_group = var.rds_config[count.index].replica
  create_db_option_group    = var.rds_config[count.index].replica

  # Source database. For cross-region use db_instance_arn
  replicate_source_db = module.master[count.index].db_instance_identifier

  engine                   = var.rds_config[count.index].engine
  engine_version           = var.rds_config[count.index].engine_version
  family                   = var.rds_config[count.index].family
  major_engine_version     = var.rds_config[count.index].major_engine_version
  instance_class           = var.rds_config[count.index].instance_class


  allocated_storage     = var.rds_config[count.index].min_storage
  max_allocated_storage = var.rds_config[count.index].max_storage

  port = var.rds_config[count.index].port

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
    count = length(module.master)
    env = var.env
    secret_manager_name = "${local.name}-rds-secret"
    lambda_role_arn = [module.lambda_rds.lambda_role_arn]
    lambda_function_arn = module.lambda_rds.lambda_function_arn
    engine = module.master[count.index].db_instance_engine
    host = module.master[count.index].db_instance_endpoint
    dbname = module.master[count.index].db_instance_name
    username = module.master[count.index].db_instance_username
    password = "${random_password.rds_password.result}"
    port = module.master[count.index].db_instance_port
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
