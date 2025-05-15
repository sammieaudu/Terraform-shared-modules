variable "env" {
  type    = string
}

variable "sg_name" {
  type = string
}

variable "sg_description" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ingress_with_cidr_blocks" {
  type = list(map(string))
}

