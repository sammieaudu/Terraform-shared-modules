variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

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
