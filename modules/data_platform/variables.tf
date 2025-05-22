variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for the data platform"
  type        = string
}

variable "sftp_user" {
  description = "Username for SFTP access"
  type        = string
}

variable "sftp_role_arn" {
  description = "ARN of the IAM role for SFTP user"
  type        = string
}

variable "glue_database_name" {
  description = "Name of the Glue database"
  type        = string
}

variable "glue_crawler_name" {
  description = "Name of the Glue crawler"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of the IAM role for Glue"
  type        = string
}

variable "glue_job_name" {
  description = "Name of the Glue ETL job"
  type        = string
}

variable "glue_etl_script_s3_path" {
  description = "S3 path to the Glue ETL script"
  type        = string
}
