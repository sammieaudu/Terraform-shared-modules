variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "eks_vpc" {
  type    = string
}

variable "cluster_version" {
  type    = string
}

variable "account" {
  type    = string
  default = "666666666666"
}

variable "eks_subnet" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}