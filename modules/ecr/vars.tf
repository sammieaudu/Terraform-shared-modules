variable "aws_region" {}
variable "name" {}
variable "image_tag_mutability" { default = "MUTABLE" }
variable "scan_on_push" { default = true }
variable "tags" {
  type    = map(string)
  default = {}
}


