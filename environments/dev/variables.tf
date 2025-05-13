variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

################################################
# VPC Netwok
################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnets for applications like EKS"
  type        = list(string)
}

variable "database_subnets" {
  description = "RDS subnets for services needing extra segmentation like RDS"
  type        = list(string)
}

################################################
# EKS Cluster
################################################
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}
#variable "eks_cluster_name" {
#  description = "The name to give the EKS cluster."
#  type        = string
#}
