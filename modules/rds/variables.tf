variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "rds_config" {
  type = list(map(string))
}

variable "database_subnet_group" {
  type    = string
}

variable "password_rotation_rules" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
}