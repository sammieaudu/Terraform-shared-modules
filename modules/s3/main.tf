module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  count = length(var.buckets_list)

  bucket = "${local.name}-${var.buckets_list[count.index].name}"
  acl    = var.buckets_list[count.index].acl

  force_destroy = false
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  versioning = {
    status     = true
    mfa_delete = false
  }

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