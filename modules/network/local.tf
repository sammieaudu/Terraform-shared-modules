locals {
  name   = "${var.env}-${var.region}"
  region = var.region

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Terraform   = "true"
    Environment = var.env
    Owner = var.env
  }
}