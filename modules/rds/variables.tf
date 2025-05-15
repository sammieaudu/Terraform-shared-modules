variable "env" {
  type    = string
}

variable "region" {
  type    = string
}

variable "buckets_list" {
    type = list(map(string))
}