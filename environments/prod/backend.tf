terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-prod"
    key            = "prod/terraform.tfstate"
    region         = var.region
    dynamodb_table = "terraform-lock-table-prod"
    encrypt        = true
  }
}
