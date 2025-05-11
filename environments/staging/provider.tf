provider "aws" {
  region  = var.region
  profile = var.aws_profile   # e.g., "staging-account"
}
