# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-dev" # Unique to the dev account
#     key            = "dev/terraform.tfstate"
#     region         = "us-east-1"
#     use_lockfile   = true
#     encrypt        = true
#   }
# }
