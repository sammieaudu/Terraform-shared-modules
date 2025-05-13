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
variable "account" {
  description = "AWS Account Number"
  type    = string
}

################################################
# IAM Variables
################################################
variable "iam_groups_names" {
  description = "List of IAM group names to create"
  type        = list(string)
}
variable "iam_developerUser_names" {
  description = "List of IAM Users names to create"
  type        = list(string)
}
variable "iam_devOpsUser_names" {
  description = "List of IAM Users names to create"
  type        = list(string)
}

variable "developer_cgp_arn" {
  description = "Developers custom group policy ARNS"
  type        = list(string)
}

variable "devops_cgp_arn" {
  description = "DevOps custom group policy ARNS"
  type        = list(string)
}