locals {
  name   = "${var.env}-${var.region}"
  region = var.region
  
  master_map = { for idx, config in var.rds_config : config.name => aws_db_instance.master[idx] }

  rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_secret_version.secret_string)

  tags = {
    Terraform   = "true"
    Environment = var.env
    Owner = var.env
  }

}