terraform {
  backend "s3" {
    bucket         = "dex-backend-us-east-1-terraform-state-bucket" # Unique to the dev account
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    #use_lockfile   = true
    #encrypt        = true
  }
}
