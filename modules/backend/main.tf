# ---------------------------------------------
# Terraform backend: S3 bucket and DynamoDB lock table
# ---------------------------------------------

resource "aws_s3_bucket" "tf_backend" {
  bucket = var.backend_bucket_name
  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "tf_backend_versioning" {
  bucket = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_backend_encryption" {
  bucket = aws_s3_bucket.tf_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name           = var.lock_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}

# ---------------------------------------------
# Variables
# ---------------------------------------------
variable "backend_bucket_name" {
  description = "Name of the S3 bucket for TF backend"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table for TF locking"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {
    Terraform = "true"
  }
}
