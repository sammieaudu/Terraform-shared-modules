variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
}

variable "database_subnet_ids" {
  description = "List of subnet IDs for the database subnet group"
  type        = list(string)
}
