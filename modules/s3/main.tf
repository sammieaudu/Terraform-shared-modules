data "aws_caller_identity" "current" {}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  count = length(var.buckets_list)

  bucket = "${local.name}-${var.buckets_list[count.index].name}"
  acl    = var.buckets_list[count.index].acl

  force_destroy = false
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  
  # Enable versioning
  versioning = {
    status     = true
    mfa_delete = false
  }

  # Enable server-side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Enable access logging
  logging = {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/${local.name}-${var.buckets_list[count.index].name}/"
  }

  # Block public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Enable bucket policies
  attach_policy = true
  policy        = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.name}-${var.buckets_list[count.index].name}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })

  lifecycle_rule = [
    {
      id      = "expire_old_versions"
      enabled = true
      filter = {
        prefix = ""
      }
      expiration = {
        days = 90
      }

      transition = {
        days          = 30
        storage_class = "STANDARD_IA"
      }

      noncurrent_version_expiration = {
        newer_noncurrent_versions = 5
        days = 30
      }
    }
  ]
  
  tags = local.tags
}

# Create explicit public access blocks for each bucket
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  count = length(var.buckets_list)

  bucket = "${local.name}-${var.buckets_list[count.index].name}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create KMS key for S3 encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/${local.name}-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# Create logging bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${local.name}-logs"
  force_destroy = false

  tags = local.tags
}

# Configure logging bucket
resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_ownership]
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_public_access_block" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "cleanup_old_logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}