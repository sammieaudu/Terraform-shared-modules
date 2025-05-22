// S3 Bucket definition
data "aws_s3_bucket" "data_platform_bucket" {
  bucket = var.s3_bucket_name
}

// AWS SFTP (Transfer Family)
resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "PUBLIC"
}
resource "aws_transfer_user" "sftp_user" {
  server_id = aws_transfer_server.sftp.id
  user_name = var.sftp_user
  role      = var.sftp_role_arn

  home_directory = "/${var.s3_bucket_name}"
}

// AWS Glue Database for the platform
resource "aws_glue_catalog_database" "glue_db" {
  name = var.glue_database_name
}

// AWS Glue Crawler to populate the Data Catalog
resource "aws_glue_crawler" "glue_crawler" {
  name         = var.glue_crawler_name
  database_name = aws_glue_catalog_database.glue_db.name
  role         = var.glue_role_arn

  s3_target {
    path = "s3://${data.data_platform_bucket.bucket}/data/"
  }
}

// AWS Glue Job for ETL operations
resource "aws_glue_job" "glue_job" {
  name     = var.glue_job_name
  role_arn = var.glue_role_arn
  command {
    name            = "glueetl"
    script_location = var.glue_etl_script_s3_path
    python_version  = "3"
  }
  max_retries = 1
}
