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
  description = "AWS Account Number"
  type    = string
}

# variable "eks_public_subnets" {
#   description = "List of subnet IDs for the EKS cluster"
#   type        = list(string)
# }

variable "eks_private_subnets" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}