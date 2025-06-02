locals {
  name   = "${var.env}-${var.region}"
  region = var.region

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}