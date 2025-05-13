variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

# variable "account" {
#   type    = string  
# }

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