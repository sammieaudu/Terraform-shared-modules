variable "env" {
  type    = string
}

variable "secret_manager_name" {
  type = string
}

variable "lambda_role_arn" {
  type = list(string)
}

variable "lambda_function_arn" {
  type = string
}

variable "engine" {
  type = string
}

variable "host" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
  sensitive = true
}

variable "dbname" {
  type = string
}

variable "port" {
  type = number
}

variable "rotation_rule" {
  type = string
}