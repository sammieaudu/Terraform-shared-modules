terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-staging"
    key            = "staging/terraform.tfstate"
    region         = var.region
    dynamodb_table = "terraform-lock-table-staging"
    encrypt        = true
  }
}
