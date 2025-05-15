locals {
  
  tags = {
    Terraform   = "true"
    Environment = var.env
    Owner = var.env
  }

}