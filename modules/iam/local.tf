locals {
  name   = "${var.env}-${var.region}"
  region = var.region

#   account = var.account

  tags = {
    Terraform   = "true"
    Environment = var.env
    Owner = var.env
  }
}