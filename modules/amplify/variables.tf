variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "amp_config" {
  type = list(map(string))
}

variable "custom_rules" {
  type = list(object({
    source  = string
    status  = string
    target  = string
  }))
}